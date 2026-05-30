defmodule Fskick.Repo.Migrations.CreatePlayerResults do
  use Ecto.Migration

  def change() do
    create table(:player_results, primary_key: false) do
      add :player_id, :uuid, primary_key: true
      add :game_id, :uuid, primary_key: true
      add :season_id, :uuid, null: false
      add :played_at, :utc_datetime_usec, null: false
      add :team, :string, null: false
      add :won, :boolean, null: false
    end

    create index(:player_results, [:player_id, :played_at])
    create index(:player_results, [:game_id, :team])
  end
end
