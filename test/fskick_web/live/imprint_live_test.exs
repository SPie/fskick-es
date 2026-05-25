defmodule FskickWeb.ImprintLiveTest do
  use FskickWeb.ConnCase
  import Phoenix.LiveViewTest

  test "shows Impressum heading", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/imprint")
    assert html =~ "Impressum"
  end
end
