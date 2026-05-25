defmodule FskickWeb.HomeLiveTest do
  use FskickWeb.ConnCase
  import Phoenix.LiveViewTest

  test "shows FSKick brand and Imprint link", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ "FSKick"
    assert has_element?(view, "a", "Imprint")
  end
end
