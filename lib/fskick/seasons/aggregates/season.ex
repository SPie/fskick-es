defmodule Fskick.Seasons.Aggregates.Season do
  @moduledoc """
  Season aggregate root. Enforces state-dependent invariants only —
  structural validation lives on the command.
  """

  alias Fskick.Seasons.Aggregates.Season
  alias Fskick.Seasons.Commands.CreateSeason
  alias Fskick.Seasons.Events.SeasonCreated

  defstruct [:season_id, :name, :active]

  def execute(%Season{season_id: nil}, %CreateSeason{season_id: id, name: name}) do
    %SeasonCreated{season_id: id, name: name, active: false}
  end

  def execute(%Season{}, %CreateSeason{}) do
    {:error, :already_created}
  end

  def apply(%Season{} = state, %SeasonCreated{season_id: id, name: name, active: active}) do
    %Season{state | season_id: id, name: name, active: active}
  end
end
