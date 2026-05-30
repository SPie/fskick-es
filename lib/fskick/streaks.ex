defmodule Fskick.Streaks do
  @moduledoc """
  Read-side computations over the `player_results` read model written
  by `Fskick.Games.Projectors.PlayerResults`.

  All streaks here are all-time and season-agnostic, matching the old
  app. A draw counts as a win (the projector stores `won: true` for
  both teams on a draw), so a draw shows up as a green circle and
  continues a winning streak.
  """

  import Ecto.Query, only: [from: 2]

  alias Fskick.Games.PlayerResult
  alias Fskick.Players.Player
  alias Fskick.Repo

  defmodule Streak do
    @moduledoc false
    defstruct [:player_id, :name, :number]
  end

  @doc """
  Returns the last `n` results (as `won` booleans) for the given player,
  ordered oldest → newest, ready for direct rendering as left-to-right
  circles. Fewer than `n` entries are returned for new players.
  """
  def last_results(player_id, n \\ 5) when is_binary(player_id) and is_integer(n) and n > 0 do
    from(r in PlayerResult,
      where: r.player_id == ^player_id,
      order_by: [desc: r.played_at, desc: r.game_id],
      limit: ^n,
      select: r.won
    )
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Longest run of consecutive wins (or losses) for the given player
  across their entire history. Returns an integer (0 if the player has
  no results).
  """
  def longest_streak(player_id, type) when is_binary(player_id) and type in [:win, :loss] do
    target = type == :win

    from(r in PlayerResult,
      where: r.player_id == ^player_id,
      order_by: [asc: r.played_at, asc: r.game_id],
      select: r.won
    )
    |> Repo.all()
    |> longest_run(target)
  end

  @doc """
  Returns the player with the longest all-time winning streak, or
  `nil` if no games have been recorded yet.
  """
  def longest_winning_streak(), do: top_longest(true)

  @doc """
  Returns the player with the longest all-time losing streak, or
  `nil` if no games have been recorded yet.
  """
  def longest_losing_streak(), do: top_longest(false)

  defp top_longest(target) do
    all_results_by_player()
    |> Enum.map(fn {{player_id, name}, results} ->
      %Streak{player_id: player_id, name: name, number: longest_run(results, target)}
    end)
    |> Enum.filter(&(&1.number > 0))
    |> Enum.max_by(& &1.number, fn -> nil end)
  end

  @doc """
  Top players by their CURRENT (ongoing) streak of the requested type,
  sorted descending and capped at `limit`. Players whose current run
  of the requested type is zero are dropped.
  """
  def current_streaks(type, limit \\ 10) when type in [:win, :loss] and is_integer(limit) do
    target = type == :win

    all_results_by_player()
    |> Enum.map(fn {{player_id, name}, results} ->
      %Streak{player_id: player_id, name: name, number: current_run(results, target)}
    end)
    |> Enum.filter(&(&1.number > 0))
    |> Enum.sort_by(& &1.number, :desc)
    |> Enum.take(limit)
  end

  defp all_results_by_player() do
    from(r in PlayerResult,
      join: p in Player,
      on: p.id == r.player_id,
      order_by: [asc: r.played_at, asc: r.game_id],
      select: {r.player_id, p.name, r.won}
    )
    |> Repo.all()
    |> Enum.group_by(
      fn {player_id, name, _won} -> {player_id, name} end,
      fn {_player_id, _name, won} -> won end
    )
  end

  defp longest_run(results, target) do
    {best, _current} =
      Enum.reduce(results, {0, 0}, fn won, {best, current} ->
        current = if won == target, do: current + 1, else: 0
        {max(best, current), current}
      end)

    best
  end

  defp current_run(results, target) do
    results
    |> Enum.reverse()
    |> Enum.take_while(&(&1 == target))
    |> length()
  end
end
