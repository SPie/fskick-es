defmodule Fskick.StreaksTest do
  use Fskick.DataCase, async: false

  alias Fskick.Games
  alias Fskick.Games.PlayerResult
  alias Fskick.Players
  alias Fskick.Seasons
  alias Fskick.Streaks
  alias Fskick.Streaks.Streak

  describe "all-time streaks across a seeded set of games" do
    setup do
      unique = System.unique_integer([:positive])
      {:ok, season} = Seasons.create_season("season-#{unique}")
      {:ok, _} = Seasons.activate_season(season.name)
      {:ok, alice} = Players.create_player("Alice-#{unique}")
      {:ok, bob} = Players.create_player("Bob-#{unique}")
      {:ok, carol} = Players.create_player("Carol-#{unique}")
      {:ok, dave} = Players.create_player("Dave-#{unique}")

      baseline = Repo.aggregate(PlayerResult, :count)

      games = [
        create_game!(
          [alice, bob],
          [carol, dave],
          :team_a_won,
          ~U[2026-01-01 12:00:00.000000Z]
        ),
        create_game!(
          [alice, carol],
          [bob, dave],
          :draw,
          ~U[2026-01-02 12:00:00.000000Z]
        ),
        create_game!(
          [alice, dave],
          [bob, carol],
          :team_b_won,
          ~U[2026-01-03 12:00:00.000000Z]
        ),
        create_game!(
          [alice, bob],
          [carol, dave],
          :team_a_won,
          ~U[2026-01-04 12:00:00.000000Z]
        )
      ]

      await_results(baseline + length(games) * 4)

      %{alice: alice, bob: bob, carol: carol, dave: dave}
    end

    test "last_results/2 returns the player's results oldest → newest", %{alice: alice} do
      assert Streaks.last_results(alice.id, 5) == [true, true, false, true]
    end

    test "last_results/2 limits to the requested count", %{bob: bob} do
      assert Streaks.last_results(bob.id, 2) == [true, true]
    end

    test "last_results/2 returns [] for a player with no games" do
      {:ok, ghost} = Players.create_player("Ghost-#{System.unique_integer([:positive])}")
      assert Streaks.last_results(ghost.id) == []
    end

    test "longest_streak/2 finds the longest consecutive run", %{
      alice: alice,
      bob: bob,
      dave: dave
    } do
      assert Streaks.longest_streak(alice.id, :win) == 2
      assert Streaks.longest_streak(alice.id, :loss) == 1
      assert Streaks.longest_streak(bob.id, :win) == 4
      assert Streaks.longest_streak(bob.id, :loss) == 0
      assert Streaks.longest_streak(dave.id, :win) == 1
      assert Streaks.longest_streak(dave.id, :loss) == 2
    end

    test "longest_streak/2 returns 0 for a player with no games" do
      {:ok, ghost} = Players.create_player("Ghost-#{System.unique_integer([:positive])}")
      assert Streaks.longest_streak(ghost.id, :win) == 0
      assert Streaks.longest_streak(ghost.id, :loss) == 0
    end

    test "longest_winning_streak/0 surfaces the top player", %{bob: bob} do
      assert %Streak{player_id: id, number: 4} = Streaks.longest_winning_streak()
      assert id == bob.id
    end

    test "longest_losing_streak/0 surfaces the top player", %{dave: dave} do
      assert %Streak{player_id: id, number: 2} = Streaks.longest_losing_streak()
      assert id == dave.id
    end

    test "current_streaks/2 returns ongoing wins, descending, zero-filtered", %{
      alice: alice,
      bob: bob
    } do
      streaks = Streaks.current_streaks(:win, 10)
      assert Enum.map(streaks, & &1.number) == [4, 1]
      assert Enum.map(streaks, & &1.player_id) == [bob.id, alice.id]
    end

    test "current_streaks/2 returns ongoing losses, descending, zero-filtered", %{
      carol: carol,
      dave: dave
    } do
      streaks = Streaks.current_streaks(:loss, 10)
      assert Enum.map(streaks, & &1.number) == [2, 1]
      assert Enum.map(streaks, & &1.player_id) == [dave.id, carol.id]
    end

    test "current_streaks/2 honours the limit", %{bob: bob} do
      assert [%Streak{player_id: id}] = Streaks.current_streaks(:win, 1)
      assert id == bob.id
    end
  end

  describe "no games" do
    test "longest_winning_streak/0 and longest_losing_streak/0 return nil" do
      assert Streaks.longest_winning_streak() == nil
      assert Streaks.longest_losing_streak() == nil
    end

    test "current_streaks/2 returns []" do
      assert Streaks.current_streaks(:win) == []
      assert Streaks.current_streaks(:loss) == []
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
