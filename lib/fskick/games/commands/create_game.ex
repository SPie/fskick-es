defmodule Fskick.Games.Commands.CreateGame do
  @moduledoc """
  Command to record a new game.

  A game has two team slots (`team_a`, `team_b`) but one slot may be
  empty — used to record outcomes where only one side is present.
  At least one team must contain a player. When a team is empty the
  populated team cannot be the winner — only outcomes that the empty
  team "wins" or `:draw` are valid:

  - team_b empty: outcome may be `:draw` (everyone played, no winning
    side) or `:team_b_won` (the populated team lost).
  - team_a empty: symmetric — `:draw` or `:team_a_won`.

  Structural validation lives here: presence of all fields, at least
  one player total, no duplicate players within or across teams, a
  valid outcome, and the empty-team outcome constraint. Player and
  season existence is checked at the context layer (read-model
  lookups) before the command is built.
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
    |> validate_at_least_one_player()
    |> validate_outcome_when_team_empty()
    |> validate_no_duplicate_players(:team_a)
    |> validate_no_duplicate_players(:team_b)
    |> validate_no_overlap()
    |> apply_action(:insert)
  end

  defp validate_at_least_one_player(changeset) do
    team_a = get_field(changeset, :team_a) || []
    team_b = get_field(changeset, :team_b) || []

    if team_a == [] and team_b == [] do
      add_error(changeset, :team_a, "at least one team must contain a player")
    else
      changeset
    end
  end

  defp validate_outcome_when_team_empty(changeset) do
    team_a = get_field(changeset, :team_a) || []
    team_b = get_field(changeset, :team_b) || []
    outcome = get_field(changeset, :outcome)

    cond do
      team_a != [] and team_b != [] -> changeset
      team_a == [] and team_b == [] -> changeset
      team_b == [] and outcome == :team_a_won -> empty_team_win_error(changeset)
      team_a == [] and outcome == :team_b_won -> empty_team_win_error(changeset)
      true -> changeset
    end
  end

  defp empty_team_win_error(changeset) do
    add_error(changeset, :outcome, "populated team cannot win without an opponent")
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
