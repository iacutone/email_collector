defmodule EmailCollectorWeb.Plugs.ApiAuthPlug do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    api_key =
      get_req_header(conn, "authorization")
      |> List.first()
      |> extract_api_key()

    case EmailCollector.Accounts.get_user_by_api_key(api_key) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid API key"})
        |> halt()

      user ->
        assign(conn, :current_user, user)
    end
  end

  defp extract_api_key(nil), do: nil
  defp extract_api_key("Bearer " <> api_key), do: api_key
  defp extract_api_key(api_key), do: api_key
end
