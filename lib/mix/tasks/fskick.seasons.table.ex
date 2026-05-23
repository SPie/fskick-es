defmodule Mix.Tasks.Fskick.Seasons.Table do
  @moduledoc """
  Prints a ranked table of player stats scoped to a single season.

      mix fskick.seasons.table                        # active season
      mix fskick.seasons.table "2026"                 # named season
      mix fskick.seasons.table --sort wins
      mix fskick.seasons.table "2026" --player Alice
      mix fskick.seasons.table --sort win_ratio -p Bob

  Optional positional arg:
    season_name  Season to print. Defaults to the currently-active season.

  Optional flags:
    --sort, -s    Sort key: points (default), wins, games, win_ratio
    --player, -p  Filter the table to a single player by name

  A draw counts as a win for both teams.
  """

  use Mix.Task

  alias Fskick.CLI.PlayerStatsTable
  alias Fskick.Games
  alias Fskick.Players
  alias Fskick.Seasons

  @shortdoc ~s|Prints season player rankings: mix fskick.seasons.table [name] [--sort key] [--player name]|

  @strict [sort: :string, player: :string]
  @aliases [s: :sort, p: :player]
  @sort_keys %{
    "points" => :points,
    "wins" => :wins,
    "games" => :games,
    "win_ratio" => :win_ratio
  }

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, rest, invalid} = OptionParser.parse(argv, strict: @strict, aliases: @aliases)

    if invalid != [] do
      Mix.raise("Unknown or malformed flags: #{inspect(invalid)}\n\n#{usage()}")
    end

    if length(rest) > 1 do
      Mix.raise("Too many positional arguments: #{inspect(rest)}\n\n#{usage()}")
    end

    season = resolve_season(List.first(rest))
    sort = resolve_sort(opts[:sort])
    player_filter = opts[:player]

    stats =
      Players.list_player_stats(season_id: season.id, sort: sort)
      |> filter_by_player(player_filter)

    total_games = Games.season_game_count(season.id)

    Mix.shell().info("Season: #{season.name}")
    Mix.shell().info(PlayerStatsTable.render(stats, total_games))
  end

  defp resolve_season(nil) do
    case Seasons.get_active_season() do
      nil -> Mix.raise("No active season — pass a season name explicitly")
      season -> season
    end
  end

  defp resolve_season(name) do
    case Seasons.get_season_by_name(name) do
      nil -> Mix.raise("Season not found: #{inspect(name)}")
      season -> season
    end
  end

  defp resolve_sort(nil), do: :points

  defp resolve_sort(raw) do
    case Map.fetch(@sort_keys, raw) do
      {:ok, key} ->
        key

      :error ->
        Mix.raise(
          "Invalid --sort #{inspect(raw)}; expected one of #{inspect(Map.keys(@sort_keys))}"
        )
    end
  end

  defp filter_by_player(stats, nil), do: stats
  defp filter_by_player(stats, name), do: Enum.filter(stats, &(&1.name == name))

  defp usage() do
    "Usage: mix fskick.seasons.table [name] [--sort points|wins|games|win_ratio] [--player name]"
  end
end
