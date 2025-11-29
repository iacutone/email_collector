# Time-Based Bot Detection

The Email Collector API includes time-based bot detection to catch automated submissions that happen too quickly.

## How It Works

Bots typically submit forms instantly (< 2 seconds), while real users need time to:
- Read the form
- Type their email address
- Click the submit button

The API checks the time elapsed between form load and submission:
- **< 2 seconds**: Rejected as too fast (likely a bot)
- **2 seconds - 1 hour**: Accepted as valid
- **> 1 hour**: Rejected as expired (form should be reloaded)

## Implementation

### Client-Side (JavaScript)

Add a hidden timestamp field when the form loads:

```html
<form id="email-form">
  <input type="email" name="email" placeholder="Enter your email" required>
  <input type="hidden" id="form-loaded-at" name="form_loaded_at">
  <button type="submit">Subscribe</button>
</form>

<script>
  // Set timestamp when form loads
  document.getElementById('form-loaded-at').value = Date.now();

  // Handle form submission
  document.getElementById('email-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = {
      email: {
        name: e.target.email.value
      },
      form_loaded_at: parseInt(e.target.form_loaded_at.value)
    };

    const response = await fetch('/api/v1/emails/YOUR_CAMPAIGN_ID', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(formData)
    });

    if (response.ok) {
      alert('Successfully subscribed!');
    } else {
      const error = await response.json();
      alert(error.error);
    }
  });
</script>
```

### API Request Format

```json
POST /api/v1/emails/:campaign_id
{
  "email": {
    "name": "user@example.com"
  },
  "form_loaded_at": 1638360000000
}
```

The `form_loaded_at` field should contain a Unix timestamp in milliseconds (from `Date.now()` in JavaScript).

## Error Responses

### Too Fast (< 2 seconds)
```json
{
  "error": "Form submitted too quickly. Please try again."
}
```
**Status**: 422 Unprocessable Entity

### Suspicious Timing (future timestamp)
```json
{
  "error": "Invalid form submission."
}
```
**Status**: 422 Unprocessable Entity

### Expired (> 1 hour)
```json
{
  "error": "Form has expired. Please reload and try again."
}
```
**Status**: 422 Unprocessable Entity

### Invalid Timestamp
```json
{
  "error": "Invalid form data."
}
```
**Status**: 422 Unprocessable Entity

## Configuration

The minimum form time is configured in `lib/email_collector_web/rate_limiter.ex`:

```elixir
@min_form_time_ms 2000  # 2 seconds
```

Adjust based on your needs:
- **More strict**: Increase to 3-5 seconds
- **More lenient**: Decrease to 1 second (not recommended)

## Optional Feature

The timestamp is **optional** by default. If not provided, the submission is allowed. This ensures backward compatibility with existing forms.

To make it **required**, modify the `check_form_timing/1` function in the controller:

```elixir
# Make timestamp required
defp check_form_timing(%{"form_loaded_at" => _} = params) do
  # existing logic
end

defp check_form_timing(_), do: {:error, :missing_timestamp}
```

## Testing

Run the time-based detection tests:

```bash
mix test test/email_collector_web/controllers/api/email_controller_test.exs
```

## React Example

```jsx
import { useState, useEffect } from 'react';

function EmailForm({ campaignId }) {
  const [email, setEmail] = useState('');
  const [formLoadedAt, setFormLoadedAt] = useState(null);

  useEffect(() => {
    // Set timestamp when component mounts
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
    } else {
      const error = await response.json();
      alert(error.error);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Enter your email"
        required
      />
      <button type="submit">Subscribe</button>
    </form>
  );
}
```

## Combining with Other Protections

Time-based detection works alongside:
- **Rate limiting**: 100 requests/hour per IP, 500/hour per campaign
- **Honeypot fields**: Hidden fields that bots fill but humans don't
- **CAPTCHA**: For suspicious traffic patterns

Together, these provide comprehensive bot protection.
