defmodule Fskick.Router do
  use Commanded.Commands.Router

  alias Fskick.Players.Aggregates.Player
  alias Fskick.Players.Commands.CreatePlayer

  identify(Player, by: :player_id, prefix: "player-")
  dispatch([CreatePlayer], to: Player)
end
