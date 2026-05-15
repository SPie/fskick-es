defmodule FskickWeb.PageController do
  use FskickWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
