# Security Policy

## Supported Versions

We provide security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in RConsoleAI, please report it responsibly:

### Private Disclosure

**Do not create a public issue.** Instead, email us at:

**security@rconsoleai.example.com**

Or use GitHub's private vulnerability reporting:
1. Go to the [Security tab](https://github.com/yourusername/rconsoleai/security)
2. Click "Report a vulnerability"
3. Fill in the details

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes
- Your contact information (optional)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 7 days
- **Fix Timeline**: Depends on severity
  - Critical: Within 30 days
  - High: Within 60 days
  - Medium: Within 90 days
  - Low: Next release cycle

## Security Architecture

### Secrets Management

- **No secrets in client code**: API keys never stored in R package
- **Backend-only secrets**: Cloudflare Workers environment secrets
- **No .Rprofile storage**: Secrets never written to user config files
- **No git history**: Keys never committed

### Provider Security

#### AI Horde (Default)
- Anonymous access via public API
- No authentication required
- No user data stored by RConsoleAI
- Prompts sent to distributed workers (community-run)

#### Secure Backend Gateway (Optional)
- Rate limiting: 60 req/min per IP, 1000 req/hour global
- Request validation: message length, token limits
- CORS: Restricted to known origins
- No prompt logging by default
- Provider credentials in Cloudflare secrets only

### Data Handling

- **Conversation history**: Stored locally only (opt-in via `persist_history`)
- **R environment data**: Only sent with explicit consent (`include_values = TRUE`)
- **Dataset contents**: Only metadata sent by default
- **No telemetry**: No usage analytics collected

### Network Security

- HTTPS only for all API communications
- Certificate validation enforced
- Request timeouts (default 90s)
- No insecure redirects

## Known Security Considerations

### AI Horde
- Prompts processed by unknown third-party workers
- Not suitable for sensitive/confidential data
- No guarantee of worker integrity
- Use gateway provider for sensitive workloads

### Generated Code
- AI-generated code is **never automatically executed**
- User must explicitly copy and run code
- Review all generated code before execution
- No `eval(parse())` or similar in package code

### Supply Chain
- Dependencies: httr2, jsonlite, R6 (well-maintained CRAN packages)
- Regular dependency updates via Dependabot
- Lockfile: `renv.lock` for reproducible environments

## Best Practices for Users

1. **Don't send secrets** in prompts (passwords, API keys, tokens)
2. **Use gateway provider** for sensitive data
3. **Review generated code** before running
4. **Disable history persistence** for sensitive sessions: `rchat_config(persist_history = FALSE)`
5. **Use environment context cautiously**: `rchat_env(include_values = TRUE)` only when needed

## Security Updates

Security fixes will be released as patch versions. Subscribe to:
- GitHub releases
- Security advisories

## Acknowledgments

We thank security researchers who responsibly disclose vulnerabilities.