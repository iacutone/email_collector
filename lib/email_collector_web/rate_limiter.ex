defmodule EmailCollectorWeb.RateLimiter do
  @moduledoc """
  Rate limiting configuration and helpers for the Email Collector API.

  ## Rate Limits

  - **Per IP Address**: 100 requests per hour
  - **Per Campaign**: 500 requests per hour

  ## Configuration

  Adjust these limits based on your needs:
  - Increase for high-traffic campaigns
  - Decrease for stricter bot protection
  - Consider different limits for different environments

  ## Storage

  Uses Hammer with ETS backend (in-memory).
  For distributed systems, consider Redis backend.
  """

  @ip_rate_limit_per_hour 100
  @campaign_rate_limit_per_hour 500

  @doc """
  Check if an IP address has exceeded its rate limit.

  Returns `{:ok, :allowed}` if within limit, `{:error, :rate_limited}` otherwise.
  """
  def check_ip_rate_limit(ip_address) do
    case Hammer.check_rate("email:ip:#{ip_address}", :timer.hours(1), @ip_rate_limit_per_hour) do
      {:allow, _count} -> {:ok, :allowed}
      {:deny, _limit} -> {:error, :rate_limited}
    end
  end

  @doc """
  Check if a campaign has exceeded its rate limit.

  Returns `{:ok, :allowed}` if within limit, `{:error, :rate_limited}` otherwise.
  """
  def check_campaign_rate_limit(campaign_id) do
    case Hammer.check_rate(
           "email:campaign:#{campaign_id}",
           :timer.hours(1),
           @campaign_rate_limit_per_hour
         ) do
      {:allow, _count} -> {:ok, :allowed}
      {:deny, _limit} -> {:error, :rate_limited}
    end
  end

  @doc """
  Extract client IP address from connection, checking for proxy headers.
  """
  def get_client_ip(conn) do
    # Check for forwarded IP first (for proxies/load balancers)
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] ->
        ip
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        # Fall back to remote_ip
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end

  @doc """
  Get the current IP rate limit.
  """
  def ip_rate_limit, do: @ip_rate_limit_per_hour

  @doc """
  Get the current campaign rate limit.
  """
  def campaign_rate_limit, do: @campaign_rate_limit_per_hour
end
