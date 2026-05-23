defmodule Fskick.Players.PlayerStat do
  @moduledoc """
  Derived player ranking row returned by `Fskick.Players.list_player_stats/1`.

  Distinct from `Fskick.Games.PlayerStats`: that schema is the persisted
  read-model row holding raw counters (`wins`, `games`); this struct is
  the computed view including derivations (`points`, `win_ratio`,
  `games_ratio`) and rank (`position`).
  """

  defstruct [
    :position,
    :name,
    :wins,
    :games,
    :points,
    :win_ratio,
    :games_ratio
  ]
end
