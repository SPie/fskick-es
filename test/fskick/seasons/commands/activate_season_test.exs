defmodule Fskick.Seasons.Commands.ActivateSeasonTest do
  use Fskick.DataCase, async: true

  alias Fskick.Seasons.Commands.ActivateSeason

  describe "new/1" do
    test "returns a command with valid attrs" do
      id = Ecto.UUID.generate()

      assert {:ok, %ActivateSeason{season_id: ^id}} =
               ActivateSeason.new(%{season_id: id})
    end

    test "rejects missing season_id" do
      assert {:error, changeset} = ActivateSeason.new(%{})
      assert "can't be blank" in errors_on(changeset).season_id
    end
  end
end
