defmodule Fskick.Players do
  @moduledoc """
  Players context: write side dispatches commands through `Fskick.App`;
  read side queries the `Fskick.Players.Player` projection.
  """

  alias Fskick.App
  alias Fskick.CQRS.Projection
  alias Fskick.Players.Commands.CreatePlayer
  alias Fskick.Players.Player
  alias Fskick.Repo

  @doc """
  Create a new player with the given name.

  Returns `{:ok, %Player{}}` on success, or:
  - `{:error, %Ecto.Changeset{}}` when the name is blank/invalid or already taken
  - `{:error, :projection_timeout}` if the read model does not catch up in time
  - `{:error, reason}` for dispatch failures
  """
  def create_player(name) do
    attrs = %{player_id: Ecto.UUID.generate(), name: name}

    with {:ok, %CreatePlayer{} = command} <- CreatePlayer.new(attrs),
         :ok <- App.dispatch(command) do
      Projection.await(Player, command.player_id)
    end
  end

  def get_player_by_name(name) when is_binary(name) do
    Repo.get_by(Player, name: name)
  end
end
