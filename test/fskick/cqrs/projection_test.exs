defmodule Fskick.CQRS.ProjectionTest do
  use Fskick.DataCase, async: true

  alias Fskick.CQRS.Projection
  alias Fskick.Players.Player

  describe "await/3" do
    test "returns {:ok, struct} once the row exists" do
      id = Ecto.UUID.generate()
      Repo.insert!(%Player{id: id, name: "Alice", created_at: DateTime.utc_now()})

      assert {:ok, %Player{id: ^id, name: "Alice"}} = Projection.await(Player, id)
    end

    test "returns the row when it appears before the timeout" do
      id = Ecto.UUID.generate()

      task =
        Task.async(fn ->
          Process.sleep(50)
          Repo.insert!(%Player{id: id, name: "Bob", created_at: DateTime.utc_now()})
        end)

      assert {:ok, %Player{id: ^id}} = Projection.await(Player, id, timeout: 1_000)

      Task.await(task)
    end

    test "returns {:error, :projection_timeout} when the row never appears" do
      assert {:error, :projection_timeout} =
               Projection.await(Player, Ecto.UUID.generate(), timeout: 50)
    end
  end
end
