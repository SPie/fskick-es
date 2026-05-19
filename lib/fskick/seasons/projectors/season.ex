defmodule Fskick.Seasons.Projectors.Season do
  use Commanded.Projections.Ecto,
    application: Fskick.App,
    repo: Fskick.Repo,
    name: "Fskick.Seasons.Projectors.Season"

  alias Fskick.Seasons.Events.SeasonCreated

  project(%SeasonCreated{season_id: id, name: name, active: active}, _metadata, fn multi ->
    Ecto.Multi.insert(multi, :season, %Fskick.Seasons.Season{
      id: id,
      name: name,
      active: active
    })
  end)
end
