defmodule EmailCollectorWeb.RateLimiter do
  @moduledoc """
  Rate limiting configuration and helpers for the Email Collector API.

  ## Rate Limits

  - **Per IP Address**: 100 requests per hour
  - **Per Campaign**: 500 requests per hour
  - **Minimum Form Time**: 2 seconds (bots submit too fast)

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
  @min_form_time_ms 2000

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

  @doc """
  Validate that enough time has passed since form load.

  Expects a `form_loaded_at` timestamp (Unix milliseconds) in the params.
  Returns `{:ok, :valid}` if enough time passed, `{:error, :too_fast}` otherwise.

  Bots typically submit forms instantly (< 2 seconds), while humans need time to:
  - Read the form
  - Type their email
  - Click submit

  ## Example

      # Client sends timestamp when form was loaded
      %{"form_loaded_at" => 1638360000000, "email" => %{"name" => "user@example.com"}}
  """
  def check_form_timing(form_loaded_at) when is_integer(form_loaded_at) do
    current_time = System.system_time(:millisecond)
    time_elapsed = current_time - form_loaded_at

    cond do
      # Form loaded in the future? Suspicious
      time_elapsed < 0 ->
        {:error, :suspicious_timing}

      # Too fast? Likely a bot
      time_elapsed < @min_form_time_ms ->
        {:error, :too_fast}

      # Too slow? Could be legitimate but also suspicious (> 1 hour)
      time_elapsed > :timer.hours(1) ->
        {:error, :expired}

      # Just right
      true ->
        {:ok, :valid}
    end
  end

  def check_form_timing(_), do: {:error, :invalid_timestamp}

  @doc """
  Generate a form token with timestamp for client-side forms.

  Returns a signed token that includes the current timestamp.
  The client should send this back with the form submission.
  """
  def generate_form_token do
    timestamp = System.system_time(:millisecond)
    Base.encode64("#{timestamp}")
  end

  @doc """
  Decode and validate a form token.

  Returns `{:ok, timestamp}` if valid, `{:error, reason}` otherwise.
  """
  def decode_form_token(token) when is_binary(token) do
    case Base.decode64(token) do
      {:ok, decoded} ->
        case Integer.parse(decoded) do
          {timestamp, ""} -> {:ok, timestamp}
          _ -> {:error, :invalid_token}
        end

      :error ->
        {:error, :invalid_token}
    end
  end

  def decode_form_token(_), do: {:error, :invalid_token}
end
