defmodule Fskick.Players do
  @moduledoc """
  Players context: write side dispatches commands through `Fskick.App`;
  read side queries the `Fskick.Players.Player` projection.
  """

  alias Fskick.App
  alias Fskick.Players.Commands.CreatePlayer
  alias Fskick.Players.Player
  alias Fskick.Repo

  @doc """
  Create a new player with the given name.

  Returns `{:ok, %Player{}}` on success, or:
  - `{:error, %Ecto.Changeset{}}` when the name is blank/invalid or already taken
  - `{:error, reason}` for dispatch failures
  """
  @projection_wait_ms 5_000

  def create_player(name) do
    attrs = %{player_id: Ecto.UUID.generate(), name: name}

    with {:ok, %CreatePlayer{} = command} <- CreatePlayer.new(attrs),
         :ok <- App.dispatch(command) do
      await_projection(command.player_id, deadline(@projection_wait_ms))
    end
  end

  defp await_projection(id, deadline) do
    case Repo.get(Player, id) do
      %Player{} = player ->
        {:ok, player}

      nil ->
        if System.monotonic_time(:millisecond) >= deadline do
          {:error, :projection_timeout}
        else
          Process.sleep(25)
          await_projection(id, deadline)
        end
    end
  end

  defp deadline(ms), do: System.monotonic_time(:millisecond) + ms

  def get_player_by_name(name) when is_binary(name) do
    Repo.get_by(Player, name: name)
  end
end
