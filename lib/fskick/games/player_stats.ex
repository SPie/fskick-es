defmodule Fskick.Games.PlayerStats do
  @moduledoc """
  Read-model row for per-player game counters. Written only by
  `Fskick.Games.Projectors.PlayerStats`; one row per player who has
  played at least one game. Derived stats (points, ratios, position)
  are computed at read time from these raw counters.
  """

  use Ecto.Schema

  @primary_key {:player_id, :binary_id, autogenerate: false}
  schema "player_stats" do
    field :wins, :integer, default: 0
    field :games, :integer, default: 0
  end
end
