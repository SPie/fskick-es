defmodule Fskick.Players.Aggregates.Player do
  @moduledoc """
  Player aggregate root. Enforces state-dependent invariants only —
  structural validation lives on the command.
  """

  alias Fskick.Players.Aggregates.Player
  alias Fskick.Players.Commands.CreatePlayer
  alias Fskick.Players.Events.PlayerCreated

  defstruct [:player_id, :name]

  def execute(%Player{player_id: nil}, %CreatePlayer{player_id: id, name: name}) do
    %PlayerCreated{player_id: id, name: name}
  end

  def execute(%Player{}, %CreatePlayer{}) do
    {:error, :already_created}
  end

  def apply(%Player{} = state, %PlayerCreated{player_id: id, name: name}) do
    %Player{state | player_id: id, name: name}
  end
end
