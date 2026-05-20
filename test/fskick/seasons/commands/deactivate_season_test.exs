defmodule Fskick.Seasons.Commands.DeactivateSeasonTest do
  use Fskick.DataCase, async: true

  alias Fskick.Seasons.Commands.DeactivateSeason

  describe "new/1" do
    test "returns a command with valid attrs" do
      id = Ecto.UUID.generate()

      assert {:ok, %DeactivateSeason{season_id: ^id}} =
               DeactivateSeason.new(%{season_id: id})
    end

    test "rejects missing season_id" do
      assert {:error, changeset} = DeactivateSeason.new(%{})
      assert "can't be blank" in errors_on(changeset).season_id
    end
  end
end
