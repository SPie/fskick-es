defmodule Fskick.Players.Commands.CreatePlayerTest do
  use Fskick.DataCase, async: true

  alias Fskick.Players.Commands.CreatePlayer
  alias Fskick.Players.Player

  describe "new/1" do
    test "returns a command with valid attrs" do
      id = Ecto.UUID.generate()

      assert {:ok, %CreatePlayer{player_id: ^id, name: "Alice"}} =
               CreatePlayer.new(%{player_id: id, name: "Alice"})
    end

    test "trims surrounding whitespace from name" do
      assert {:ok, %CreatePlayer{name: "Alice"}} =
               CreatePlayer.new(%{player_id: Ecto.UUID.generate(), name: "  Alice  "})
    end

    test "rejects missing player_id" do
      assert {:error, changeset} = CreatePlayer.new(%{name: "Alice"})
      assert "can't be blank" in errors_on(changeset).player_id
    end

    test "rejects missing name" do
      assert {:error, changeset} = CreatePlayer.new(%{player_id: Ecto.UUID.generate()})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "rejects empty name" do
      assert {:error, changeset} =
               CreatePlayer.new(%{player_id: Ecto.UUID.generate(), name: ""})

      assert "can't be blank" in errors_on(changeset).name
    end

    test "rejects whitespace-only name (post-trim)" do
      assert {:error, changeset} =
               CreatePlayer.new(%{player_id: Ecto.UUID.generate(), name: "   "})

      assert "can't be blank" in errors_on(changeset).name
    end

    test "rejects a name already taken in the read model" do
      Repo.insert!(%Player{id: Ecto.UUID.generate(), name: "Alice"})

      assert {:error, changeset} =
               CreatePlayer.new(%{player_id: Ecto.UUID.generate(), name: "Alice"})

      assert "has already been taken" in errors_on(changeset).name
    end

    test "rejects a name already taken after trimming" do
      Repo.insert!(%Player{id: Ecto.UUID.generate(), name: "Alice"})

      assert {:error, changeset} =
               CreatePlayer.new(%{player_id: Ecto.UUID.generate(), name: "  Alice  "})

      assert "has already been taken" in errors_on(changeset).name
    end
  end
end
