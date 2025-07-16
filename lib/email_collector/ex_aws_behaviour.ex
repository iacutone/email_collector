defmodule EmailCollector.ExAwsBehaviour do
  @moduledoc """
  Behaviour module for ExAws operations used by the mailer.
  This allows us to mock ExAws in tests using mox.
  """

  @callback request(ExAws.Operation.t()) :: {:ok, map()} | {:error, term()}
end 