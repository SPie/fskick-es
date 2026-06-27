defmodule FskickWeb.PlayerDetailLiveTest do
  use FskickWeb.ConnCase
  import Phoenix.LiveViewTest

  alias Fskick.Players

  test "renders the player name, Stats heading, and stats column headers", %{conn: conn} do
    {:ok, player} = Players.create_player("Alice")

    {:ok, _view, html} = live(conn, ~p"/players/#{player.id}")

    assert html =~ "Alice"
    assert html =~ "Stats"
    assert html =~ "Pos"
    assert html =~ "Player"
    assert html =~ "Points"
    assert html =~ "Wins"
    assert html =~ "Games"
    assert html =~ "Win Ratio"
    assert html =~ "Streak"
    assert html =~ "Longest Streaks"
    assert html =~ "won games"
    assert html =~ "lost games"
    assert html =~ "Favorite Team"
    assert html =~ "Favorite Opponents"
  end

  test "toggling the team view switches to least-favorite labels and back", %{conn: conn} do
    {:ok, player} = Players.create_player("Alice")

    {:ok, view, _html} = live(conn, ~p"/players/#{player.id}")

    assert has_element?(view, "input[phx-click='toggle_team']")
    assert render(view) =~ "Favorite Team"

    html = view |> element("input[phx-click='toggle_team']") |> render_click()

    assert html =~ "Worst Team"
    assert html =~ "Losses"
    assert html =~ "Loss Ratio"

    html = view |> element("input[phx-click='toggle_team']") |> render_click()

    refute html =~ "Worst Team"
  end

  test "toggling the opponents view switches to least-favorite labels", %{conn: conn} do
    {:ok, player} = Players.create_player("Bob")

    {:ok, view, _html} = live(conn, ~p"/players/#{player.id}")

    assert has_element?(view, "input[phx-click='toggle_opponents']")

    html = view |> element("input[phx-click='toggle_opponents']") |> render_click()

    assert html =~ "Toughest Opponents"
  end

  test "redirects to /players when the UUID matches no player", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/players"}}} =
             live(conn, ~p"/players/#{Ecto.UUID.generate()}")
  end

  test "redirects to /players when the id is not a valid UUID", %{conn: conn} do
    assert {:error, {:live_redirect, %{to: "/players"}}} =
             live(conn, ~p"/players/not-a-uuid")
  end
end
