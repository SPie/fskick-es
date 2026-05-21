defmodule Mix.Tasks.Fskick.Games.New do
  @moduledoc """
  Records a new game between two teams.

      mix fskick.games.new --team-a "Alice,Bob" --team-b "Carol,Dave" --winner a
      mix fskick.games.new --team-a "Alice,Bob" --team-b "Carol,Dave" --draw
      mix fskick.games.new --team-a "Alice" --team-b "Bob" --winner b \
          --played-at 2026-04-01 --season "2026"

  Required flags:
    --team-a   Comma-separated player names for team A
    --team-b   Comma-separated player names for team B

  Exactly one of:
    --winner a|b   Mark team A or team B as the winner
    --draw         Record the game as a draw

  Optional flags:
    --played-at YYYY-MM-DD  Date the game was played (default: now)
    --season "<name>"        Attach to a specific season (default: active season)
  """

  use Mix.Task

  alias Fskick.Games

  @shortdoc ~s|Records a new game: mix fskick.games.new --team-a "..." --team-b "..." --winner a|

  @strict [
    team_a: :string,
    team_b: :string,
    winner: :string,
    draw: :boolean,
    played_at: :string,
    season: :string
  ]

  @impl Mix.Task
  def run(argv) do
    Mix.Task.run("app.start")

    {opts, _rest, invalid} = OptionParser.parse(argv, strict: @strict)

    if invalid != [] do
      Mix.raise("Unknown or malformed flags: #{inspect(invalid)}\n\n#{usage()}")
    end

    with {:ok, team_a_names} <- require_team(opts, :team_a),
         {:ok, team_b_names} <- require_team(opts, :team_b),
         {:ok, outcome} <- resolve_outcome(opts),
         {:ok, played_at} <- parse_played_at(opts[:played_at]) do
      attrs = %{
        team_a_names: team_a_names,
        team_b_names: team_b_names,
        outcome: outcome,
        played_at: played_at,
        season_name: opts[:season]
      }

      handle_result(Games.create_game(attrs))
    else
      {:error, message} -> Mix.raise(message <> "\n\n" <> usage())
    end
  end

  defp require_team(opts, key) do
    case Keyword.get(opts, key) do
      nil -> {:error, "Missing required flag --#{String.replace(Atom.to_string(key), "_", "-")}"}
      raw -> {:ok, parse_names(raw)}
    end
  end

  defp parse_names(raw) do
    raw
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp resolve_outcome(opts) do
    case {Keyword.get(opts, :winner), Keyword.get(opts, :draw)} do
      {nil, true} ->
        {:ok, :draw}

      {"a", nil} ->
        {:ok, :team_a_won}

      {"b", nil} ->
        {:ok, :team_b_won}

      {nil, nil} ->
        {:error, "Must specify either --winner a|b or --draw"}

      {_, true} ->
        {:error, "--winner and --draw are mutually exclusive"}

      {other, nil} ->
        {:error, "--winner must be 'a' or 'b' (got: #{inspect(other)})"}
    end
  end

  defp parse_played_at(nil), do: {:ok, DateTime.utc_now()}

  defp parse_played_at(raw) do
    with {:ok, date} <- Date.from_iso8601(raw),
         {:ok, datetime} <- DateTime.new(date, ~T[00:00:00.000000], "Etc/UTC") do
      {:ok, datetime}
    else
      _ -> {:error, "Invalid --played-at #{inspect(raw)}; expected YYYY-MM-DD"}
    end
  end

  defp handle_result({:ok, command}) do
    Mix.shell().info("Game created: #{command.game_id} (#{command.outcome})")
  end

  defp handle_result({:error, :no_active_season}) do
    Mix.raise(
      ~s|No active season. Activate one with "mix fskick.seasons.activate", or pass --season "<name>".|
    )
  end

  defp handle_result({:error, {:season_not_found, name}}) do
    Mix.raise("Season with name #{inspect(name)} does not exist")
  end

  defp handle_result({:error, {:players_not_found, names}}) do
    Mix.raise("Unknown players: #{Enum.join(names, ", ")}")
  end

  defp handle_result({:error, %Ecto.Changeset{} = changeset}) do
    Mix.raise("Invalid input: #{format_errors(changeset)}")
  end

  defp handle_result({:error, reason}) do
    Mix.raise("Failed to create game: #{inspect(reason)}")
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc ->
        String.replace(acc, "%{#{k}}", to_string(v))
      end)
    end)
    |> inspect()
  end

  defp usage() do
    "Usage: mix fskick.games.new --team-a \"A,B\" --team-b \"C,D\" (--winner a|b | --draw) [--played-at YYYY-MM-DD] [--season \"<name>\"]"
  end
end
