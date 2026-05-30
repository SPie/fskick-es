defmodule FskickWeb.Components.Streak do
  @moduledoc """
  Shared streak presentational components. `streak_circles/1` renders a
  row of green/red circles from a list of `won` booleans (oldest →
  newest, left → right). Used by the player detail page.
  """

  use Phoenix.Component

  attr :results, :list, required: true

  def streak_circles(assigns) do
    ~H"""
    <span
      :for={won <- @results}
      class={["inline-block rounded-full w-8 h-8", color(won)]}
    />
    """
  end

  defp color(true), do: "bg-green-700"
  defp color(false), do: "bg-red-700"
end
