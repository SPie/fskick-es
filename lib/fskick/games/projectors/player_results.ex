defmodule Fskick.Games.Projectors.PlayerResults do
  @moduledoc """
  Projects `GameCreated` events into the `player_results` read model —
  one row per (player, game) carrying the player's outcome and the
  game's `played_at`. Backs `Fskick.Streaks` (last-N circles, longest
  winning/losing streak, current ongoing streaks).

  Draws follow the existing product rule: a `:draw` outcome is recorded
  as `won: true` for both teams, mirroring
  `Fskick.Games.Projectors.PlayerStats`.

  The `name:` is versioned (`.v1`) so a fresh deployment replays from
  the origin of the event store and backfills `player_results` from
  every existing `GameCreated`.
  """

  use Commanded.Projections.Ecto,
    application: Fskick.App,
    repo: Fskick.Repo,
    name: "Fskick.Games.Projectors.PlayerResults.v1"

  alias Fskick.Games.Events.GameCreated
  alias Fskick.Games.PlayerResult

  project(%GameCreated{} = event, _metadata, fn multi ->
    team_a_won = won?(event.outcome, :team_a)
    team_b_won = won?(event.outcome, :team_b)
    played_at = coerce_datetime(event.played_at)

    multi
    |> insert_results(:team_a, "a", event.team_a, event, played_at, team_a_won)
    |> insert_results(:team_b, "b", event.team_b, event, played_at, team_b_won)
  end)

  defp coerce_datetime(%DateTime{} = dt), do: dt

  defp coerce_datetime(value) when is_binary(value) do
    {:ok, dt, _offset} = DateTime.from_iso8601(value)
    dt
  end

  defp won?("team_a_won", :team_a), do: true
  defp won?("team_b_won", :team_b), do: true
  defp won?("draw", _team), do: true
  defp won?(_outcome, _team), do: false

  defp insert_results(multi, tag, team, player_ids, event, played_at, won) do
    player_ids
    |> Enum.with_index()
    |> Enum.reduce(multi, fn {player_id, idx}, acc ->
      Ecto.Multi.insert(
        acc,
        {:player_result, tag, idx},
        %PlayerResult{
          player_id: player_id,
          game_id: event.game_id,
          season_id: event.season_id,
          played_at: played_at,
          team: team,
          won: won
        },
        on_conflict: :nothing,
        conflict_target: [:player_id, :game_id]
      )
    end)
  end
end
