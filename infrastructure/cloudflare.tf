terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token (set via CF_TERRAFORM or CLOUDFLARE_API_TOKEN env var)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for collection.email"
  type        = string
}

# Bot Fight Mode
resource "cloudflare_bot_management" "collection_email" {
  zone_id                      = var.cloudflare_zone_id
  enable_js                    = true
  fight_mode                   = true
  suppress_session_score       = false
  auto_update_model            = true
}

# WAF Custom Rule 1: Block Bot User-Agents
resource "cloudflare_ruleset" "block_bot_user_agents" {
  zone_id     = var.cloudflare_zone_id
  name        = "Block Bot User-Agents on POST"
  description = "Block common bot user-agents on API POST requests"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = "block"
    description = "Block bot user-agents on POST to /api/v1/emails"
    enabled     = true
    expression  = "(http.request.method eq \"POST\" and http.request.uri.path contains \"/api/v1/emails\" and (http.user_agent contains \"curl\" or http.user_agent contains \"wget\" or http.user_agent contains \"python-requests\" or http.user_agent contains \"postman\" or lower(http.user_agent) contains \"bot\"))"
  }
}

# WAF Custom Rule 2: Block Missing User-Agent
resource "cloudflare_ruleset" "block_missing_user_agent" {
  zone_id     = var.cloudflare_zone_id
  name        = "Block Missing User-Agent"
  description = "Block POST requests without User-Agent header"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = "block"
    description = "Require User-Agent on POST to /api/v1/emails"
    enabled     = true
    expression  = "(http.request.method eq \"POST\" and http.request.uri.path contains \"/api/v1/emails\" and http.user_agent eq \"\")"
  }
}

# WAF Custom Rule 3: Block Missing Content-Type
resource "cloudflare_ruleset" "block_missing_content_type" {
  zone_id     = var.cloudflare_zone_id
  name        = "Block Missing Content-Type"
  description = "Block POST requests without Content-Type header"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  rules {
    action      = "block"
    description = "Require Content-Type on POST to /api/v1/emails"
    enabled     = true
    expression  = "(http.request.method eq \"POST\" and http.request.uri.path contains \"/api/v1/emails\" and not any(http.request.headers[\"content-type\"][*] eq \"application/json\"))"
  }
}

# Output zone information
output "zone_id" {
  value       = var.cloudflare_zone_id
  description = "Cloudflare Zone ID"
}

output "bot_management_enabled" {
  value       = cloudflare_bot_management.collection_email.fight_mode
  description = "Bot Fight Mode status"
}
