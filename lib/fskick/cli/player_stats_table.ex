defmodule Fskick.CLI.PlayerStatsTable do
  @moduledoc """
  Renders a list of `%Fskick.Players.PlayerStat{}` rows as a TableRex CLI
  table. Shared by `mix fskick.players.get` and `mix fskick.seasons.table`
  so both tasks present the same column layout.
  """

  def render(stats, total_games) do
    headers = [
      "Position (#{length(stats)})",
      "Name",
      "Points",
      "Wins",
      "Games (#{total_games})"
    ]

    rows =
      for stat <- stats do
        [
          Integer.to_string(stat.position),
          stat.name,
          format_float(stat.points),
          "#{Integer.to_string(stat.wins)} (#{format_float(stat.win_ratio)}%)",
          "#{Integer.to_string(stat.games)} (#{format_float(stat.games_ratio)}%)"
        ]
      end

    rows
    |> TableRex.Table.new(headers)
    |> TableRex.Table.render!()
  end

  defp format_float(value) when is_float(value) do
    :erlang.float_to_binary(value, decimals: 2)
  end

  defp format_float(value) when is_integer(value) do
    :erlang.float_to_binary(value * 1.0, decimals: 2)
  end
end
