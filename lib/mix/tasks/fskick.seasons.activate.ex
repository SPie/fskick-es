defmodule Mix.Tasks.Fskick.Seasons.Activate do
  @moduledoc """
  Activates the named season, deactivating any other currently-active
  season.

      mix fskick.seasons.activate "2026"

  Only one season can be active at a time; zero active is allowed.
  Activating an already-active season is a silent no-op success.
  Fails if no season with the given name exists.
  """

  use Mix.Task

  alias Fskick.Seasons

  @shortdoc ~s|Activates a season: mix fskick.seasons.activate "2026"|

  @impl Mix.Task
  def run([name | _]) do
    Mix.Task.run("app.start")

    case Seasons.activate_season(name) do
      {:ok, season} ->
        Mix.shell().info("Season #{season.name} activated")

      {:error, :not_found} ->
        Mix.raise("Season with name #{inspect(name)} does not exist")

      {:error, :projection_timeout} ->
        Mix.raise("Season activation dispatched but read model did not catch up in time")

      {:error, %Ecto.Changeset{} = changeset} ->
        Mix.raise("Invalid input: #{format_errors(changeset)}")

      {:error, reason} ->
        Mix.raise("Failed to activate season: #{inspect(reason)}")
    end
  end

  def run(_), do: Mix.raise(~s|Usage: mix fskick.seasons.activate "<name>"|)

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc ->
        String.replace(acc, "%{#{k}}", to_string(v))
      end)
    end)
    |> inspect()
  end
end
