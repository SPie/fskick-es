defmodule Fskick.Router do
  use Commanded.Commands.Router

  alias Fskick.Players.Aggregates.Player
  alias Fskick.Players.Commands.CreatePlayer
  alias Fskick.Seasons.Aggregates.Season
  alias Fskick.Seasons.Commands.CreateSeason

  identify(Player, by: :player_id, prefix: "player-")
  dispatch([CreatePlayer], to: Player)

  identify(Season, by: :season_id, prefix: "season-")
  dispatch([CreateSeason], to: Season)
end
