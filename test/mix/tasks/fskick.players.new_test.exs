defmodule Mix.Tasks.Fskick.Players.NewTest do
  use Fskick.DataCase

  import ExUnit.CaptureIO

  alias Mix.Tasks.Fskick.Players.New

  test "creates a player and prints a success message" do
    output = capture_io(fn -> New.run(["Alice"]) end)
    assert output =~ "Player Alice created"
  end

  test "raises when the name is already taken" do
    capture_io(fn -> New.run(["Alice"]) end)

    assert_raise Mix.Error, ~r/already exists/, fn ->
      capture_io(fn -> New.run(["Alice"]) end)
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
