defmodule Fskick.Games.Commands.CreateGameTest do
  use Fskick.DataCase, async: true

  alias Fskick.Games.Commands.CreateGame

  defp valid_attrs(overrides \\ %{}) do
    %{
      game_id: Ecto.UUID.generate(),
      season_id: Ecto.UUID.generate(),
      played_at: DateTime.utc_now(),
      team_a: [Ecto.UUID.generate(), Ecto.UUID.generate()],
      team_b: [Ecto.UUID.generate()],
      outcome: :team_a_won
    }
    |> Map.merge(overrides)
  end

  describe "new/1" do
    test "returns a command with valid attrs" do
      attrs = valid_attrs()

      assert {:ok, %CreateGame{outcome: :team_a_won}} = CreateGame.new(attrs)
    end

    test "accepts :team_b_won outcome" do
      assert {:ok, %CreateGame{outcome: :team_b_won}} =
               CreateGame.new(valid_attrs(%{outcome: :team_b_won}))
    end

    test "accepts :draw outcome" do
      assert {:ok, %CreateGame{outcome: :draw}} =
               CreateGame.new(valid_attrs(%{outcome: :draw}))
    end

    test "rejects unknown outcome" do
      assert {:error, changeset} = CreateGame.new(valid_attrs(%{outcome: :tie}))
      assert "is invalid" in errors_on(changeset).outcome
    end

    test "rejects missing fields" do
      assert {:error, changeset} = CreateGame.new(%{})
      errors = errors_on(changeset)

      for field <- [:game_id, :season_id, :played_at, :team_a, :team_b, :outcome] do
        assert "can't be blank" in Map.get(errors, field, []), "expected #{field} to be required"
      end
    end

    test "accepts an empty team_b with a :draw outcome (single-team draw)" do
      attrs = valid_attrs(%{team_b: [], outcome: :draw})

      assert {:ok, %CreateGame{team_b: [], outcome: :draw}} = CreateGame.new(attrs)
    end

    test "accepts an empty team_b with :team_b_won (populated team lost)" do
      attrs = valid_attrs(%{team_b: [], outcome: :team_b_won})

      assert {:ok, %CreateGame{team_b: [], outcome: :team_b_won}} = CreateGame.new(attrs)
    end

    test "accepts an empty team_a with a :draw outcome" do
      attrs = valid_attrs(%{team_a: [], outcome: :draw})

      assert {:ok, %CreateGame{team_a: [], outcome: :draw}} = CreateGame.new(attrs)
    end

    test "accepts an empty team_a with :team_a_won (populated team lost)" do
      attrs = valid_attrs(%{team_a: [], outcome: :team_a_won})

      assert {:ok, %CreateGame{team_a: [], outcome: :team_a_won}} = CreateGame.new(attrs)
    end

    test "rejects an empty team_b with :team_a_won (populated team can't win)" do
      assert {:error, changeset} =
               CreateGame.new(valid_attrs(%{team_b: [], outcome: :team_a_won}))

      assert "populated team cannot win without an opponent" in errors_on(changeset).outcome
    end

    test "rejects an empty team_a with :team_b_won (populated team can't win)" do
      assert {:error, changeset} =
               CreateGame.new(valid_attrs(%{team_a: [], outcome: :team_b_won}))

      assert "populated team cannot win without an opponent" in errors_on(changeset).outcome
    end

    test "rejects both teams empty" do
      assert {:error, changeset} =
               CreateGame.new(valid_attrs(%{team_a: [], team_b: [], outcome: :draw}))

      assert "at least one team must contain a player" in errors_on(changeset).team_a
    end

    test "rejects duplicate players within team_a" do
      id = Ecto.UUID.generate()

      assert {:error, changeset} = CreateGame.new(valid_attrs(%{team_a: [id, id]}))
      assert "contains duplicate players" in errors_on(changeset).team_a
    end

    test "rejects players appearing in both teams" do
      shared = Ecto.UUID.generate()
      other_a = Ecto.UUID.generate()
      other_b = Ecto.UUID.generate()

      assert {:error, changeset} =
               CreateGame.new(
                 valid_attrs(%{team_a: [shared, other_a], team_b: [shared, other_b]})
               )

      assert "shares players with team_a" in errors_on(changeset).team_b
    end
  end
end
