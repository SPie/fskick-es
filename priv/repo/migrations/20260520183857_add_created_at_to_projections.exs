defmodule Fskick.Repo.Migrations.AddCreatedAtToProjections do
  use Ecto.Migration

  def up do
    alter table(:players) do
      add :created_at, :utc_datetime_usec
    end

    alter table(:seasons) do
      add :created_at, :utc_datetime_usec
    end

    execute "UPDATE players SET created_at = inserted_at AT TIME ZONE 'UTC'"
    execute "UPDATE seasons SET created_at = inserted_at AT TIME ZONE 'UTC'"

    alter table(:players) do
      modify :created_at, :utc_datetime_usec, null: false
    end

    alter table(:seasons) do
      modify :created_at, :utc_datetime_usec, null: false
    end
  end

  def down do
    alter table(:players) do
      remove :created_at
    end

    alter table(:seasons) do
      remove :created_at
    end
  end
end
