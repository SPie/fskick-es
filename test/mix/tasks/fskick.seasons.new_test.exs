defmodule Mix.Tasks.Fskick.Seasons.NewTest do
  use Fskick.DataCase

  import ExUnit.CaptureIO

  alias Mix.Tasks.Fskick.Seasons.New

  test "creates a season and prints a success message" do
    output = capture_io(fn -> New.run(["2026"]) end)
    assert output =~ "Season 2026 created"
  end

  test "raises when the name is already taken" do
    capture_io(fn -> New.run(["2026"]) end)

    assert_raise Mix.Error, ~r/already exists/, fn ->
      capture_io(fn -> New.run(["2026"]) end)
    end
  end

  test "raises when the name is empty" do
    assert_raise Mix.Error, ~r/Invalid input/, fn ->
      capture_io(fn -> New.run([""]) end)
    end
  end

  test "raises when no argument is given" do
    assert_raise Mix.Error, ~r/Usage/, fn ->
      New.run([])
    end
  end
end
