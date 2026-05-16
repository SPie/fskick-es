defmodule Fskick.Players.Projectors.Player do
  use Commanded.Projections.Ecto,
    application: Fskick.App,
    repo: Fskick.Repo,
    name: "Fskick.Players.Projectors.Player"

  alias Fskick.Players.Events.PlayerCreated

  project(%PlayerCreated{player_id: id, name: name}, _metadata, fn multi ->
    Ecto.Multi.insert(multi, :player, %Fskick.Players.Player{id: id, name: name})
  end)
end
