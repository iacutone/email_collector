# Cloudflare Infrastructure with OpenTofu

This directory contains OpenTofu/Terraform configuration for managing Cloudflare bot protection.

## Prerequisites

1. Install OpenTofu: https://opentofu.org/docs/intro/install/
2. Get Cloudflare API Token: https://dash.cloudflare.com/profile/api-tokens
   - Permissions needed: Zone.Bot Management, Zone.Firewall Services, Zone.Zone Settings
3. Get your Zone ID from Cloudflare dashboard (Overview page, right sidebar)

## Setup

### Option 1: Using Environment Variables (Recommended)

```bash
# Set Cloudflare API token (you already did this!)
export CLOUDFLARE_API_TOKEN="your-api-token"

# Set Zone ID
export TF_VAR_cloudflare_zone_id="your-zone-id"
```

### Option 2: Using terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your zone_id
```

## Initialize

```bash
cd infrastructure
tofu init
```

## Usage

### Plan changes:
```bash
tofu plan
```

### Apply configuration:
```bash
tofu apply
```

### Destroy resources:
```bash
tofu destroy
```

## What This Creates

- ✅ Bot Fight Mode enabled
- ✅ WAF rule: Block bot user-agents (curl, wget, python-requests, postman, bot)
- ✅ WAF rule: Block missing User-Agent header
- ✅ WAF rule: Block missing Content-Type header

## Security Note

Never commit `terraform.tfvars` to git if it contains sensitive data!
Using environment variables is safer.
