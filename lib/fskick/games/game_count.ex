defmodule Fskick.Games.GameCount do
  @moduledoc """
  Singleton read-model row holding the total number of games recorded.
  The migration seeds the single row with `id: 1, total: 0`; the
  projector increments `total` on every `GameCreated`.
  """

  use Ecto.Schema

  @primary_key {:id, :integer, autogenerate: false}
  schema "game_counts" do
    field :total, :integer, default: 0
  end
end
