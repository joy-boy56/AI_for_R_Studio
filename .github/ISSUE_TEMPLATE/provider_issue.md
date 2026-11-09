---
name: Provider Issue
about: Report issues with AI providers (AI Horde, NVIDIA, OpenAI-compatible)
title: '[PROVIDER] '
labels: provider
assignees: ''
---

## Provider
- [ ] AI Horde (default free provider)
- [ ] NVIDIA Nemotron (via gateway)
- [ ] OpenAI-compatible (via gateway)
- [ ] Other: ___________

## Issue Type
- [ ] Model not available / not found
- [ ] Authentication / credentials error
- [ ] Rate limiting / quota exceeded
- [ ] Timeout / slow response
- [ ] Incorrect / poor quality responses
- [ ] Streaming not working
- [ ] Model listing not working
- [ ] Other: ___________

## Description
Describe the issue in detail.

## Steps to Reproduce
```r
library(rconsoleai)
rchat_provider("horde")  # or "gateway"
rchat("your prompt here")
```

## Error Output
Paste the full error message and any relevant logs.

## Expected Behavior
What should happen?

## Configuration
```r
rchat_config()
```

## Backend Details (if using gateway)
- Gateway URL: 
- Provider configured: NVIDIA / OpenAI-compatible / Both
- Cloudflare Worker status: 

## Checklist
- [ ] I have verified my API keys are correctly set in Cloudflare secrets (for gateway)
- [ ] I have checked the provider's status page for outages
- [ ] I have tried with a different model
- [ ] I have checked the troubleshooting guide