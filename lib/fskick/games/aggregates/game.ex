defmodule Fskick.Games.Aggregates.Game do
  @moduledoc """
  Game aggregate root. Enforces state-dependent invariants only —
  structural validation lives on the command.
  """

  alias Fskick.Games.Aggregates.Game
  alias Fskick.Games.Commands.CreateGame
  alias Fskick.Games.Events.GameCreated

  defstruct [:game_id, :season_id, :played_at, :team_a, :team_b, :outcome]

  def execute(%Game{game_id: nil}, %CreateGame{} = command) do
    %GameCreated{
      game_id: command.game_id,
      season_id: command.season_id,
      played_at: command.played_at,
      team_a: command.team_a,
      team_b: command.team_b,
      outcome: Atom.to_string(command.outcome)
    }
  end

  def execute(%Game{}, %CreateGame{}) do
    {:error, :already_created}
  end

  def apply(%Game{} = state, %GameCreated{} = event) do
    %Game{
      state
      | game_id: event.game_id,
        season_id: event.season_id,
        played_at: event.played_at,
        team_a: event.team_a,
        team_b: event.team_b,
        outcome: event.outcome
    }
  end
end
