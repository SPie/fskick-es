defmodule Fskick.Repo.Migrations.ConsolidatePlayerStatsPerSeason do
  use Ecto.Migration

  def change() do
    drop table(:player_stats)
    drop table(:game_counts)

    create table(:player_stats, primary_key: false) do
      add :season_id, :uuid, primary_key: true
      add :player_id, :uuid, primary_key: true
      add :wins, :integer, null: false, default: 0
      add :games, :integer, null: false, default: 0
    end

    create table(:game_counts, primary_key: false) do
      add :season_id, :uuid, primary_key: true
      add :total, :integer, null: false, default: 0
    end
  end
end
