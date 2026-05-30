defmodule FskickWeb.StreaksLiveTest do
  use FskickWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Fskick.Games
  alias Fskick.Games.PlayerResult
  alias Fskick.Players
  alias Fskick.Repo
  alias Fskick.Seasons

  test "renders the streaks page shell with both section headings", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/streaks")
    assert html =~ "Streaks"
    assert html =~ "Longest Streaks"
    assert html =~ "Current Streaks"
  end

  describe "with seeded games" do
    setup do
      unique = System.unique_integer([:positive])
      {:ok, season} = Seasons.create_season("season-#{unique}")
      {:ok, _} = Seasons.activate_season(season.name)
      {:ok, alice} = Players.create_player("Alice-#{unique}")
      {:ok, bob} = Players.create_player("Bob-#{unique}")
      {:ok, carol} = Players.create_player("Carol-#{unique}")

      baseline = Repo.aggregate(PlayerResult, :count)

      # Alice + Bob beat Carol three times in a row.
      games = [
        {[alice, bob], [carol], :team_a_won, ~U[2026-02-01 12:00:00.000000Z]},
        {[alice, bob], [carol], :team_a_won, ~U[2026-02-02 12:00:00.000000Z]},
        {[alice, bob], [carol], :team_a_won, ~U[2026-02-03 12:00:00.000000Z]}
      ]

      Enum.each(games, fn {team_a, team_b, outcome, played_at} ->
        {:ok, _} =
          Games.create_game(%{
            team_a_names: Enum.map(team_a, & &1.name),
            team_b_names: Enum.map(team_b, & &1.name),
            outcome: outcome,
            played_at: played_at
          })
      end)

      # 3 games × 3 players = 9 player_results rows added.
      await_results(baseline + 9)

      %{alice: alice, bob: bob, carol: carol}
    end

    test "lists the longest-streak players by name", %{conn: conn, alice: alice, carol: carol} do
      {:ok, _view, html} = live(conn, ~p"/streaks")
      assert html =~ alice.name
      assert html =~ carol.name
      assert html =~ "3"
    end

    test "the W/L switch flips the current-streaks list to losing", %{
      conn: conn,
      alice: alice,
      carol: carol
    } do
      {:ok, view, _html} = live(conn, ~p"/streaks")

      win_html = render(view)
      # Alice has a current winning streak; Carol does not.
      assert win_html =~ alice.name

      loss_html =
        view
        |> element("input[name='win']")
        |> render_click()

      # After flipping to losing streaks Carol's name appears in the list.
      assert loss_html =~ carol.name
    end
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
