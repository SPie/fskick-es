defmodule Mix.Tasks.Fskick.Seasons.List do
  @moduledoc """
  Lists all seasons with name and active status in a table.

      mix fskick.seasons.list
  """

  use Mix.Task

  alias Fskick.Seasons

  @shortdoc ~s|Lists all seasons: mix fskick.seasons.list|

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    rows =
      for season <- Seasons.list_seasons() do
        active = if season.active, do: "Active", else: ""
        [season.name, active]
      end

    table =
      rows
      |> TableRex.Table.new(["Name", "Active"])
      |> TableRex.Table.render!()

    Mix.shell().info(table)
  end
end
