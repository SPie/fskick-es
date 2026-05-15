defmodule Fskick.Repo do
  use Ecto.Repo,
    otp_app: :fskick,
    adapter: Ecto.Adapters.Postgres
end
