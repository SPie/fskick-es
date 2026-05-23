defmodule Fskick.Games.GameCount do
  @moduledoc """
  Read-model row holding the total number of games recorded for a single
  season. The projector creates the row lazily on the first `GameCreated`
  for a season and increments `total` on every subsequent one.

  All-time totals are derived by `SUM(total)` across all rows.
  """

  use Ecto.Schema

  @primary_key {:season_id, :binary_id, autogenerate: false}
  schema "game_counts" do
    field :total, :integer, default: 0
  end
end
