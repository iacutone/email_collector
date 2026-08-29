defmodule EmailCollectorWeb.Plugs.CorsPlug do
  @moduledoc """
  Per-campaign CORS plug.

  Validates the request Origin against the campaign's allowed_origins allowlist.
  Requests with no Origin header (e.g. direct curl calls) are passed through to
  the bot detector and other validations downstream.

  Preflight OPTIONS requests are handled here so the browser gets the correct
  Access-Control-Allow-Origin before sending the actual POST.
  """

  import Plug.Conn
  alias EmailCollector.Campaigns

  def init(opts), do: opts

  def call(%Plug.Conn{method: "OPTIONS"} = conn, _opts) do
    campaign_id = conn.path_params["campaign_id"] || conn.path_params["id"]
    origin = get_req_header(conn, "origin") |> List.first()

    conn
    |> put_cors_headers(campaign_id, origin)
    |> send_resp(200, "")
    |> halt()
  end

  def call(conn, _opts) do
    origin = get_req_header(conn, "origin") |> List.first()

    # No Origin header means a direct (non-browser) request.
    # Let the bot detector handle it downstream.
    if is_nil(origin) do
      conn
    else
      campaign_id = conn.path_params["campaign_id"]

      case origin_allowed?(campaign_id, origin) do
        true ->
          conn
          |> put_resp_header("access-control-allow-origin", origin)
          |> put_resp_header("access-control-allow-methods", "POST, OPTIONS")
          |> put_resp_header("access-control-allow-headers", "Content-Type, Accept")
          |> put_resp_header("vary", "Origin")

        false ->
          conn
          |> put_status(:forbidden)
          |> Phoenix.Controller.json(%{error: "Origin not allowed"})
          |> halt()
      end
    end
  end

  # Private

  defp origin_allowed?(nil, _origin), do: false

  defp origin_allowed?(campaign_id, origin) do
    case Campaigns.get_campaign(campaign_id) do
      nil -> false
      campaign -> origin in campaign.allowed_origins
    end
  end

  defp put_cors_headers(conn, campaign_id, origin) do
    if origin && origin_allowed?(campaign_id, origin) do
      conn
      |> put_resp_header("access-control-allow-origin", origin)
      |> put_resp_header("access-control-allow-methods", "POST, OPTIONS")
      |> put_resp_header("access-control-allow-headers", "Content-Type, Accept")
      |> put_resp_header("vary", "Origin")
    else
      conn
    end
  end
end
