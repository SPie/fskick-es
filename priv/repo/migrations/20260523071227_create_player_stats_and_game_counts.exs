defmodule Fskick.Repo.Migrations.CreatePlayerStatsAndGameCounts do
  use Ecto.Migration

  def change do
    create table(:player_stats, primary_key: false) do
      add :player_id, :uuid, primary_key: true
      add :wins, :integer, null: false, default: 0
      add :games, :integer, null: false, default: 0
    end

    create table(:game_counts, primary_key: false) do
      add :id, :integer, primary_key: true
      add :total, :integer, null: false, default: 0
    end

    execute(
      "INSERT INTO game_counts (id, total) VALUES (1, 0)",
      "DELETE FROM game_counts WHERE id = 1"
    )
  end
end
