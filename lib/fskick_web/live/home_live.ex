defmodule FskickWeb.HomeLive do
  use FskickWeb, :live_view

  alias Fskick.Games
  alias Fskick.Players
  alias Fskick.Seasons

  @allowed_sorts ~w(points wins games win_ratio)

  def mount(_params, _session, socket) do
    seasons = Seasons.list_seasons()
    active_season = Seasons.get_active_season() || List.first(seasons)

    {:ok,
     socket
     |> assign(seasons: seasons, active_season: active_season, sort: :points)
     |> load_stats()}
  end

  def handle_event("change_season", %{"season" => uuid}, socket) do
    case Enum.find(socket.assigns.seasons, &(&1.id == uuid)) do
      nil -> {:noreply, socket}
      season -> {:noreply, socket |> assign(:active_season, season) |> load_stats()}
    end
  end

  def handle_event("sort", %{"sort" => key}, socket) when key in @allowed_sorts do
    {:noreply,
     socket
     |> assign(:sort, String.to_existing_atom(key))
     |> load_stats()}
  end

  defp load_stats(socket) do
    case socket.assigns.active_season do
      nil ->
        assign(socket, stats: [], games_count: 0)

      season ->
        stats = Players.list_player_stats(season_id: season.id, sort: socket.assigns.sort)
        assign(socket, stats: stats, games_count: Games.season_game_count(season.id))
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h2 class="text-center text-md md:text-2xl font-bold">
        Season
        <form :if={@seasons != []} class="inline" phx-change="change_season">
          <select name="season" class="bg-gray-900">
            <option
              :for={s <- @seasons}
              value={s.id}
              selected={@active_season && s.id == @active_season.id}
            >
              {s.name}
            </option>
          </select>
        </form>
      </h2>

      <div>
        <table class="mx-auto text-xs md:text-base table-fixed">
          <thead>
            <tr>
              <th class="border-b border-gray-500 text-left px-1 md:px-6 py-4">Pos ({length(@stats)})</th>
              <th class="border-b border-gray-500 text-left px-1 md:px-6 py-4">Player</th>
              <.sort_header sort={@sort} key={:points} label="Points" />
              <.sort_header sort={@sort} key={:wins} label="Wins" />
              <.sort_header sort={@sort} key={:games} label={"Games (#{@games_count})"} />
              <.sort_header sort={@sort} key={:win_ratio} label="Win Ratio" />
            </tr>
          </thead>
          <tbody>
            <tr :for={stat <- @stats}>
              <td class="border-b border-gray-500 text-left px-1 md:px-6 py-3">{stat.position}</td>
              <td class="border-b border-gray-500 text-left px-1 md:px-6 py-3 underline">
                <.link navigate={"/players/" <> stat.player_id}>{stat.name}</.link>
              </td>
              <td class="border-b border-gray-500 text-left px-1 md:px-6 py-3">{format_float(stat.points)}</td>
              <td class="border-b border-gray-500 text-left px-1 md:px-6 py-3">{stat.wins}</td>
              <td class="border-b border-gray-500 text-left px-1 md:px-6 py-3">
                {stat.games} ({format_float(stat.games_ratio)} %)
              </td>
              <td class="border-b border-gray-500 text-left px-1 md:px-6 py-3">{format_float(stat.win_ratio)} %</td>
            </tr>
          </tbody>
        </table>
      </div>
    </Layouts.app>
    """
  end

  attr :sort, :atom, required: true
  attr :key, :atom, required: true
  attr :label, :string, required: true

  defp sort_header(assigns) do
    ~H"""
    <th
      class={["border-b border-gray-500 text-left px-1 md:px-6 py-4 cursor-pointer", @sort == @key && "underline"]}
      phx-click="sort"
      phx-value-sort={Atom.to_string(@key)}
    >
      {@label}
    </th>
    """
  end

  defp format_float(value) when is_float(value) do
    :erlang.float_to_binary(value, decimals: 2)
  end

  defp format_float(value) when is_integer(value) do
    :erlang.float_to_binary(value * 1.0, decimals: 2)
  end
end
