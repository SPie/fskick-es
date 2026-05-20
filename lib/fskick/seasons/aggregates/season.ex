defmodule Fskick.Seasons.Aggregates.Season do
  @moduledoc """
  Season aggregate root. Enforces state-dependent invariants only —
  structural validation lives on the command.
  """

  alias Fskick.Seasons.Aggregates.Season
  alias Fskick.Seasons.Commands.ActivateSeason
  alias Fskick.Seasons.Commands.CreateSeason
  alias Fskick.Seasons.Commands.DeactivateSeason
  alias Fskick.Seasons.Events.SeasonActivated
  alias Fskick.Seasons.Events.SeasonCreated
  alias Fskick.Seasons.Events.SeasonDeactivated

  defstruct [:season_id, :name, :active]

  def execute(%Season{season_id: nil}, %CreateSeason{season_id: id, name: name}) do
    %SeasonCreated{season_id: id, name: name, active: false}
  end

  def execute(%Season{}, %CreateSeason{}) do
    {:error, :already_created}
  end

  def execute(%Season{season_id: nil}, %ActivateSeason{}) do
    {:error, :not_found}
  end

  def execute(%Season{active: true}, %ActivateSeason{}) do
    {:error, :already_active}
  end

  def execute(%Season{season_id: id}, %ActivateSeason{}) do
    %SeasonActivated{season_id: id}
  end

  def execute(%Season{season_id: nil}, %DeactivateSeason{}) do
    {:error, :not_found}
  end

  def execute(%Season{active: false}, %DeactivateSeason{}) do
    {:error, :already_inactive}
  end

  def execute(%Season{season_id: id}, %DeactivateSeason{}) do
    %SeasonDeactivated{season_id: id}
  end

  def apply(%Season{} = state, %SeasonCreated{season_id: id, name: name, active: active}) do
    %Season{state | season_id: id, name: name, active: active}
  end

  def apply(%Season{} = state, %SeasonActivated{}) do
    %Season{state | active: true}
  end

  def apply(%Season{} = state, %SeasonDeactivated{}) do
    %Season{state | active: false}
  end
end
