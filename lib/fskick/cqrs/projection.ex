defmodule Fskick.CQRS.Projection do
  @moduledoc """
  Helpers for synchronising with Commanded read-model projections.

  After dispatching a command through `Fskick.App`, callers use
  `await/3` to block until the corresponding projector has written
  (or updated) the row in the read model. Pass `:match` to wait for a
  specific row state — e.g. `match: & &1.active` to wait until the row
  exists and a predicate returns true.
  """

  alias Fskick.Repo

  @default_wait_ms 5_000
  @poll_interval_ms 25

  @doc """
  Poll the read model for `schema` with the given `id` until the row
  exists and the optional `:match` predicate returns true, or the
  timeout elapses.

  ## Options

  - `:timeout` — milliseconds to wait (default `#{@default_wait_ms}`).
  - `:match` — single-arity predicate run against the loaded struct.
    Defaults to `fn _ -> true end` (any existing row matches).

  Returns `{:ok, struct}` on success, or `{:error, :projection_timeout}`
  if the projection does not catch up in time.
  """
  def await(schema, id, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_wait_ms)
    match = Keyword.get(opts, :match, fn _ -> true end)
    deadline = System.monotonic_time(:millisecond) + timeout
    do_await(schema, id, match, deadline)
  end

  defp do_await(schema, id, match, deadline) do
    case Repo.get(schema, id) do
      nil ->
        retry_or_timeout(schema, id, match, deadline)

      struct ->
        if match.(struct) do
          {:ok, struct}
        else
          retry_or_timeout(schema, id, match, deadline)
        end
    end
  end

  defp retry_or_timeout(schema, id, match, deadline) do
    if System.monotonic_time(:millisecond) >= deadline do
      {:error, :projection_timeout}
    else
      Process.sleep(@poll_interval_ms)
      do_await(schema, id, match, deadline)
    end
  end
end
