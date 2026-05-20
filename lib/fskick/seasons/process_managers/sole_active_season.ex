defmodule Fskick.Seasons.ProcessManagers.SoleActiveSeason do
  @moduledoc """
  Enforces the cross-aggregate invariant: at most one season is active
  at a time.

  Listens for `SeasonActivated` events. When a season becomes active
  and another season was previously active, it dispatches
  `DeactivateSeason` for the previous one. Tracks the currently-active
  season id in its own state, rebuilt from the event store.
  """

  use Commanded.ProcessManagers.ProcessManager,
    application: Fskick.App,
    name: "Fskick.Seasons.ProcessManagers.SoleActiveSeason"

  alias Fskick.Seasons.Commands.DeactivateSeason
  alias Fskick.Seasons.Events.SeasonActivated
  alias Fskick.Seasons.Events.SeasonDeactivated
  alias Fskick.Seasons.ProcessManagers.SoleActiveSeason

  @singleton "sole-active-season"

  @derive Jason.Encoder
  defstruct [:active_season_id]

  def interested?(%SeasonActivated{}), do: {:start, @singleton}
  def interested?(%SeasonDeactivated{}), do: {:continue, @singleton}

  def handle(%SoleActiveSeason{active_season_id: nil}, %SeasonActivated{}), do: []

  def handle(%SoleActiveSeason{active_season_id: id}, %SeasonActivated{season_id: id}), do: []

  def handle(%SoleActiveSeason{active_season_id: prev_id}, %SeasonActivated{}) do
    %DeactivateSeason{season_id: prev_id}
  end

  def apply(%SoleActiveSeason{} = pm, %SeasonActivated{season_id: id}) do
    %SoleActiveSeason{pm | active_season_id: id}
  end

  def apply(%SoleActiveSeason{active_season_id: id} = pm, %SeasonDeactivated{season_id: id}) do
    %SoleActiveSeason{pm | active_season_id: nil}
  end

  def apply(%SoleActiveSeason{} = pm, %SeasonDeactivated{}), do: pm
end
