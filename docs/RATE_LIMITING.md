# Rate Limiting

The Email Collector API implements rate limiting to protect against bot and malicious traffic.

## Current Limits

- **Per IP Address**: 100 email submissions per hour
- **Per Campaign**: 500 email submissions per hour

## How It Works

Rate limiting is applied to the `POST /api/v1/emails/:campaign_id` endpoint using the [Hammer](https://github.com/ExHammer/hammer) library.

### Dual-Layer Protection

1. **IP-based limiting**: Prevents a single IP from flooding the system
2. **Campaign-based limiting**: Prevents a single campaign from being overwhelmed

Both checks must pass for a request to succeed.

## Response

When rate limited, the API returns:
- **Status**: `429 Too Many Requests`
- **Body**: `{"error": "Rate limit exceeded. Please try again later."}`

## Configuration

Rate limits are configured in `lib/email_collector_web/rate_limiter.ex`:

```elixir
@ip_rate_limit_per_hour 100
@campaign_rate_limit_per_hour 500
```

### Adjusting Limits

To change the limits, modify the module attributes in `rate_limiter.ex`:

```elixir
# More restrictive
@ip_rate_limit_per_hour 50
@campaign_rate_limit_per_hour 200

# More permissive
@ip_rate_limit_per_hour 500
@campaign_rate_limit_per_hour 2000
```

## Storage Backend

Currently uses **ETS** (in-memory) backend configured in `config/config.exs`:

```elixir
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}
```

### Scaling to Redis

For distributed systems or persistent rate limiting across restarts:

1. Add Redis dependency:
```elixir
{:hammer_backend_redis, "~> 6.1"}
```

2. Update config:
```elixir
config :hammer,
  backend: {Hammer.Backend.Redis, [
    expiry_ms: 60_000 * 60 * 4,
    redis_url: System.get_env("REDIS_URL") || "redis://localhost:6379"
  ]}
```

## IP Detection

The system checks for proxied requests via the `X-Forwarded-For` header, falling back to `remote_ip`. This ensures accurate rate limiting behind load balancers.

## Testing

Rate limiting tests are in `test/email_collector_web/controllers/api/email_controller_test.exs`:

```bash
mix test test/email_collector_web/controllers/api/email_controller_test.exs
```

## Additional Protection Strategies

Consider adding:

1. **Honeypot fields**: Hidden form fields that bots fill but humans don't
2. **CAPTCHA**: For suspicious traffic patterns
3. **Email verification**: Require confirmation before counting submissions
4. **Time-based checks**: Reject submissions that are too fast (< 2 seconds)
5. **Fingerprinting**: Track browser/device patterns

## Monitoring

To monitor rate limiting effectiveness:

1. Log rate limit hits
2. Track 429 responses in your metrics
3. Monitor campaign submission patterns
4. Alert on unusual spikes

Example logging addition:

```elixir
{:error, :rate_limited} ->
  Logger.warning("Rate limit hit for IP: #{ip_address}, Campaign: #{campaign_id}")
  # ... return 429
```
