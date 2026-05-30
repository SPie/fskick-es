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
