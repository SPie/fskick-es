defmodule Mix.Tasks.Fskick.Migrate.Legacy do
  @moduledoc """
  Imports data from the old Go app's SQLite database into the new
  event-sourced store.

      mix fskick.migrate.legacy /path/to/old.db

  Idempotent — already-imported seasons, players, and games are skipped.
  See `Fskick.LegacyMigration` for the data mapping rules.
  """

  use Mix.Task

  alias Fskick.LegacyMigration

  @shortdoc "Imports data from the legacy SQLite database"

  @impl Mix.Task
  def run([db_path]) do
    Mix.Task.run("app.start")

    case LegacyMigration.migrate_all(db_path) do
      :ok ->
        Mix.shell().info("Migration complete")

      {:error, reason} ->
        Mix.raise("Migration failed: #{inspect(reason)}")
    end
  end

  def run(_), do: Mix.raise("Usage: mix fskick.migrate.legacy <path-to-sqlite.db>")
end
