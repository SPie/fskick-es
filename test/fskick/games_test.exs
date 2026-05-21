defmodule Fskick.GamesTest do
  use Fskick.DataCase, async: false

  alias Fskick.Games
  alias Fskick.Games.Commands.CreateGame
  alias Fskick.Players
  alias Fskick.Seasons

  describe "create_game/1" do
    setup do
      unique = System.unique_integer([:positive])
      {:ok, season} = Seasons.create_season("season-#{unique}")
      {:ok, _} = Seasons.activate_season(season.name)
      {:ok, alice} = Players.create_player("Alice-#{unique}")
      {:ok, bob} = Players.create_player("Bob-#{unique}")
      {:ok, carol} = Players.create_player("Carol-#{unique}")
      {:ok, dave} = Players.create_player("Dave-#{unique}")

      %{
        season: season,
        alice: alice,
        bob: bob,
        carol: carol,
        dave: dave
      }
    end

    test "creates a game using the currently-active season", %{
      season: season,
      alice: alice,
      bob: bob,
      carol: carol,
      dave: dave
    } do
      attrs = %{
        team_a_names: [alice.name, bob.name],
        team_b_names: [carol.name, dave.name],
        outcome: :team_a_won
      }

      assert {:ok, %CreateGame{} = command} = Games.create_game(attrs)
      assert command.season_id == season.id
      assert command.outcome == :team_a_won
      assert Enum.sort(command.team_a) == Enum.sort([alice.id, bob.id])
      assert Enum.sort(command.team_b) == Enum.sort([carol.id, dave.id])
    end

    test "accepts a draw outcome", %{alice: alice, carol: carol} do
      attrs = %{
        team_a_names: [alice.name],
        team_b_names: [carol.name],
        outcome: :draw
      }

      assert {:ok, %CreateGame{outcome: :draw}} = Games.create_game(attrs)
    end

    test "uses the supplied played_at when provided", %{alice: alice, carol: carol} do
      played_at = ~U[2026-04-01 00:00:00.000000Z]

      attrs = %{
        team_a_names: [alice.name],
        team_b_names: [carol.name],
        outcome: :team_a_won,
        played_at: played_at
      }

      assert {:ok, %CreateGame{played_at: ^played_at}} = Games.create_game(attrs)
    end

    test "resolves an explicit season name", %{alice: alice, carol: carol} do
      unique = System.unique_integer([:positive])
      {:ok, other_season} = Seasons.create_season("other-#{unique}")

      attrs = %{
        team_a_names: [alice.name],
        team_b_names: [carol.name],
        outcome: :team_a_won,
        season_name: other_season.name
      }

      assert {:ok, %CreateGame{season_id: season_id}} = Games.create_game(attrs)
      assert season_id == other_season.id
    end

    test "returns {:error, {:players_not_found, names}} for unknown player names", %{
      alice: alice
    } do
      attrs = %{
        team_a_names: [alice.name],
        team_b_names: ["Ghost"],
        outcome: :team_a_won
      }

      assert {:error, {:players_not_found, ["Ghost"]}} = Games.create_game(attrs)
    end

    test "returns {:error, {:season_not_found, name}} for unknown season", %{
      alice: alice,
      carol: carol
    } do
      attrs = %{
        team_a_names: [alice.name],
        team_b_names: [carol.name],
        outcome: :team_a_won,
        season_name: "no-such-season"
      }

      assert {:error, {:season_not_found, "no-such-season"}} = Games.create_game(attrs)
    end

    test "returns a changeset error when a player appears in both teams", %{alice: alice} do
      attrs = %{
        team_a_names: [alice.name],
        team_b_names: [alice.name],
        outcome: :team_a_won
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Games.create_game(attrs)
      assert "shares players with team_a" in errors_on(changeset).team_b
    end
  end

  describe "create_game/1 without an active season" do
    test "returns {:error, :no_active_season} when no --season passed and no active season exists" do
      unique = System.unique_integer([:positive])
      {:ok, alice} = Players.create_player("Alice-#{unique}")
      {:ok, carol} = Players.create_player("Carol-#{unique}")

      attrs = %{
        team_a_names: [alice.name],
        team_b_names: [carol.name],
        outcome: :team_a_won
      }

      assert {:error, :no_active_season} = Games.create_game(attrs)
    end
  end
end
