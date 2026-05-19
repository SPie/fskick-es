defmodule Fskick.SeasonsTest do
  use Fskick.DataCase

  alias Fskick.Seasons
  alias Fskick.Seasons.Season

  describe "create_season/1" do
    test "creates a season and projects it to the read model" do
      assert {:ok, %Season{name: "2026", id: id, active: false}} =
               Seasons.create_season("2026")

      assert is_binary(id)
      assert Seasons.get_season_by_name("2026")
    end

    test "creates the season as inactive" do
      assert {:ok, %Season{active: false}} = Seasons.create_season("2026")
    end

    test "trims surrounding whitespace from the name" do
      assert {:ok, %Season{name: "2026"}} = Seasons.create_season("  2026  ")
    end

    test "rejects duplicate names" do
      assert {:ok, _} = Seasons.create_season("2026")
      assert {:error, %Ecto.Changeset{} = changeset} = Seasons.create_season("2026")
      assert "has already been taken" in errors_on(changeset).name
    end

    test "rejects duplicate names after trimming" do
      assert {:ok, _} = Seasons.create_season("2026")
      assert {:error, %Ecto.Changeset{} = changeset} = Seasons.create_season("  2026  ")
      assert "has already been taken" in errors_on(changeset).name
    end

    test "rejects blank name" do
      assert {:error, %Ecto.Changeset{}} = Seasons.create_season("")
      assert {:error, %Ecto.Changeset{}} = Seasons.create_season("   ")
    end
  end
end
