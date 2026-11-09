# RConsoleAI Backend Gateway

Cloudflare Workers backend for RConsoleAI secure AI provider gateway.

## Overview

This backend provides a secure gateway for authenticated AI providers:
- **NVIDIA Nemotron** via NVIDIA API
- **OpenAI-compatible** endpoints (OpenAI, Azure, local models)

The R package communicates with this gateway, never directly with provider APIs. API keys are stored only in Cloudflare secrets.

## Architecture

```
R Package (rconsoleai)
    │
    ▼ HTTPS
Cloudflare Worker (this backend)
    │
    ├──► NVIDIA API (Nemotron models)
    │
    └──► OpenAI-compatible API (GPT, local, Azure)
```

## Quick Start

```bash
cd backend
npm install
npx wrangler login

# Set secrets for providers you want
npx wrangler secret put NVIDIA_API_KEY
npx wrangler secret put OPENAI_API_KEY
npx wrangler secret put OPENAI_BASE_URL  # Optional

# Deploy
npx wrangler deploy
```

## Configuration

### Secrets (Required)

Set via `npx wrangler secret put SECRET_NAME`:

| Secret | Description |
|--------|-------------|
| `NVIDIA_API_KEY` | NVIDIA API key from build.nvidia.com |
| `OPENAI_API_KEY` | OpenAI or compatible API key |
| `OPENAI_BASE_URL` | Custom endpoint (default: https://api.openai.com/v1) |
| `OPENAI_ORGANIZATION` | OpenAI organization ID (optional) |

### Environment Variables (wrangler.toml)

```toml
[vars]
ENVIRONMENT = "production"
LOG_LEVEL = "info"
# RATE_LIMIT_PER_MINUTE = "60"
# RATE_LIMIT_PER_HOUR = "1000"
# ALLOWED_ORIGINS = "https://yourdomain.com"
```

## API Endpoints

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "service": "rconsoleai-gateway",
  "version": "0.1.0",
  "timestamp": "2024-01-01T00:00:00.000Z"
}
```

### GET /models
List available models from all configured providers.

**Query Parameters:**
- `provider`: `nvidia`, `openai-compatible`, or `all` (default)

**Response:**
```json
{
  "models": [
    {"id": "nvidia/nemotron-3-ultra", "name": "nvidia/nemotron-3-ultra", "provider": "nvidia", "owned_by": "nvidia"},
    {"id": "gpt-3.5-turbo", "name": "gpt-3.5-turbo", "provider": "openai-compatible", "owned_by": "openai"}
  ],
  "count": 2
}
```

### GET /providers
List configured providers and their status.

**Response:**
```json
{
  "providers": [
    {"name": "nvidia", "configured": true, "default_model": "nvidia/nemotron-3-ultra"},
    {"name": "openai-compatible", "configured": true, "base_url": "https://api.openai.com/v1", "default_model": "gpt-3.5-turbo"}
  ]
}
```

### POST /chat
Chat completion endpoint.

**Request:**
```json
{
  "messages": [
    {"role": "system", "content": "You are helpful"},
    {"role": "user", "content": "Hello!"}
  ],
  "model": "nvidia/nemotron-3-ultra",
  "max_tokens": 700,
  "temperature": 0.7,
  "stream": false
}
```

**Response:**
```json
{
  "choices": [
    {
      "message": {"role": "assistant", "content": "Hello! How can I help?"},
      "finish_reason": "stop",
      "index": 0
    }
  ],
  "usage": {"prompt_tokens": 20, "completion_tokens": 10, "total_tokens": 30},
  "model": "nvidia/nemotron-3-ultra"
}
```

## Error Responses

All errors follow this format:
```json
{
  "error": "Error type",
  "message": "Human-readable description"
}
```

| Status | Error | Description |
|--------|-------|-------------|
| 400 | Invalid request | Request validation failed |
| 401 | Authentication failed | Invalid API credentials |
| 404 | Model not found | Requested model unavailable |
| 429 | Rate limit exceeded | Too many requests |
| 500 | Internal server error | Unexpected error |
| 503 | Provider unavailable | No providers configured |

## Rate Limiting

Default limits (per IP):
- 60 requests/minute
- 1000 requests/hour

Configure via secrets:
```bash
npx wrangler secret put RATE_LIMIT_PER_MINUTE "120"
npx wrangler secret put RATE_LIMIT_PER_HOUR "2000"
```

Rate limit headers included in responses:
- `X-RateLimit-Limit-Minute`
- `X-RateLimit-Remaining-Minute`
- `X-RateLimit-Reset-Minute`
- `X-RateLimit-Limit-Hour`
- `X-RateLimit-Remaining-Hour`
- `X-RateLimit-Reset-Hour`

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Type checking
npm run typecheck

# Linting
npm run lint

# Tests
npm test
```

## Project Structure

```
backend/
├── src/
│   ├── index.ts              # Main entry point
│   ├── router.ts             # Request routing
│   ├── providers/
│   │   ├── nvidia.ts         # NVIDIA Nemotron provider
│   │   └── openai-compatible.ts  # OpenAI-compatible provider
│   └── middleware/
│       ├── rate-limit.ts     # Rate limiting
│       ├── validation.ts     # Request validation
│       └── error-handler.ts  # Error handling
├── wrangler.toml             # Cloudflare Worker config
├── package.json              # Dependencies
└── tsconfig.json             # TypeScript config
```

## Deployment

### Production
```bash
npx wrangler deploy --env production
```

### Preview/Staging
```bash
npx wrangler deploy --env staging
```

### Custom Domain
1. Cloudflare Dashboard > Workers > your-worker > Triggers
2. Add Custom Domain
3. Update R package: `rchat_config(gateway_url = "https://ai.yourdomain.com")`

## Monitoring

### Logs
```bash
npx wrangler tail
```

### Metrics
Cloudflare Dashboard > Workers > your-worker > Metrics

## Security

- API keys stored only in Cloudflare secrets
- Request validation on all endpoints
- Rate limiting prevents abuse
- CORS configurable via `ALLOWED_ORIGINS`
- No prompt logging by default
- HTTPS only

## Cost

Cloudflare Workers Free Tier:
- 100,000 requests/day
- 10ms CPU time/request
- Sufficient for personal/small team use

## Important Notes

### NVIDIA Authorization
**NVIDIA developer/free API access does NOT automatically permit operating a publicly shared multi-user AI service.**

Before enabling shared NVIDIA inference:
1. Review [NVIDIA Terms of Service](https://www.nvidia.com/en-us/about-nvidia/terms-of-use/)
2. Obtain required authorization/license for shared use
3. Consider using only for personal/team use

### Local Models
For local models (Ollama, vLLM, TGI), set `OPENAI_BASE_URL` to your local endpoint:
```bash
npx wrangler secret put OPENAI_BASE_URL "http://localhost:11434/v1"
# Note: Local endpoints need Cloudflare Tunnel or public IP
```

## Support

- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [RConsoleAI Issues](https://github.com/yourusername/rconsoleai/issues)