defmodule Fskick.Seasons do
  @moduledoc """
  Seasons context: write side dispatches commands through `Fskick.App`;
  read side queries the `Fskick.Seasons.Season` projection.
  """

  import Ecto.Query, only: [from: 2]

  alias Fskick.App
  alias Fskick.CQRS.Projection
  alias Fskick.Repo
  alias Fskick.Seasons.Commands.CreateSeason
  alias Fskick.Seasons.Season

  @doc """
  Create a new season with the given name.

  Newly created seasons are inactive — activation is a separate command.

  Returns `{:ok, %Season{}}` on success, or:
  - `{:error, %Ecto.Changeset{}}` when the name is blank/invalid or already taken
  - `{:error, :projection_timeout}` if the read model does not catch up in time
  - `{:error, reason}` for dispatch failures
  """
  def create_season(name) do
    attrs = %{season_id: Ecto.UUID.generate(), name: name}

    with {:ok, %CreateSeason{} = command} <- CreateSeason.new(attrs),
         :ok <- App.dispatch(command) do
      Projection.await(Season, command.season_id)
    end
  end

  def get_season_by_name(name) when is_binary(name) do
    Repo.get_by(Season, name: name)
  end

  @doc """
  Return all seasons ordered by creation time (oldest first).
  """
  def list_seasons do
    Repo.all(from s in Season, order_by: [asc: s.inserted_at])
  end
end
