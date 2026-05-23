defmodule Mix.Tasks.Fskick.Players.Get do
  @moduledoc """
  Prints a ranked table of all players with stats.

      mix fskick.players.get
      mix fskick.players.get Alice
      mix fskick.players.get --sort wins
      mix fskick.players.get Alice --sort win_ratio

  Optional positional arg:
    name         Limit the output to the named player

  Optional flags:
    --sort, -s   Sort key: points (default), wins, games, win_ratio

  Stats aggregate across all seasons. A draw counts as a win for both
  teams.
  """

  use Mix.Task

  alias Fskick.CLI.PlayerStatsTable
  alias Fskick.Games
  alias Fskick.Players

  @shortdoc ~s|Prints player rankings: mix fskick.players.get [name] [--sort key]|

  @strict [sort: :string]
  @aliases [s: :sort]
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

    name_filter = List.first(rest)

    if length(rest) > 1 do
      Mix.raise("Too many positional arguments: #{inspect(rest)}\n\n#{usage()}")
    end

    sort = resolve_sort(opts[:sort])

    stats =
      Players.list_player_stats(sort: sort)
      |> filter_by_name(name_filter)

    total_games = Games.total_games_count()

    Mix.shell().info(PlayerStatsTable.render(stats, total_games))
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

  defp filter_by_name(stats, nil), do: stats
  defp filter_by_name(stats, name), do: Enum.filter(stats, &(&1.name == name))

  defp usage() do
    "Usage: mix fskick.players.get [name] [--sort points|wins|games|win_ratio]"
  end
end
