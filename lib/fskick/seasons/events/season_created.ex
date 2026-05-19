defmodule Fskick.Seasons.Events.SeasonCreated do
  @derive Jason.Encoder
  defstruct [:season_id, :name, :active]
end
