defmodule FskickWeb.HomeLive do
  use FskickWeb, :live_view

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}></Layouts.app>
    """
  end
end
