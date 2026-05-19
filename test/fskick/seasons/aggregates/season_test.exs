defmodule Fskick.Seasons.Aggregates.SeasonTest do
  use ExUnit.Case, async: true

  alias Fskick.Seasons.Aggregates.Season
  alias Fskick.Seasons.Commands.CreateSeason
  alias Fskick.Seasons.Events.SeasonCreated

  describe "execute/2" do
    test "emits SeasonCreated with active: false when aggregate is uninitialised" do
      id = Ecto.UUID.generate()
      cmd = %CreateSeason{season_id: id, name: "2026"}

      assert %SeasonCreated{season_id: ^id, name: "2026", active: false} =
               Season.execute(%Season{}, cmd)
    end

    test "rejects when the season has already been created" do
      state = %Season{season_id: Ecto.UUID.generate(), name: "2026", active: false}
      cmd = %CreateSeason{season_id: Ecto.UUID.generate(), name: "2027"}

      assert {:error, :already_created} = Season.execute(state, cmd)
    end
  end

  describe "apply/2" do
    test "SeasonCreated sets id, name and active on the aggregate" do
      id = Ecto.UUID.generate()
      event = %SeasonCreated{season_id: id, name: "2026", active: false}

      assert %Season{season_id: ^id, name: "2026", active: false} =
               Season.apply(%Season{}, event)
    end
  end
end
