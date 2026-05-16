defmodule Mix.Tasks.Fskick.Players.New do
  @moduledoc """
  Creates a new player with the given name.

      mix fskick.players.new "Alice"

  Fails if the name already exists or is empty.
  """

  use Mix.Task

  alias Fskick.Players

  @shortdoc ~s|Creates a new player: mix fskick.players.new "Alice"|

  @impl Mix.Task
  def run([name | _]) do
    Mix.Task.run("app.start")

    case Players.create_player(name) do
      {:ok, player} ->
        Mix.shell().info("Player #{player.name} created")

      {:error, :projection_timeout} ->
        Mix.raise("Player was created but read model did not catch up in time")

      {:error, %Ecto.Changeset{} = changeset} ->
        if name_taken?(changeset) do
          Mix.raise("Player with name #{inspect(name)} already exists")
        else
          Mix.raise("Invalid input: #{format_errors(changeset)}")
        end

      {:error, reason} ->
        Mix.raise("Failed to create player: #{inspect(reason)}")
    end
  end

  def run(_), do: Mix.raise(~s|Usage: mix fskick.players.new "<name>"|)

  defp name_taken?(changeset) do
    changeset.errors
    |> Keyword.get_values(:name)
    |> Enum.any?(fn {msg, _opts} -> msg == "has already been taken" end)
  end

  defp format_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc ->
        String.replace(acc, "%{#{k}}", to_string(v))
      end)
    end)
    |> inspect()
  end
end
