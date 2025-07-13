defmodule EmailCollector.Repo do
  use Ecto.Repo,
    otp_app: :email_collector,
    adapter: Ecto.Adapters.SQLite3
end
