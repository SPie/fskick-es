defmodule Fskick.Games.PlayerResult do
  @moduledoc """
  Read-model row recording a single player's outcome in a single game.
  Written only by `Fskick.Games.Projectors.PlayerResults`; one row per
  (player, game) pair. The `played_at` column carries the ordering key
  used by `Fskick.Streaks` to walk a player's results chronologically.

  A `:draw` outcome stores `won: true` for both teams, matching the
  product rule used by `Fskick.Games.Projectors.PlayerStats`.
  """

  use Ecto.Schema

  @primary_key false
  schema "player_results" do
    field :player_id, :binary_id, primary_key: true
    field :game_id, :binary_id, primary_key: true
    field :season_id, :binary_id
    field :played_at, :utc_datetime_usec
    field :won, :boolean
  end
end
