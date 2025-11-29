<div align="center">
  <h1>📧 Email Collector</h1>
  <p>
    <strong>A powerful, bot-resistant email collection API built with Phoenix & Elixir</strong>
  </p>
  <p>
    <a href="#features">Features</a> •
    <a href="#quick-start">Quick Start</a> •
    <a href="#api-documentation">API</a> •
    <a href="#bot-protection">Bot Protection</a> •
    <a href="#deployment">Deployment</a>
  </p>
  <p>
    <img src="https://img.shields.io/badge/Elixir-1.18-purple?logo=elixir" alt="Elixir 1.18">
    <img src="https://img.shields.io/badge/Phoenix-1.8-orange?logo=phoenix-framework" alt="Phoenix 1.8">
    <img src="https://img.shields.io/badge/SQLite-3-blue?logo=sqlite" alt="SQLite">
    <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
  </p>
</div>

---

## ✨ Features

- 🚀 **High-Performance API** - Built on Phoenix for blazing-fast email collection
- 🛡️ **Multi-Layer Bot Protection** - Rate limiting, time-based detection, and more
- 📊 **Campaign Management** - Organize emails into campaigns with full CRUD operations
- 🔐 **Secure Authentication** - API key-based auth with bcrypt password hashing
- 📥 **CSV Export** - Download your collected emails instantly
- ✉️ **Unsubscribe Support** - Built-in unsubscribe functionality
- 🌐 **CORS Enabled** - Ready for cross-origin requests
- 📦 **SQLite Database** - Lightweight, serverless, zero-config database
- 🔄 **Litestream Integration** - Continuous SQLite replication for production

## 🚀 Quick Start

### Prerequisites

- Elixir 1.18+
- Erlang/OTP 27+

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

Visit [`localhost:4000`](http://localhost:4000) to access the application.

## 📚 API Documentation

### Collect an Email (Public)

```bash
POST /api/v1/emails/:campaign_id
Content-Type: application/json

{
  "email": {
    "name": "user@example.com"
  },
  "form_loaded_at": 1638360000000  # Optional: for bot detection
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "name": "user@example.com",
  "campaign_id": "abc-123",
  "inserted_at": "2024-11-28T12:00:00Z"
}
```

### Unsubscribe (Public)

```bash
POST /api/v1/emails/:campaign_id/unsubscribe
Content-Type: application/json

{
  "email": "user@example.com"
}
```

### List Campaign Emails (Authenticated)

```bash
GET /api/v1/emails/:campaign_id
Authorization: Bearer YOUR_API_KEY
```

**Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "user@example.com",
    "campaign_id": "abc-123",
    "inserted_at": "2024-11-28T12:00:00Z"
  }
]
```

## 🛡️ Bot Protection

Email Collector includes comprehensive bot protection out of the box:

### 1. **Rate Limiting** (via Hammer)
- 100 requests per hour per IP address
- 500 requests per hour per campaign
- Returns `429 Too Many Requests` when exceeded

### 2. **Time-Based Detection**
- Rejects submissions faster than 2 seconds (bots submit instantly)
- Validates form load timestamps
- Detects suspicious timing patterns

### 3. **Email Validation**
- RFC-compliant email address validation
- Prevents duplicate submissions per campaign

### Configuration

Adjust limits in `lib/email_collector_web/rate_limiter.ex`:

```elixir
@ip_rate_limit_per_hour 100
@campaign_rate_limit_per_hour 500
@min_form_time_ms 2000  # 2 seconds
```

📖 **Learn More:**
- [Rate Limiting Guide](docs/RATE_LIMITING.md)
- [Time-Based Bot Detection](docs/TIME_BASED_BOT_DETECTION.md)

## 🎯 Campaign Management

### Create a Campaign

1. Sign up at `/auth/new`
2. Log in at `/auth/login`
3. Create a campaign at `/campaigns/new`
4. Use the campaign ID in your forms

### Download Emails

Visit `/campaigns/:id/download` to export emails as CSV.

## 🔐 Authentication

The API uses two authentication methods:

- **Browser Sessions** - For web interface (campaigns, profile)
- **API Keys** - For programmatic access (GET endpoints)

Get your API key from your profile page after logging in.

## 🌐 Client Integration

### Vanilla JavaScript

```html
<form id="email-form">
  <input type="email" name="email" required>
  <input type="hidden" id="form-loaded-at">
  <button type="submit">Subscribe</button>
</form>

<script>
  document.getElementById('form-loaded-at').value = Date.now();
  
  document.getElementById('email-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const response = await fetch('/api/v1/emails/YOUR_CAMPAIGN_ID', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: { name: e.target.email.value },
        form_loaded_at: parseInt(e.target.querySelector('#form-loaded-at').value)
      })
    });
    
    if (response.ok) {
      alert('Successfully subscribed!');
    }
  });
</script>
```

### React

```jsx
import { useState, useEffect } from 'react';

function EmailForm({ campaignId }) {
  const [email, setEmail] = useState('');
  const [formLoadedAt, setFormLoadedAt] = useState(null);

  useEffect(() => {
    setFormLoadedAt(Date.now());
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    const response = await fetch(`/api/v1/emails/${campaignId}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: { name: email },
        form_loaded_at: formLoadedAt
      })
    });
    
    if (response.ok) {
      alert('Successfully subscribed!');
      setEmail('');
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      <button type="submit">Subscribe</button>
    </form>
  );
}
```

## 🚢 Deployment

### Production Setup

```bash
# Set environment variables
export SECRET_KEY_BASE="your-secret-key"
export DATABASE_PATH="priv/email_collector.db"
export PHX_HOST="yourdomain.com"

# Build release
MIX_ENV=prod mix release

# Run
_build/prod/rel/email_collector/bin/email_collector start
```

### With Litestream (Recommended)

Email Collector includes Litestream for continuous SQLite replication to S3, ensuring data durability.

Configure in `config/runtime.exs`:

```elixir
config :email_collector, Litestream,
  replica_url: System.get_env("LITESTREAM_REPLICA_URL")
```

📖 **Learn More:** [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)

## 🧪 Testing

```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/email_collector_web/controllers/api/email_controller_test.exs
```

## 🛠️ Development

```bash
# Run the server
mix phx.server

# Run with IEx
iex -S mix phx.server

# Run linter
mix credo

# Run type checker
mix dialyzer

# Format code
mix format
```

## 📁 Project Structure

```
email_collector/
├── lib/
│   ├── email_collector/          # Business logic
│   │   ├── accounts/              # User authentication
│   │   ├── campaigns/             # Campaign management
│   │   └── emails/                # Email collection
│   └── email_collector_web/       # Web interface
│       ├── controllers/           # HTTP handlers
│       │   └── api/               # API endpoints
│       ├── rate_limiter.ex        # Bot protection
│       └── router.ex              # Route definitions
├── priv/
│   └── repo/migrations/           # Database migrations
├── test/                          # Test suite
└── docs/                          # Documentation
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 🔗 Resources

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir Lang](https://elixir-lang.org/)
- [Hammer Rate Limiter](https://github.com/ExHammer/hammer)
- [Litestream](https://litestream.io/)

---

<div align="center">
  <p>Built with ❤️ using Phoenix & Elixir</p>
</div>
