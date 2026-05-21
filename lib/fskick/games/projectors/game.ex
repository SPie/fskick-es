defmodule Fskick.Games.Projectors.Game do
  @moduledoc """
  Placeholder handler for game events.

  No read model yet — this module exists so its supervised subscription
  loads `Fskick.Games.Events.GameCreated` at boot, putting the event's
  struct field atoms into the VM. Without it, other subscriptions (e.g.
  the players projector or the seasons process manager) crash when they
  catch up past a `GameCreated` row, because the JSON serializer
  deserializes keys with `keys: :atoms!` and `:team_a`/`:team_b` would
  not yet exist.

  When the read model is added, swap `Commanded.Event.Handler` for
  `Commanded.Projections.Ecto` + `project/3` clauses. To make the new
  projector replay every past `GameCreated`, either give it a different
  `name:`, or rebuild it by deleting its `projection_versions` row and
  its event-store subscription before restart.
  """

  use Commanded.Event.Handler,
    application: Fskick.App,
    name: "Fskick.Games.Projectors.Game"

  alias Fskick.Games.Events.GameCreated

  @impl Commanded.Event.Handler
  def handle(%GameCreated{}, _metadata), do: :ok
end
