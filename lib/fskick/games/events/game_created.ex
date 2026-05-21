defmodule Fskick.Games.Events.GameCreated do
  @derive Jason.Encoder
  defstruct [
    :game_id,
    :season_id,
    :played_at,
    :team_a,
    :team_b,
    :outcome
  ]
end
