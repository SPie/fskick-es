defmodule Fskick.Seasons.Season do
  @moduledoc """
  Read-model schema for seasons.

  Written by `Fskick.Seasons.Projectors.Season` in response to
  `Fskick.Seasons.Events.SeasonCreated`. Used for queries and
  cross-aggregate uniqueness checks; not used for user input casting.
  """

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "seasons" do
    field :name, :string
    field :active, :boolean, default: false

    timestamps()
  end
end
