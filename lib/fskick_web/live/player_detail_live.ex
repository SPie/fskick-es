defmodule FskickWeb.PlayerDetailLive do
  use FskickWeb, :live_view
  import FskickWeb.Components.PlayerStatsTable

  alias Fskick.Games
  alias Fskick.Players

  @allowed_sorts ~w(points wins games win_ratio)

  def mount(%{"id" => id}, _session, socket) do
    case Players.get_player(id) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Player not found")
         |> push_navigate(to: ~p"/players")}

      player ->
        {:ok,
         socket
         |> assign(player: player, sort: :points)
         |> load_stats()}
    end
  end

  def handle_event("sort", %{"sort" => key}, socket) when key in @allowed_sorts do
    {:noreply,
     socket
     |> assign(:sort, String.to_existing_atom(key))
     |> load_stats()}
  end

  defp load_stats(socket) do
    player = socket.assigns.player

    stats =
      [sort: socket.assigns.sort]
      |> Players.list_player_stats()
      |> Enum.filter(&(&1.player_id == player.id))

    assign(socket, stats: stats, games_count: Games.total_games_count())
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h2 class="text-center text-md md:text-2xl font-bold">{@player.name}</h2>

      <div class="mx-auto w-4/5">
        <div class="my-5">
          <h3 class="text-left text-sm md:text-xl font-bold">Stats</h3>

          <div>
            <.player_stats_table stats={@stats} games_count={@games_count} sort={@sort} />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
