defmodule Mix.Tasks.Fskick.Seasons.New do
  @moduledoc """
  Creates a new season with the given name.

      mix fskick.seasons.new "2026"

  Newly created seasons are inactive. Fails if the name already exists or is empty.
  """

  use Mix.Task

  alias Fskick.Seasons

  @shortdoc ~s|Creates a new season: mix fskick.seasons.new "2026"|

  @impl Mix.Task
  def run([name | _]) do
    Mix.Task.run("app.start")

    case Seasons.create_season(name) do
      {:ok, season} ->
        Mix.shell().info("Season #{season.name} created")

      {:error, :projection_timeout} ->
        Mix.raise("Season was created but read model did not catch up in time")

      {:error, %Ecto.Changeset{} = changeset} ->
        if name_taken?(changeset) do
          Mix.raise("Season with name #{inspect(name)} already exists")
        else
          Mix.raise("Invalid input: #{format_errors(changeset)}")
        end

      {:error, reason} ->
        Mix.raise("Failed to create season: #{inspect(reason)}")
    end
  end

  def run(_), do: Mix.raise(~s|Usage: mix fskick.seasons.new "<name>"|)

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
