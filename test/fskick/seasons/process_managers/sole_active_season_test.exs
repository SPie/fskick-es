defmodule Fskick.Seasons.ProcessManagers.SoleActiveSeasonTest do
  use ExUnit.Case, async: true

  alias Fskick.Seasons.Commands.DeactivateSeason
  alias Fskick.Seasons.Events.SeasonActivated
  alias Fskick.Seasons.Events.SeasonDeactivated
  alias Fskick.Seasons.ProcessManagers.SoleActiveSeason

  describe "handle/2 SeasonActivated" do
    test "no previous active season — emits no command" do
      assert [] =
               SoleActiveSeason.handle(
                 %SoleActiveSeason{active_season_id: nil},
                 %SeasonActivated{season_id: Ecto.UUID.generate()}
               )
    end

    test "same season activated again — emits no command" do
      id = Ecto.UUID.generate()

      assert [] =
               SoleActiveSeason.handle(
                 %SoleActiveSeason{active_season_id: id},
                 %SeasonActivated{season_id: id}
               )
    end

    test "different season was active — dispatches DeactivateSeason for the previous" do
      prev_id = Ecto.UUID.generate()
      new_id = Ecto.UUID.generate()

      assert %DeactivateSeason{season_id: ^prev_id} =
               SoleActiveSeason.handle(
                 %SoleActiveSeason{active_season_id: prev_id},
                 %SeasonActivated{season_id: new_id}
               )
    end
  end

  describe "apply/2" do
    test "SeasonActivated sets active_season_id" do
      id = Ecto.UUID.generate()

      assert %SoleActiveSeason{active_season_id: ^id} =
               SoleActiveSeason.apply(
                 %SoleActiveSeason{active_season_id: nil},
                 %SeasonActivated{season_id: id}
               )
    end

    test "SeasonActivated overwrites previous active_season_id" do
      prev = Ecto.UUID.generate()
      new = Ecto.UUID.generate()

      assert %SoleActiveSeason{active_season_id: ^new} =
               SoleActiveSeason.apply(
                 %SoleActiveSeason{active_season_id: prev},
                 %SeasonActivated{season_id: new}
               )
    end

    test "SeasonDeactivated clears active_season_id when it matches" do
      id = Ecto.UUID.generate()

      assert %SoleActiveSeason{active_season_id: nil} =
               SoleActiveSeason.apply(
                 %SoleActiveSeason{active_season_id: id},
                 %SeasonDeactivated{season_id: id}
               )
    end

    test "SeasonDeactivated for a different season is a no-op" do
      tracked = Ecto.UUID.generate()
      other = Ecto.UUID.generate()

      assert %SoleActiveSeason{active_season_id: ^tracked} =
               SoleActiveSeason.apply(
                 %SoleActiveSeason{active_season_id: tracked},
                 %SeasonDeactivated{season_id: other}
               )
    end
  end
end
