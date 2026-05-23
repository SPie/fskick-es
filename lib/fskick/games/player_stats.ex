defmodule Fskick.Games.PlayerStats do
  @moduledoc """
  Read-model row for per-(season, player) game counters. Written only by
  `Fskick.Games.Projectors.PlayerStats`; one row per (season, player) pair
  that has played at least one game in that season. Derived stats (points,
  ratios, position) are computed at read time from these raw counters.

  All-time numbers are derived by `GROUP BY player_id, SUM(wins, games)` —
  there is no separate all-time table.
  """

  use Ecto.Schema

  @primary_key false
  schema "player_stats" do
    field :season_id, :binary_id, primary_key: true
    field :player_id, :binary_id, primary_key: true
    field :wins, :integer, default: 0
    field :games, :integer, default: 0
  end
end
