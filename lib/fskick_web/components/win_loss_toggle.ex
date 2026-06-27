defmodule FskickWeb.Components.WinLossToggle do
  @moduledoc """
  Win/loss toggle switch. Green/checked = **W** (win-based view), red/unchecked
  = **L** (loss-based view). Used to flip rankings between favorite (wins) and
  least-favorite (losses); also the streak page's current-streak toggle.

  The enclosing LiveView handles the `phx-click` event named by `:event` and
  binds `:checked` to its own win/loss state.
  """
  use Phoenix.Component

  attr :checked, :boolean, required: true
  attr :event, :string, required: true

  def win_loss_toggle(assigns) do
    ~H"""
    <label class="flex items-center relative w-max cursor-pointer select-none py-5">
      <input
        type="checkbox"
        name="win"
        checked={@checked}
        phx-click={@event}
        class="peer appearance-none transition-colors cursor-pointer w-14 h-7 rounded-full focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-black bg-red-700 checked:bg-green-700"
      />
      <span class="absolute font-medium text-xs uppercase right-1 text-white">L</span>
      <span class="absolute font-medium text-xs uppercase right-8 text-white">W</span>
      <span class="w-7 h-7 right-7 absolute rounded-full transform transition-transform bg-gray-200 peer-checked:translate-x-7" />
    </label>
    """
  end
end
