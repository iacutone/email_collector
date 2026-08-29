# EmailCollector

<div align="center">
  <img src="https://img.shields.io/badge/Phoenix-1.8-orange?style=flat-square&logo=phoenix-framework" alt="Phoenix 1.8">
  <img src="https://img.shields.io/badge/Elixir-1.18-purple?style=flat-square&logo=elixir" alt="Elixir 1.18">
  <img src="https://img.shields.io/badge/SQLite-3-blue?style=flat-square&logo=sqlite" alt="SQLite">
  <img src="https://img.shields.io/badge/Cloudflare-Protected-orange?style=flat-square&logo=cloudflare" alt="Cloudflare">
</div>

A lightweight, high-performance email collection API built with Phoenix and Elixir. Designed for developers who need a simple, reliable way to collect and manage email addresses with built-in bot protection.

## Features

- 🚀 **Fast & Lightweight** - Built on Phoenix/Elixir for exceptional performance
- 🔒 **Bot Protection** - Cloudflare edge protection + User-Agent validation
- 📊 **Campaign Management** - Organize emails into campaigns
- 🔑 **API Key Authentication** - Secure access to your data
- 💾 **SQLite Database** - Simple, serverless database with Litestream backups
- 🌐 **Per-Campaign CORS** - Allowlist specific origins per campaign, no wildcard exposure
- ⚡ **Real-time Updates** - Phoenix LiveView for admin dashboard

## Quick Start

### Prerequisites

- Elixir 1.18+
- Erlang/OTP 28+
- SQLite 3

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/email_collector.git
cd email_collector

# Install dependencies
mix setup

# Start the server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

## API Usage

### Collect an Email

```bash
POST /api/v1/emails/:campaign_id
Content-Type: application/json

{
  "email": {
    "name": "user@example.com",
    "misc": {
      "first_name": "John",
      "last_name": "Doe",
      "comments": "Interested in updates"
    }
  }
}
```

### Retrieve Emails

```bash
GET /api/v1/emails/:campaign_id
Authorization: Bearer YOUR_API_KEY
```

### Unsubscribe

```bash
POST /api/v1/emails/:campaign_id/unsubscribe
Content-Type: application/json

{
  "email": "user@example.com"
}
```

## CORS - Allowed Origins

By default all cross-origin browser requests to a campaign are rejected. To accept
requests from your frontend you must register each origin in the campaign dashboard.

### Why per-campaign origins?

Unlike a wildcard `Access-Control-Allow-Origin: *`, this ensures only **your** domains
can POST emails to **your** campaigns. A different user's campaign cannot be targeted
from your site, and vice versa.

### Adding an origin

1. Log in and go to your campaign page
2. Scroll to the **Allowed Origins** section
3. Enter your frontend origin (scheme + host, no trailing slash):
   ```
   https://myapp.com
   ```
4. Click **Add Origin**

You can add multiple origins per campaign - useful for production, staging, and local development:

```
https://myapp.com
https://staging.myapp.com
http://localhost:3000
```

### Integrating with your frontend

```javascript
// Browser fetch - Origin header is sent automatically
const response = await fetch(
  'https://email-collection.com/api/v1/emails/YOUR_CAMPAIGN_ID',
  {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: { name: 'user@example.com' } })
  }
)
```

If the origin of your page is not in the campaign's allowlist, Cloudflare and the
server will both reject the request with a `403 Forbidden` response.

## Bot Protection

EmailCollector uses a multi-layered approach to prevent bot abuse:

### 1. Cloudflare Edge Protection (Recommended)

- **Bot Fight Mode** - Automatic bot detection and blocking
- **Rate Limiting** - 100 requests/hour per IP at the edge
- **WAF Rules** - Custom rules to block suspicious user-agents
- **Zero application overhead** - All protection happens before requests reach your server

See [Cloudflare Setup Guide](docs/CLOUDFLARE_SETUP.md) for configuration.

### 2. Application-Level Validation

- **User-Agent Validation** - Blocks common bot tools (curl, wget, python-requests, etc.)
- **Lightweight** - No dependencies, minimal performance impact
- **Backup layer** - Works even if Cloudflare is bypassed

See [Bot Detection Documentation](docs/BOT_DETECTION.md) for details.

## Deployment

This application is designed to run on any server with Docker support. We use Kamal for deployment.

### Deploy to Production

```bash
# Set up environment variables
cp .env.example .env
# Edit .env with your configuration

# Deploy
kamal deploy
```

### Environment Variables

```bash
SECRET_KEY_BASE=your_secret_key
DATABASE_PATH=/app/data/email_collector.db
AWS_ACCESS_KEY=your_aws_key
AWS_SECRET_KEY=your_aws_secret
LITESTREAM_ACCESS_KEY_ID=your_litestream_key
LITESTREAM_SECRET_ACCESS_KEY=your_litestream_secret
REPLICA_URL=s3://your-bucket/path
```

## Configuration

### Multiple Domains

The application supports multiple domains out of the box:
- `email-collection.com` (primary)
- `www.email-collection.com`

Configure in `config/runtime.exs`:

```elixir
check_origin: [
  "https://email-collection.com",
  "https://www.email-collection.com"
]
```

## Documentation

- [Cloudflare Setup Guide](docs/CLOUDFLARE_SETUP.md) - Complete guide for edge protection
- [Bot Detection](docs/BOT_DETECTION.md) - Application-level bot protection details
- [Rate Limiting](docs/RATE_LIMITING.md) - Rate limiting strategies (deprecated - use Cloudflare)
- [Time-Based Detection](docs/TIME_BASED_BOT_DETECTION.md) - Form submission timing validation

## Development

### Run Tests

```bash
mix test
```

### Code Quality

```bash
# Run Credo
mix credo

# Run Dialyzer
mix dialyzer
```

### Database

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Reset database
mix ecto.reset
```

## Architecture

- **Phoenix Framework** - Web framework
- **Ecto** - Database wrapper and query generator
- **SQLite** - Embedded database
- **Litestream** - Continuous SQLite replication to S3
- **Bandit** - HTTP server
- **Cloudflare** - Edge protection and CDN

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Learn More

- Official Phoenix website: https://www.phoenixframework.org/
- Phoenix Guides: https://hexdocs.pm/phoenix/overview.html
- Phoenix Docs: https://hexdocs.pm/phoenix
- Elixir Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
