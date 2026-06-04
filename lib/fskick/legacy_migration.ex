defmodule Fskick.LegacyMigration do
  @moduledoc """
  One-shot importer from the old Go app's SQLite database into the
  event-sourced store.

  Reads `seasons`, `players`, `games`, and `attendances` rows from the
  supplied SQLite file and emits the matching commands:

  - `CreateSeason` per row, followed by a single `ActivateSeason` for the
    `active = 1` row.
  - `CreatePlayer` per row.
  - `CreateGame` per row, with team membership reconstructed from
    `attendances.win`:
    - Mixed wins and losses → winners on `team_a`, losers on
      `team_b`, outcome `:team_a_won`.
    - Every attendance has `win = true` → a single-team game, every
      player on `team_a`, `team_b` empty, outcome `:draw`.
    - Every attendance has `win = false` → a single-team game, every
      player on `team_a`, `team_b` empty, outcome `:team_b_won`
      (the populated team lost; the absent team "won").
    - Exactly one attendance falls into the appropriate single-team
      branch based on its `win` flag, so single-player rows are
      imported rather than dropped.

  Original UUIDs are preserved verbatim, so cross-table references survive
  the migration.

  Idempotent: each step checks the read model (`Repo.get` for seasons /
  players; `PlayerResult.game_id` for games) and skips already-imported
  rows. `{:error, :already_created}` from a command dispatch is also
  treated as "already imported" to handle the race between projectors
  during a quick re-run.
  """

  import Ecto.Query, only: [from: 2]

  alias Exqlite.Sqlite3
  alias Fskick.App
  alias Fskick.CQRS.Projection
  alias Fskick.Games
  alias Fskick.Games.Commands.CreateGame
  alias Fskick.Games.GameCount
  alias Fskick.Games.PlayerResult
  alias Fskick.Players.Commands.CreatePlayer
  alias Fskick.Players.Player
  alias Fskick.Repo
  alias Fskick.Seasons.Commands.ActivateSeason
  alias Fskick.Seasons.Commands.CreateSeason
  alias Fskick.Seasons.Season

  @doc """
  Run the full migration. Returns `:ok` on success or `{:error, reason}`
  on the first failure (no partial-rollback is attempted — the event
  store contains exactly the events that were successfully dispatched
  before the failure, and re-running the task will pick up where it left
  off).
  """
  def migrate_all(db_path) when is_binary(db_path) do
    with {:ok, conn} <- open(db_path),
         :ok <- migrate_seasons(conn),
         :ok <- migrate_players(conn),
         :ok <- migrate_games(conn) do
      Sqlite3.close(conn)
      :ok
    end
  end

  defp open(db_path) do
    case Sqlite3.open(db_path) do
      {:ok, conn} -> {:ok, conn}
      {:error, reason} -> {:error, {:sqlite_open_failed, db_path, reason}}
    end
  end

  @doc false
  def migrate_seasons(conn) do
    rows =
      query_all(
        conn,
        ~s|SELECT uuid, name, active FROM seasons WHERE deleted_at IS NULL ORDER BY created_at, id|
      )

    {imported, skipped, error} =
      Enum.reduce_while(rows, {0, 0, nil}, fn [uuid, name, active], {i, s, _err} ->
        case create_season_if_missing(uuid, name) do
          :imported -> {:cont, {i + 1, s, nil}}
          :skipped -> {:cont, {i, s + 1, nil}}
          {:error, reason} -> {:halt, {i, s, {uuid, name, active, reason}}}
        end
      end)

    case error do
      nil ->
        info("Seasons: imported #{imported}, skipped #{skipped}")
        activate_active_season(rows)

      {uuid, name, _active, reason} ->
        {:error, {:season_failed, uuid, name, reason}}
    end
  end

  defp create_season_if_missing(uuid, name) do
    case Repo.get(Season, uuid) do
      %Season{} ->
        :skipped

      nil ->
        with {:ok, command} <- CreateSeason.new(%{season_id: uuid, name: name}),
             :ok <- dispatch_or_existing(command),
             {:ok, _row} <- Projection.await(Season, uuid) do
          :imported
        end
    end
  end

  defp activate_active_season(rows) do
    case Enum.find(rows, fn [_uuid, _name, active] -> truthy?(active) end) do
      nil ->
        :ok

      [uuid, name, _active] ->
        case Repo.get(Season, uuid) do
          %Season{active: true} ->
            :ok

          %Season{} ->
            with {:ok, command} <- ActivateSeason.new(%{season_id: uuid}),
                 :ok <- dispatch_or_existing(command),
                 {:ok, _row} <- Projection.await(Season, uuid, match: & &1.active) do
              info("Activated season #{name}")
              :ok
            else
              {:error, reason} -> {:error, {:season_activate_failed, uuid, name, reason}}
            end

          nil ->
            {:error, {:season_activate_failed, uuid, name, :missing_in_read_model}}
        end
    end
  end

  @doc false
  def migrate_players(conn) do
    rows =
      query_all(
        conn,
        ~s|SELECT uuid, name FROM players WHERE deleted_at IS NULL ORDER BY created_at, id|
      )

    {imported, skipped, error} =
      Enum.reduce_while(rows, {0, 0, nil}, fn [uuid, name], {i, s, _err} ->
        case create_player_if_missing(uuid, name) do
          :imported -> {:cont, {i + 1, s, nil}}
          :skipped -> {:cont, {i, s + 1, nil}}
          {:error, reason} -> {:halt, {i, s, {uuid, name, reason}}}
        end
      end)

    case error do
      nil ->
        info("Players: imported #{imported}, skipped #{skipped}")
        :ok

      {uuid, name, reason} ->
        {:error, {:player_failed, uuid, name, reason}}
    end
  end

  defp create_player_if_missing(uuid, name) do
    case Repo.get(Player, uuid) do
      %Player{} ->
        :skipped

      nil ->
        with {:ok, command} <- CreatePlayer.new(%{player_id: uuid, name: name}),
             :ok <- dispatch_or_existing(command),
             {:ok, _row} <- Projection.await(Player, uuid) do
          :imported
        end
    end
  end

  @doc false
  def migrate_games(conn) do
    rows =
      query_all(conn, ~s"""
        SELECT g.uuid, g.played_at, s.uuid, p.uuid, a.win
        FROM games g
        JOIN attendances a ON a.game_id = g.id AND a.deleted_at IS NULL
        JOIN players p ON p.id = a.player_id AND p.deleted_at IS NULL
        JOIN seasons s ON s.id = g.season_id
        WHERE g.deleted_at IS NULL
        ORDER BY g.played_at, g.id, p.uuid
      """)

    games = group_game_rows(rows)

    {imported, skipped, error} =
      Enum.reduce_while(games, {0, 0, nil}, fn game, {i, s, _err} ->
        case create_game_if_missing(game) do
          :imported -> {:cont, {i + 1, s, nil}}
          :skipped -> {:cont, {i, s + 1, nil}}
          {:error, reason} -> {:halt, {i, s, {game, reason}}}
        end
      end)

    case error do
      nil ->
        info("Games: imported #{imported}, skipped #{skipped}")
        :ok

      {game, reason} ->
        {:error, {:game_failed, game.game_uuid, reason}}
    end
  end

  defp group_game_rows(rows) do
    rows
    |> Enum.group_by(fn [game_uuid | _] -> game_uuid end)
    |> Enum.map(fn {game_uuid, group} ->
      [[_, played_at, season_uuid | _] | _] = group

      attendances =
        Enum.map(group, fn [_, _, _, player_uuid, win] ->
          %{uuid: player_uuid, win: truthy?(win)}
        end)

      %{
        game_uuid: game_uuid,
        played_at: played_at,
        season_uuid: season_uuid,
        attendances: attendances
      }
    end)
    |> Enum.sort_by(& &1.played_at)
  end

  defp create_game_if_missing(%{game_uuid: game_uuid} = game) do
    if game_exists?(game_uuid) do
      :skipped
    else
      case build_teams(game.attendances) do
        {:error, reason} ->
          info("Skipping game #{game_uuid}: #{reason}")
          :skipped

        {:ok, {team_a, team_b, outcome}} ->
          dispatch_game(game, team_a, team_b, outcome)
      end
    end
  end

  defp dispatch_game(%{game_uuid: game_uuid} = game, team_a, team_b, outcome) do
    played_at = parse_datetime(game.played_at)
    before_count = Games.season_game_count(game.season_uuid)

    attrs = %{
      game_id: game_uuid,
      season_id: game.season_uuid,
      played_at: played_at,
      team_a: team_a,
      team_b: team_b,
      outcome: outcome
    }

    with {:ok, command} <- CreateGame.new(attrs),
         :ok <- dispatch_or_existing(command),
         {:ok, _row} <-
           Projection.await(GameCount, game.season_uuid, match: &(&1.total > before_count)) do
      :imported
    end
  end

  defp game_exists?(game_uuid) do
    Repo.exists?(from r in PlayerResult, where: r.game_id == ^game_uuid)
  end

  @doc """
  Pure: derive `{team_a, team_b, outcome}` from the per-player win flags
  for one game.

  - Mixed wins and losses → winners on `team_a`, losers on `team_b`,
    `outcome: :team_a_won`.
  - All `win = true` → a single-team game: every player on `team_a`,
    `team_b` empty, `outcome: :draw`.
  - All `win = false` → a single-team game: every player on `team_a`,
    `team_b` empty, `outcome: :team_b_won`. The populated team lost;
    the absent team is recorded as the winner.
  - A single attendance is handled by the same rule based on its win
    flag, so single-player games are imported rather than dropped.
  - Zero attendances → `{:error, :no_attendances}`. Defensive; the
    SQL query's inner joins make this unreachable in practice.

  Returns `{:ok, {team_a, team_b, outcome}}` or `{:error, reason}`.
  """
  @spec build_teams([%{uuid: binary(), win: boolean()}]) ::
          {:ok, {[binary()], [binary()], :team_a_won | :team_b_won | :draw}}
          | {:error, atom()}
  def build_teams([]), do: {:error, :no_attendances}

  def build_teams(attendances) when is_list(attendances) do
    {winners, losers} = Enum.split_with(attendances, & &1.win)

    cond do
      losers == [] ->
        {:ok, {Enum.map(attendances, & &1.uuid), [], :draw}}

      winners == [] ->
        {:ok, {Enum.map(attendances, & &1.uuid), [], :team_b_won}}

      true ->
        {:ok, {Enum.map(winners, & &1.uuid), Enum.map(losers, & &1.uuid), :team_a_won}}
    end
  end

  @doc """
  Parse the legacy SQLite `played_at` text into a `DateTime`. SQLite
  stores it as `"YYYY-MM-DD HH:MM:SS"` (optionally with fractional
  seconds and a trailing `Z`).
  """
  def parse_datetime(value) when is_binary(value) do
    normalized =
      value
      |> String.replace(" ", "T", global: false)
      |> ensure_z()

    case DateTime.from_iso8601(normalized) do
      {:ok, dt, _offset} -> dt
      {:error, _} -> raise ArgumentError, "could not parse datetime: #{inspect(value)}"
    end
  end

  defp ensure_z(s) do
    if String.ends_with?(s, "Z") or
         Regex.match?(~r/[+-]\d{2}:?\d{2}$/, s) do
      s
    else
      s <> "Z"
    end
  end

  defp dispatch_or_existing(command) do
    case App.dispatch(command) do
      :ok -> :ok
      {:error, :already_created} -> :ok
      {:error, :already_active} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp query_all(conn, sql) do
    {:ok, stmt} = Sqlite3.prepare(conn, sql)

    try do
      {:ok, rows} = Sqlite3.fetch_all(conn, stmt)
      rows
    after
      Sqlite3.release(conn, stmt)
    end
  end

  defp truthy?(1), do: true
  defp truthy?(true), do: true
  defp truthy?(_), do: false

  defp info(message) do
    if function_exported?(Mix, :shell, 0) do
      Mix.shell().info(message)
    end

    :ok
  end
end
