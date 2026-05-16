defmodule Fskick.PlayersTest do
  use Fskick.DataCase

  alias Fskick.Players
  alias Fskick.Players.Player

  describe "create_player/1" do
    test "creates a player and projects it to the read model" do
      assert {:ok, %Player{name: "Alice", id: id}} = Players.create_player("Alice")
      assert is_binary(id)
      assert Players.get_player_by_name("Alice")
    end

    test "trims surrounding whitespace from the name" do
      assert {:ok, %Player{name: "Alice"}} = Players.create_player("  Alice  ")
    end

    test "rejects duplicate names" do
      assert {:ok, _} = Players.create_player("Alice")
      assert {:error, %Ecto.Changeset{} = changeset} = Players.create_player("Alice")
      assert "has already been taken" in errors_on(changeset).name
    end

    test "rejects duplicate names after trimming" do
      assert {:ok, _} = Players.create_player("Alice")
      assert {:error, %Ecto.Changeset{} = changeset} = Players.create_player("  Alice  ")
      assert "has already been taken" in errors_on(changeset).name
    end

    test "rejects blank name" do
      assert {:error, %Ecto.Changeset{}} = Players.create_player("")
      assert {:error, %Ecto.Changeset{}} = Players.create_player("   ")
    end
  end
end
