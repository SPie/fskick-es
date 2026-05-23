defmodule Fskick.Games.Projectors.PlayerStats do
  @moduledoc """
  Projects `GameCreated` events into the read models that back the
  player rankings table:

  - `player_stats` — per-player counters (`wins`, `games`)
  - `game_counts` — singleton total of all games recorded

  A `:draw` outcome counts as a win for both teams, matching the
  product rule that a draw is treated like a win in the rankings.

  Derived stats (points, ratios, position) are **not** stored here —
  they depend on global aggregates (total games, max games across
  players) and would otherwise force a write to every row on every
  event. Read-side derivation lives in `Fskick.Players.list_player_stats/1`.
  """

  use Commanded.Projections.Ecto,
    application: Fskick.App,
    repo: Fskick.Repo,
    name: "Fskick.Games.Projectors.PlayerStats"

  import Ecto.Query, only: [from: 2]

  alias Fskick.Games.Events.GameCreated
  alias Fskick.Games.GameCount
  alias Fskick.Games.PlayerStats

  project(%GameCreated{} = event, _metadata, fn multi ->
    team_a_win_inc = win_inc(event.outcome, :team_a)
    team_b_win_inc = win_inc(event.outcome, :team_b)

    multi
    |> upsert_team(:team_a, event.team_a, team_a_win_inc)
    |> upsert_team(:team_b, event.team_b, team_b_win_inc)
    |> Ecto.Multi.update_all(
      :game_count,
      from(c in GameCount, where: c.id == 1),
      inc: [total: 1]
    )
  end)

  defp win_inc("team_a_won", :team_a), do: 1
  defp win_inc("team_b_won", :team_b), do: 1
  defp win_inc("draw", _team), do: 1
  defp win_inc(_outcome, _team), do: 0

  defp upsert_team(multi, tag, player_ids, win_inc) do
    player_ids
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {player_id, idx}, acc ->
      Ecto.Multi.insert(
        acc,
        {:player_stats, tag, idx},
        %PlayerStats{player_id: player_id, wins: win_inc, games: 1},
        on_conflict: [inc: [wins: win_inc, games: 1]],
        conflict_target: :player_id
      )
    end)
  end
end
