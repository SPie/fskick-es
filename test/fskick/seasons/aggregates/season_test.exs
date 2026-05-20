defmodule Fskick.Seasons.Aggregates.SeasonTest do
  use ExUnit.Case, async: true

  alias Fskick.Seasons.Aggregates.Season
  alias Fskick.Seasons.Commands.ActivateSeason
  alias Fskick.Seasons.Commands.CreateSeason
  alias Fskick.Seasons.Commands.DeactivateSeason
  alias Fskick.Seasons.Events.SeasonActivated
  alias Fskick.Seasons.Events.SeasonCreated
  alias Fskick.Seasons.Events.SeasonDeactivated

  describe "execute/2 with CreateSeason" do
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

  describe "execute/2 with ActivateSeason" do
    test "emits SeasonActivated when the season exists and is inactive" do
      id = Ecto.UUID.generate()
      state = %Season{season_id: id, name: "2026", active: false}

      assert %SeasonActivated{season_id: ^id} =
               Season.execute(state, %ActivateSeason{season_id: id})
    end

    test "rejects when the aggregate has not been created" do
      cmd = %ActivateSeason{season_id: Ecto.UUID.generate()}

      assert {:error, :not_found} = Season.execute(%Season{}, cmd)
    end

    test "rejects when the season is already active" do
      id = Ecto.UUID.generate()
      state = %Season{season_id: id, name: "2026", active: true}

      assert {:error, :already_active} =
               Season.execute(state, %ActivateSeason{season_id: id})
    end
  end

  describe "execute/2 with DeactivateSeason" do
    test "emits SeasonDeactivated when the season is active" do
      id = Ecto.UUID.generate()
      state = %Season{season_id: id, name: "2026", active: true}

      assert %SeasonDeactivated{season_id: ^id} =
               Season.execute(state, %DeactivateSeason{season_id: id})
    end

    test "rejects when the aggregate has not been created" do
      cmd = %DeactivateSeason{season_id: Ecto.UUID.generate()}

      assert {:error, :not_found} = Season.execute(%Season{}, cmd)
    end

    test "rejects when the season is already inactive" do
      id = Ecto.UUID.generate()
      state = %Season{season_id: id, name: "2026", active: false}

      assert {:error, :already_inactive} =
               Season.execute(state, %DeactivateSeason{season_id: id})
    end
  end

  describe "apply/2" do
    test "SeasonCreated sets id, name and active on the aggregate" do
      id = Ecto.UUID.generate()
      event = %SeasonCreated{season_id: id, name: "2026", active: false}

      assert %Season{season_id: ^id, name: "2026", active: false} =
               Season.apply(%Season{}, event)
    end

    test "SeasonActivated flips active to true" do
      id = Ecto.UUID.generate()
      state = %Season{season_id: id, name: "2026", active: false}

      assert %Season{active: true} = Season.apply(state, %SeasonActivated{season_id: id})
    end

    test "SeasonDeactivated flips active to false" do
      id = Ecto.UUID.generate()
      state = %Season{season_id: id, name: "2026", active: true}

      assert %Season{active: false} = Season.apply(state, %SeasonDeactivated{season_id: id})
    end
  end
end
