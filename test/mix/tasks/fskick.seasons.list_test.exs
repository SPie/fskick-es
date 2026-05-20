defmodule Mix.Tasks.Fskick.Seasons.ListTest do
  use Fskick.DataCase

  import ExUnit.CaptureIO

  alias Fskick.Seasons
  alias Mix.Tasks.Fskick.Seasons.List

  test "renders a table with headers when no seasons exist" do
    output = capture_io(fn -> List.run([]) end)
    assert output =~ "Name"
    assert output =~ "Active"
  end

  test "renders each season name and a blank Active cell when inactive" do
    {:ok, _} = Seasons.create_season("2026")

    output = capture_io(fn -> List.run([]) end)
    assert output =~ "2026"
    refute output =~ ~r/2026\s*\|\s*Active/
  end
end
