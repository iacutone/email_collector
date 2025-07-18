import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :email_collector, EmailCollector.Repo,
  database: Path.expand("../email_collector_test.db", __DIR__),
  pool_size: 5,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :email_collector, EmailCollectorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "GvmKdNENmZbaCGsoP7v3mmjOtWagjeMGZtYpTYKt5B/tRFecyAxkXs1mF5FJMLh5",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure mox for mocking ExAws in tests
config :email_collector,
  ex_aws_client: EmailCollector.ExAwsMock

config :email_collector, :token_salt, "super_secret_password_reset_salt_2024"
