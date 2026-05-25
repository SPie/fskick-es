defmodule FskickWeb.HomeLiveTest do
  use FskickWeb.ConnCase
  import Phoenix.LiveViewTest

  test "renders the home shell with FSKick and Imprint", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ "FSKick"
    assert has_element?(view, "a", "Imprint")
  end

  test "renders the seasons table column headers", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Pos"
    assert html =~ "Player"
    assert html =~ "Points"
    assert html =~ "Wins"
    assert html =~ "Games"
    assert html =~ "Win Ratio"
  end
end
