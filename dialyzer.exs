defmodule Dialyzer.Config do
  def project() do
    [
      plt_add_apps: [:ex_unit, :mix, :phoenix, :phoenix_live_view, :phoenix_html, :ecto, :ecto_sql, :ecto_sqlite3, :bcrypt_elixir, :nimble_csv],
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
      ignore_warnings: ".dialyzer_ignore.exs",
      list_unused_filters: true,
      check_plt: true,
      plt_core_path: "priv/plts",
      plt_local_path: "priv/plts"
    ]
  end
end 