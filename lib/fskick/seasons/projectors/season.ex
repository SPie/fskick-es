defmodule Fskick.Seasons.Projectors.Season do
  use Commanded.Projections.Ecto,
    application: Fskick.App,
    repo: Fskick.Repo,
    name: "Fskick.Seasons.Projectors.Season"

  import Ecto.Query, only: [from: 2]

  alias Fskick.Seasons.Events.SeasonActivated
  alias Fskick.Seasons.Events.SeasonCreated
  alias Fskick.Seasons.Events.SeasonDeactivated

  project(%SeasonCreated{season_id: id, name: name, active: active}, metadata, fn multi ->
    Ecto.Multi.insert(multi, :season, %Fskick.Seasons.Season{
      id: id,
      name: name,
      active: active,
      created_at: metadata.created_at
    })
  end)

  project(%SeasonActivated{season_id: id}, _metadata, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :season,
      from(s in Fskick.Seasons.Season, where: s.id == ^id),
      set: [active: true, updated_at: NaiveDateTime.utc_now(:second)]
    )
  end)

  project(%SeasonDeactivated{season_id: id}, _metadata, fn multi ->
    Ecto.Multi.update_all(
      multi,
      :season,
      from(s in Fskick.Seasons.Season, where: s.id == ^id),
      set: [active: false, updated_at: NaiveDateTime.utc_now(:second)]
    )
  end)
end
