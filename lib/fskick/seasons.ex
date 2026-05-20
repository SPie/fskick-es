defmodule Fskick.Seasons do
  @moduledoc """
  Seasons context: write side dispatches commands through `Fskick.App`;
  read side queries the `Fskick.Seasons.Season` projection.
  """

  import Ecto.Query, only: [from: 2]

  alias Fskick.App
  alias Fskick.CQRS.Projection
  alias Fskick.Repo
  alias Fskick.Seasons.Commands.ActivateSeason
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

  @doc """
  Activate the season with the given name.

  Any other currently-active season is deactivated by the
  `Fskick.Seasons.ProcessManagers.SoleActiveSeason` process manager.
  Activating an already-active season is a silent no-op success.

  Returns `{:ok, %Season{}}` on success, or:
  - `{:error, :not_found}` if no season exists with that name
  - `{:error, :projection_timeout}` if the read model does not catch up in time
  - `{:error, reason}` for dispatch failures
  """
  def activate_season(name) when is_binary(name) do
    case get_season_by_name(name) do
      nil ->
        {:error, :not_found}

      %Season{active: true} = season ->
        {:ok, season}

      %Season{} = target ->
        previous = get_active_season()

        with {:ok, %ActivateSeason{} = command} <- ActivateSeason.new(%{season_id: target.id}),
             :ok <- App.dispatch(command),
             :ok <- await_deactivation(previous) do
          Projection.await(Season, target.id, match: & &1.active)
        end
    end
  end

  def get_season_by_name(name) when is_binary(name) do
    Repo.get_by(Season, name: name)
  end

  @doc """
  Return the currently-active season, or `nil` if none is active.
  """
  def get_active_season() do
    Repo.get_by(Season, active: true)
  end

  @doc """
  Return all seasons ordered by creation time (oldest first).
  """
  def list_seasons() do
    Repo.all(from s in Season, order_by: [asc: s.inserted_at])
  end

  defp await_deactivation(nil), do: :ok

  defp await_deactivation(%Season{id: id}) do
    case Projection.await(Season, id, match: &(not &1.active)) do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
