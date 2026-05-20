defmodule Fskick.Seasons.Commands.ActivateSeason do
  @moduledoc """
  Command to activate a season.

  Structural validation lives here: presence of `season_id`.
  State-dependent invariants (`:not_found`, `:already_active`) live in
  the aggregate.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :season_id, :binary_id
  end

  @doc """
  Build a validated `%ActivateSeason{}` from raw attrs.

  Returns `{:ok, command}` or `{:error, changeset}`.
  """
  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:season_id])
    |> validate_required([:season_id])
    |> apply_action(:insert)
  end
end
