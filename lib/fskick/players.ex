defmodule Fskick.Players do
  @moduledoc """
  Players context: write side dispatches commands through `Fskick.App`;
  read side queries the `Fskick.Players.Player` projection and, for
  rankings, joins with `Fskick.Games.PlayerStats`.
  """

  import Ecto.Query, only: [from: 2]

  alias Fskick.App
  alias Fskick.CQRS.Projection
  alias Fskick.Games
  alias Fskick.Games.PlayerStats
  alias Fskick.Players.Commands.CreatePlayer
  alias Fskick.Players.Player
  alias Fskick.Players.PlayerStat
  alias Fskick.Repo

  @valid_sorts [:points, :wins, :games, :win_ratio]

  @doc """
  Create a new player with the given name.

  Returns `{:ok, %Player{}}` on success, or:
  - `{:error, %Ecto.Changeset{}}` when the name is blank/invalid or already taken
  - `{:error, :projection_timeout}` if the read model does not catch up in time
  - `{:error, reason}` for dispatch failures
  """
  def create_player(name) do
    attrs = %{player_id: Ecto.UUID.generate(), name: name}

    with {:ok, %CreatePlayer{} = command} <- CreatePlayer.new(attrs),
         :ok <- App.dispatch(command) do
      Projection.await(Player, command.player_id)
    end
  end

  def get_player_by_name(name) when is_binary(name) do
    Repo.get_by(Player, name: name)
  end

  @doc """
  Returns a ranked list of `%Fskick.Players.PlayerStat{}` rows for every
  player who has played at least one game.

  Derivations:
  - `points = wins * 3 / max(games, div(max_games_across_players, 2))`
  - `win_ratio = wins / games`
  - `games_ratio = games / total_games`

  A `:draw` outcome counts as a win for both teams (handled by the
  projector).

  ## Options

  - `:sort` — one of `#{inspect(@valid_sorts)}`. Defaults to `:points`.
    Sort is descending; `:games` is used as a tiebreaker. Players sharing
    the primary sort value share a position.
  - `:season_id` — when present, scopes the stats to a single season:
    rows come from `Fskick.Games.PlayerStats` filtered to that season,
    and `games_ratio` is `games / season_total_games`. When omitted,
    rows are aggregated across all seasons via `GROUP BY player_id` and
    `games_ratio` is `games / all_time_total_games`. Defaults to
    all-time.
  """
  def list_player_stats(opts \\ []) do
    sort = Keyword.get(opts, :sort, :points)
    validate_sort!(sort)

    {rows, total_games} =
      case Keyword.fetch(opts, :season_id) do
        {:ok, season_id} ->
          {load_season_rows(season_id), Games.season_game_count(season_id)}

        :error ->
          {load_all_time_rows(), Games.total_games_count()}
      end

    max_games = Enum.reduce(rows, 0, fn row, acc -> max(row.games, acc) end)

    rows
    |> Enum.map(&derive(&1, total_games, max_games))
    |> Enum.sort_by(&sort_key(&1, sort), :desc)
    |> assign_positions(sort)
  end

  defp validate_sort!(sort) do
    unless sort in @valid_sorts do
      raise ArgumentError,
            "invalid sort: #{inspect(sort)}; expected one of #{inspect(@valid_sorts)}"
    end
  end

  defp load_all_time_rows() do
    Repo.all(
      from s in PlayerStats,
        join: p in Player,
        on: p.id == s.player_id,
        group_by: [s.player_id, p.name],
        select: %{
          player_id: s.player_id,
          name: p.name,
          wins: type(sum(s.wins), :integer),
          games: type(sum(s.games), :integer)
        }
    )
  end

  defp load_season_rows(season_id) do
    Repo.all(
      from s in PlayerStats,
        join: p in Player,
        on: p.id == s.player_id,
        where: s.season_id == ^season_id,
        select: %{
          player_id: s.player_id,
          name: p.name,
          wins: s.wins,
          games: s.games
        }
    )
  end

  defp derive(
         %{player_id: player_id, name: name, wins: wins, games: games},
         total_games,
         max_games
       ) do
    %PlayerStat{
      player_id: player_id,
      name: name,
      wins: wins,
      games: games,
      points: points(wins, games, max_games),
      win_ratio: ratio(wins, games),
      games_ratio: ratio(games, total_games)
    }
  end

  defp points(_wins, 0, _max_games), do: 0.0

  defp points(wins, games, max_games) do
    divisor = max(games, div(max_games, 2))
    wins * 3 / divisor
  end

  defp ratio(_num, 0), do: 0
  defp ratio(num, denom), do: num / denom * 100

  defp sort_key(stat, :points), do: {stat.points, stat.games}
  defp sort_key(stat, :wins), do: {stat.wins, stat.games}
  defp sort_key(stat, :games), do: {stat.games, stat.wins}
  defp sort_key(stat, :win_ratio), do: {stat.win_ratio, stat.games}

  defp position_value(stat, :points), do: stat.points
  defp position_value(stat, :wins), do: stat.wins
  defp position_value(stat, :games), do: stat.games
  defp position_value(stat, :win_ratio), do: stat.win_ratio

  defp assign_positions(sorted, sort) do
    {result, _acc} =
      sorted
      |> Enum.with_index(1)
      |> Enum.map_reduce({nil, 1}, fn {%PlayerStat{} = stat, idx}, {prev_value, prev_pos} ->
        value = position_value(stat, sort)
        position = if value == prev_value, do: prev_pos, else: idx
        {%PlayerStat{stat | position: position}, {value, position}}
      end)

    result
  end
end
