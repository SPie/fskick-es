defmodule Fskick.Seasons.Commands.CreateSeasonTest do
  use Fskick.DataCase, async: true

  alias Fskick.Seasons.Commands.CreateSeason
  alias Fskick.Seasons.Season

  describe "new/1" do
    test "returns a command with valid attrs" do
      id = Ecto.UUID.generate()

      assert {:ok, %CreateSeason{season_id: ^id, name: "2026"}} =
               CreateSeason.new(%{season_id: id, name: "2026"})
    end

    test "trims surrounding whitespace from name" do
      assert {:ok, %CreateSeason{name: "2026"}} =
               CreateSeason.new(%{season_id: Ecto.UUID.generate(), name: "  2026  "})
    end

    test "rejects missing season_id" do
      assert {:error, changeset} = CreateSeason.new(%{name: "2026"})
      assert "can't be blank" in errors_on(changeset).season_id
    end

    test "rejects missing name" do
      assert {:error, changeset} = CreateSeason.new(%{season_id: Ecto.UUID.generate()})
      assert "can't be blank" in errors_on(changeset).name
    end

    test "rejects empty name" do
      assert {:error, changeset} =
               CreateSeason.new(%{season_id: Ecto.UUID.generate(), name: ""})

      assert "can't be blank" in errors_on(changeset).name
    end

    test "rejects whitespace-only name (post-trim)" do
      assert {:error, changeset} =
               CreateSeason.new(%{season_id: Ecto.UUID.generate(), name: "   "})

      assert "can't be blank" in errors_on(changeset).name
    end

    test "rejects a name already taken in the read model" do
      Repo.insert!(%Season{id: Ecto.UUID.generate(), name: "2026"})

      assert {:error, changeset} =
               CreateSeason.new(%{season_id: Ecto.UUID.generate(), name: "2026"})

      assert "has already been taken" in errors_on(changeset).name
    end

    test "rejects a name already taken after trimming" do
      Repo.insert!(%Season{id: Ecto.UUID.generate(), name: "2026"})

      assert {:error, changeset} =
               CreateSeason.new(%{season_id: Ecto.UUID.generate(), name: "  2026  "})

      assert "has already been taken" in errors_on(changeset).name
    end
  end
end
