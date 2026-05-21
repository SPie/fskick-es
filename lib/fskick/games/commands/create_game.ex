defmodule Fskick.Games.Commands.CreateGame do
  @moduledoc """
  Command to record a new game between two teams.

  Structural validation lives here: presence of all fields, non-empty
  teams, no duplicate players within or across teams, and a valid
  outcome. Player and season existence is checked at the context
  layer (read-model lookups) before the command is built.
  """

  use Ecto.Schema

  import Ecto.Changeset

  @outcomes [:team_a_won, :team_b_won, :draw]

  @primary_key false
  embedded_schema do
    field :game_id, :binary_id
    field :season_id, :binary_id
    field :played_at, :utc_datetime_usec
    field :team_a, {:array, :binary_id}
    field :team_b, {:array, :binary_id}
    field :outcome, Ecto.Enum, values: @outcomes
  end

  @doc """
  Build a validated `%CreateGame{}` from raw attrs.

  Returns `{:ok, command}` or `{:error, changeset}`.
  """
  def new(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:game_id, :season_id, :played_at, :team_a, :team_b, :outcome])
    |> validate_required([:game_id, :season_id, :played_at, :team_a, :team_b, :outcome])
    |> validate_team_non_empty(:team_a)
    |> validate_team_non_empty(:team_b)
    |> validate_no_duplicate_players(:team_a)
    |> validate_no_duplicate_players(:team_b)
    |> validate_no_overlap()
    |> apply_action(:insert)
  end

  defp validate_team_non_empty(changeset, field) do
    case get_field(changeset, field) do
      list when is_list(list) and list != [] -> changeset
      _ -> add_error(changeset, field, "must contain at least one player")
    end
  end

  defp validate_no_duplicate_players(changeset, field) do
    case get_field(changeset, field) do
      list when is_list(list) ->
        if length(Enum.uniq(list)) == length(list) do
          changeset
        else
          add_error(changeset, field, "contains duplicate players")
        end

      _ ->
        changeset
    end
  end

  defp validate_no_overlap(changeset) do
    team_a = get_field(changeset, :team_a) || []
    team_b = get_field(changeset, :team_b) || []

    case MapSet.intersection(MapSet.new(team_a), MapSet.new(team_b)) |> MapSet.to_list() do
      [] ->
        changeset

      _overlap ->
        add_error(changeset, :team_b, "shares players with team_a")
    end
  end
end
