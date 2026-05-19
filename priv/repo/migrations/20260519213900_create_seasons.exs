defmodule Fskick.Repo.Migrations.CreateSeasons do
  use Ecto.Migration

  def change do
    create table(:seasons, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false
      add :active, :boolean, null: false, default: false

      timestamps()
    end

    create unique_index(:seasons, [:name])
  end
end
