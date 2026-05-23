defmodule Fskick.Games do
  @moduledoc """
  Games context: write side dispatches `CreateGame` commands through
  `Fskick.App`, then waits for the `PlayerStats` projector to advance
  the singleton `game_counts` row so the read model is consistent on
  return.

  Player names and the season name are resolved against their existing
  read models before the command is built, so the command carries
  UUIDs only.
  """

  import Ecto.Query, only: [from: 2]

  alias Fskick.App
  alias Fskick.CQRS.Projection
  alias Fskick.Games.Commands.CreateGame
  alias Fskick.Games.GameCount
  alias Fskick.Players.Player
  alias Fskick.Repo
  alias Fskick.Seasons

  @doc """
  Record a new game.

  `attrs` is a map with:
  - `:team_a_names` — list of player names (required, non-empty)
  - `:team_b_names` — list of player names (required, non-empty)
  - `:outcome` — `:team_a_won | :team_b_won | :draw` (required)
  - `:played_at` — `DateTime.t()` (optional; defaults to `DateTime.utc_now/0`)
  - `:season_name` — string (optional; defaults to the active season)

  Returns `{:ok, %CreateGame{}}` on success, or:
  - `{:error, :no_active_season}` if `:season_name` is omitted and none is active
  - `{:error, {:season_not_found, name}}` if the named season does not exist
  - `{:error, {:players_not_found, [name, ...]}}` for unknown player names
  - `{:error, %Ecto.Changeset{}}` for structural validation failures
  - `{:error, reason}` for dispatch failures
  """
  def create_game(attrs) when is_map(attrs) do
    before_count = total_games_count()

    with {:ok, season} <- resolve_season(Map.get(attrs, :season_name)),
         {:ok, team_a_ids} <- resolve_players(Map.get(attrs, :team_a_names, [])),
         {:ok, team_b_ids} <- resolve_players(Map.get(attrs, :team_b_names, [])),
         {:ok, %CreateGame{} = command} <-
           CreateGame.new(%{
             game_id: Ecto.UUID.generate(),
             season_id: season.id,
             played_at: Map.get(attrs, :played_at) || DateTime.utc_now(),
             team_a: team_a_ids,
             team_b: team_b_ids,
             outcome: Map.get(attrs, :outcome)
           }),
         :ok <- App.dispatch(command),
         {:ok, _} <-
           Projection.await(GameCount, 1, match: &(&1.total > before_count)) do
      {:ok, command}
    end
  end

  defp resolve_season(nil) do
    case Seasons.get_active_season() do
      nil -> {:error, :no_active_season}
      season -> {:ok, season}
    end
  end

  defp resolve_season(name) when is_binary(name) do
    case Seasons.get_season_by_name(name) do
      nil -> {:error, {:season_not_found, name}}
      season -> {:ok, season}
    end
  end

  defp resolve_players(names) when is_list(names) do
    trimmed =
      names
      |> Enum.map(&trim/1)
      |> Enum.reject(&(&1 == ""))

    found =
      Repo.all(from p in Player, where: p.name in ^trimmed, select: {p.name, p.id})
      |> Map.new()

    case Enum.split_with(trimmed, &Map.has_key?(found, &1)) do
      {_present, []} ->
        {:ok, Enum.map(trimmed, &Map.fetch!(found, &1))}

      {_present, missing} ->
        {:error, {:players_not_found, Enum.uniq(missing)}}
    end
  end

  defp trim(value) when is_binary(value), do: String.trim(value)

  @doc """
  Returns the total number of games recorded across all seasons.

  Reads from the singleton `game_counts` row maintained by
  `Fskick.Games.Projectors.PlayerStats`.
  """
  def total_games_count() do
    case Repo.get(GameCount, 1) do
      nil -> 0
      %GameCount{total: total} -> total
    end
  end
end
