defmodule Fskick.Players.Events.PlayerCreated do
  @derive Jason.Encoder
  defstruct [:player_id, :name]
end
