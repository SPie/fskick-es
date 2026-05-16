defmodule Fskick.App do
  use Commanded.Application, otp_app: :fskick

  router(Fskick.Router)
end
