defmodule Fskick.Games.Aggregates.GameTest do
  use ExUnit.Case, async: true

  alias Fskick.Games.Aggregates.Game
  alias Fskick.Games.Commands.CreateGame
  alias Fskick.Games.Events.GameCreated

  describe "execute/2 with CreateGame" do
    test "emits GameCreated when aggregate is uninitialised" do
      cmd = %CreateGame{
        game_id: Ecto.UUID.generate(),
        season_id: Ecto.UUID.generate(),
        played_at: DateTime.utc_now(),
        team_a: [Ecto.UUID.generate(), Ecto.UUID.generate()],
        team_b: [Ecto.UUID.generate()],
        outcome: :team_a_won
      }

      assert %GameCreated{
               game_id: game_id,
               season_id: season_id,
               played_at: played_at,
               team_a: team_a,
               team_b: team_b,
               outcome: "team_a_won"
             } = Game.execute(%Game{}, cmd)

      assert game_id == cmd.game_id
      assert season_id == cmd.season_id
      assert played_at == cmd.played_at
      assert team_a == cmd.team_a
      assert team_b == cmd.team_b
    end

    test "rejects when the game has already been created" do
      state = %Game{game_id: Ecto.UUID.generate()}
      cmd = %CreateGame{game_id: Ecto.UUID.generate()}

      assert {:error, :already_created} = Game.execute(state, cmd)
    end
  end

  describe "apply/2" do
    test "GameCreated sets all fields on the aggregate" do
      event = %GameCreated{
        game_id: Ecto.UUID.generate(),
        season_id: Ecto.UUID.generate(),
        played_at: DateTime.utc_now(),
        team_a: [Ecto.UUID.generate()],
        team_b: [Ecto.UUID.generate()],
        outcome: "draw"
      }

      assert %Game{
               game_id: game_id,
               season_id: season_id,
               played_at: played_at,
               team_a: team_a,
               team_b: team_b,
               outcome: "draw"
             } = Game.apply(%Game{}, event)

      assert game_id == event.game_id
      assert season_id == event.season_id
      assert played_at == event.played_at
      assert team_a == event.team_a
      assert team_b == event.team_b
    end
  end
end
