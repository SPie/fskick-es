defmodule FskickWeb.PlayersLiveTest do
  use FskickWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders the players page with the same column headers", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/players")
    assert html =~ "Players"
    assert html =~ "Pos"
    assert html =~ "Player"
    assert html =~ "Points"
    assert html =~ "Wins"
    assert html =~ "Games"
    assert html =~ "Win Ratio"
  end
end
