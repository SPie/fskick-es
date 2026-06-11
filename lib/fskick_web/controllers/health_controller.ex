defmodule FskickWeb.HealthController do
  use FskickWeb, :controller

  def check(conn, _params) do
    case Ecto.Adapters.SQL.query(Fskick.Repo, "SELECT 1", []) do
      {:ok, _} ->
        json(conn, %{status: "ok"})

      {:error, reason} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{status: "error", reason: inspect(reason)})
    end
  end
end
