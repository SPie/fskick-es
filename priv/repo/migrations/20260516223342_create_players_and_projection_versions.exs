defmodule Fskick.Repo.Migrations.CreatePlayersAndProjectionVersions do
  use Ecto.Migration

  def change do
    create table(:players, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:players, [:name])

    create table(:projection_versions, primary_key: false) do
      add :projection_name, :text, primary_key: true
      add :last_seen_event_number, :bigint

      timestamps(type: :naive_datetime_usec)
    end
  end
end
