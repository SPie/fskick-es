defmodule Fskick.Players.Aggregates.PlayerTest do
  use ExUnit.Case, async: true

  alias Fskick.Players.Aggregates.Player
  alias Fskick.Players.Commands.CreatePlayer
  alias Fskick.Players.Events.PlayerCreated

  describe "execute/2" do
    test "emits PlayerCreated when aggregate is uninitialised" do
      id = Ecto.UUID.generate()
      cmd = %CreatePlayer{player_id: id, name: "Alice"}

      assert %PlayerCreated{player_id: ^id, name: "Alice"} =
               Player.execute(%Player{}, cmd)
    end

    test "rejects when the player has already been created" do
      state = %Player{player_id: Ecto.UUID.generate(), name: "Alice"}
      cmd = %CreatePlayer{player_id: Ecto.UUID.generate(), name: "Bob"}

      assert {:error, :already_created} = Player.execute(state, cmd)
    end
  end

  describe "apply/2" do
    test "PlayerCreated sets id and name on the aggregate" do
      id = Ecto.UUID.generate()
      event = %PlayerCreated{player_id: id, name: "Alice"}

      assert %Player{player_id: ^id, name: "Alice"} = Player.apply(%Player{}, event)
    end
  end
end
