defmodule Fskick.CQRS.Projection do
  @moduledoc """
  Helpers for synchronising with Commanded read-model projections.

  After dispatching a command through `Fskick.App`, callers use
  `await/2` to block until the corresponding projector has written
  the row into the read model (or the deadline is reached).
  """

  alias Fskick.Repo

  @default_wait_ms 5_000
  @poll_interval_ms 25

  @doc """
  Poll the read model for `schema` with the given `id` until the row
  appears or the timeout elapses.

  Returns `{:ok, struct}` on success, or `{:error, :projection_timeout}`
  if the projection does not catch up in time.
  """
  def await(schema, id, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_wait_ms)
    deadline = System.monotonic_time(:millisecond) + timeout
    do_await(schema, id, deadline)
  end

  defp do_await(schema, id, deadline) do
    case Repo.get(schema, id) do
      nil ->
        if System.monotonic_time(:millisecond) >= deadline do
          {:error, :projection_timeout}
        else
          Process.sleep(@poll_interval_ms)
          do_await(schema, id, deadline)
        end

      struct ->
        {:ok, struct}
    end
  end
end
