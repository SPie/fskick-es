defmodule Fskick.PlayersTest do
  use Fskick.DataCase, async: false

  alias Fskick.Games
  alias Fskick.Games.PlayerResult
  alias Fskick.Players
  alias Fskick.Players.Player
  alias Fskick.Players.PlayerStat
  alias Fskick.Seasons

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

  describe "favorite_team/2" do
    setup do
      unique = System.unique_integer([:positive])
      {:ok, season} = Seasons.create_season("season-#{unique}")
      {:ok, _} = Seasons.activate_season(season.name)
      {:ok, alice} = Players.create_player("Alice-#{unique}")
      {:ok, b1} = Players.create_player("B1-#{unique}")
      {:ok, b2} = Players.create_player("B2-#{unique}")
      {:ok, b3} = Players.create_player("B3-#{unique}")
      {:ok, t3} = Players.create_player("T3-#{unique}")
      {:ok, t4} = Players.create_player("T4-#{unique}")
      {:ok, t5} = Players.create_player("T5-#{unique}")

      baseline = Repo.aggregate(PlayerResult, :count)

      # b1 with alice: 2W/3G → 67%
      create_game!([alice, b1], [b2, b3], :team_a_won, ~U[2026-03-01 12:00:00.000000Z])
      create_game!([alice, b1], [b2, b3], :team_a_won, ~U[2026-03-02 12:00:00.000000Z])
      # b2 with alice (g3): 1W start
      create_game!([alice, b2], [b1, b3], :team_a_won, ~U[2026-03-03 12:00:00.000000Z])
      # b1, b2 both with alice; team_b wins → b1, b2 each get a loss with alice
      create_game!([alice, b1, b2], [b3, t3], :team_b_won, ~U[2026-03-04 12:00:00.000000Z])
      # b2 with alice loses → b2: 1W/3G total = 33%
      create_game!([alice, b2], [b1, b3], :team_b_won, ~U[2026-03-05 12:00:00.000000Z])
      # t3 with alice loses → 0W/1G = 0%
      create_game!([alice, t3], [b1, b2], :team_b_won, ~U[2026-03-06 12:00:00.000000Z])
      # t4 with alice wins → 1W/1G = 100%
      create_game!([alice, t4], [b1, b2], :team_a_won, ~U[2026-03-07 12:00:00.000000Z])
      # t5 with alice wins → 1W/1G = 100%
      create_game!([alice, t5], [b1, b2], :team_a_won, ~U[2026-03-08 12:00:00.000000Z])

      # 7 games × 4 players + 1 game × 5 players = 33 player_results rows.
      await_results(baseline + 33)

      %{
        alice: alice,
        b1: b1,
        b2: b2,
        b3: b3,
        t3: t3,
        t4: t4,
        t5: t5
      }
    end

    test "excludes opponents — b3 never appears (was always on the other team)", %{
      alice: alice,
      b3: b3
    } do
      result = Players.favorite_team(alice.id, sort: :wins, limit: 10)
      refute Enum.any?(result, &(&1.player_id == b3.id))
    end

    test "excludes the target player themselves", %{alice: alice} do
      result = Players.favorite_team(alice.id, sort: :wins, limit: 10)
      refute Enum.any?(result, &(&1.player_id == alice.id))
    end

    test "aggregates wins and games over shared-team games only", %{alice: alice, b1: b1} do
      result = Players.favorite_team(alice.id, sort: :wins, limit: 10)
      b1_stat = Enum.find(result, &(&1.player_id == b1.id))
      assert %PlayerStat{wins: 2, games: 3} = b1_stat
    end

    test "default sort is :points, default limit is 5", %{alice: alice} do
      result = Players.favorite_team(alice.id)
      assert length(result) == 5
      assert Enum.sort_by(result, & &1.points, :desc) == result
    end

    test "limit caps the result", %{alice: alice} do
      result = Players.favorite_team(alice.id, sort: :wins, limit: 3)
      assert length(result) == 3
    end

    test "sorting by :wins ranks b1 first (most shared wins)", %{alice: alice, b1: b1} do
      assert [%PlayerStat{player_id: id, wins: 2} | _] =
               Players.favorite_team(alice.id, sort: :wins, limit: 5)

      assert id == b1.id
    end

    test "sorting by :win_ratio ranks 100% players (t4, t5) above 67% (b1)", %{
      alice: alice,
      t4: t4,
      t5: t5,
      b1: b1
    } do
      [first, second, third | _] = Players.favorite_team(alice.id, sort: :win_ratio, limit: 5)
      assert MapSet.new([first.player_id, second.player_id]) == MapSet.new([t4.id, t5.id])
      assert third.player_id == b1.id
    end

    test "top-N membership follows the sort (:wins vs :win_ratio differ at limit=3)", %{
      alice: alice,
      b2: b2,
      t4: t4,
      t5: t5
    } do
      by_wins = MapSet.new(Players.favorite_team(alice.id, sort: :wins, limit: 3), & &1.player_id)

      by_ratio =
        MapSet.new(Players.favorite_team(alice.id, sort: :win_ratio, limit: 3), & &1.player_id)

      # b1 (the 2W player) is in both — it dominates either way.
      # By wins: b2 is the next-highest with 1W/3G, edging out t4 and t5 on the
      # games tiebreaker — so b2 is included.
      assert b2.id in by_wins
      # By win_ratio: t4 and t5 (both 100%) edge out b2 — b2 drops out.
      refute b2.id in by_ratio
      # Conversely, t4 and t5 are in the win_ratio top-3 but absent from the
      # wins top-3.
      assert MapSet.subset?(MapSet.new([t4.id, t5.id]), by_ratio)
    end

    test "returns [] for a player with no games" do
      {:ok, ghost} = Players.create_player("Ghost-#{System.unique_integer([:positive])}")
      assert Players.favorite_team(ghost.id) == []
    end

    test "games_ratio uses the target's own total games as denominator", %{
      alice: alice,
      b1: b1
    } do
      result = Players.favorite_team(alice.id, sort: :wins, limit: 10)
      b1_stat = Enum.find(result, &(&1.player_id == b1.id))
      # Alice played 8 games total; b1 shared the team in 3.
      # games_ratio is in percent — 3/8 * 100 = 37.5
      assert_in_delta b1_stat.games_ratio, 37.5, 0.01
    end
  end

  defp create_game!(team_a, team_b, outcome, played_at) do
    {:ok, command} =
      Games.create_game(%{
        team_a_names: Enum.map(team_a, & &1.name),
        team_b_names: Enum.map(team_b, & &1.name),
        outcome: outcome,
        played_at: played_at
      })

    command
  end

  defp await_results(expected, timeout \\ 5_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_await_results(expected, deadline)
  end

  defp do_await_results(expected, deadline) do
    if Repo.aggregate(PlayerResult, :count) >= expected do
      :ok
    else
      if System.monotonic_time(:millisecond) >= deadline do
        flunk("PlayerResults projector did not catch up: expected at least #{expected} rows")
      else
        Process.sleep(25)
        do_await_results(expected, deadline)
      end
    end
  end
end
