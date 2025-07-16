ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(EmailCollector.Repo, :manual)

# Define mocks for testing
Mox.defmock(EmailCollector.ExAwsMock, for: EmailCollector.ExAwsBehaviour)
