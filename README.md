# RConsoleAI

[![R-CMD-check](https://github.com/yourusername/rconsoleai/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yourusername/rconsoleai/actions/workflows/R-CMD-check.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![R Version](https://img.shields.io/badge/R-%3E%3D%204.1.0-blue.svg)](https://www.r-project.org/)

**An AI chatbot that works directly inside the R and RStudio Console.**

RConsoleAI lets you chat with AI models, debug code, explain code, analyze datasets, and generate R code—all without leaving your R console. No local models, no Ollama, no API keys required for basic usage.

## Features

- **Interactive Chat**: Run `rchat()` for a continuous conversation in your R console
- **Single Prompts**: `rchat("Explain pnorm in R")` for quick questions
- **Multiple Providers**: AI Horde (free, default), secure backend gateway (NVIDIA Nemotron, OpenAI-compatible)
- **Slash Commands**: `/help`, `/models`, `/provider`, `/system`, `/save`, `/load`, and more
- **R Programming Integration**:
  - `rchat_code()` - Debug and review R code
  - `rchat_explain()` - Explain what code does
  - `rchat_data()` - Analyze datasets with visualization & analysis suggestions
  - `rchat_env()` - Ask questions about your R environment
- **Conversation Memory**: Persistent history across sessions
- **Model Discovery**: Dynamic model listing with worker availability
- **Zero Configuration**: Works out of the box with AI Horde
- **Privacy-First**: No data sent without consent; secrets never leave backend

## Quick Start

```r
# Install from GitHub (CRAN coming soon)
install.packages("remotes")
remotes::install_github("yourusername/rconsoleai")

# Load and start chatting
library(rconsoleai)
rchat()
```

```text
========================================
          RConsoleAI
      Your AI Programming Assistant
========================================

Provider: AI Horde
Model: Automatically selected
Status: Connected

Type /help for commands.
Type /exit to quit.

You: 
```

## Installation

### From GitHub (Current)

```r
install.packages("remotes")
remotes::install_github("yourusername/rconsoleai")
```

### From CRAN (Future)

```r
install.packages("rconsoleai")
```

### System Requirements

- R >= 4.1.0
- Internet connection (for AI Horde)
- Optional: Cloudflare Workers backend for NVIDIA/OAI providers

## Usage

### Interactive Chat

```r
# Start interactive session
rchat()

# With specific provider
rchat(provider = "horde")
rchat(provider = "gateway")  # Requires backend
```

### Single Prompts

```r
rchat("Explain the pnorm function in R.")
rchat("How do I do a t-test in R?", provider = "horde")
```

### Slash Commands

| Command | Description |
|---------|-------------|
| `/help` | Show available commands |
| `/exit`, `/quit` | End session |
| `/clear` | Clear conversation history |
| `/models` | List available models |
| `/model` | Show current model |
| `/model NAME` | Change model |
| `/provider` | Show current provider |
| `/provider horde` | Use AI Horde |
| `/provider gateway` | Use secure backend |
| `/provider auto` | Auto-select provider |
| `/system` | Show system prompt |
| `/system TEXT` | Update system prompt |
| `/status` | Show connection info |
| `/retry` | Retry last request |
| `/save [file]` | Save conversation |
| `/load [file]` | Load conversation |
| `/history` | Show message history |
| `/context` | Show R environment |

### R Programming Integration

```r
# Debug code
rchat_code("
x <- rnorm(100)
hist(x)
")

# Explain code
rchat_explain("
model <- lm(mpg ~ wt, data = mtcars)
summary(model)
")

# Analyze dataset
rchat_data(mtcars)
rchat_data(iris, include_data = TRUE)  # With sample values

# Ask about environment
rchat_env("What data frames do I have loaded?")

# Generate code
rchat("Generate R code for multiple linear regression with diagnostics")
```

### Configuration

```r
# View current config
rchat_config()

# Set defaults
rchat_config(
  provider = "auto",
  model = NULL,
  gateway_url = "https://your-worker.your-subdomain.workers.dev",
  max_tokens = 700,
  timeout = 90,
  history_limit = 50,
  persist_history = TRUE,
  color_output = TRUE
)
```

### Provider Selection

```r
# Auto (tries gateway first, falls back to AI Horde)
rchat_provider("auto")

# AI Horde only (free, no setup)
rchat_provider("horde")

# Secure backend (requires deployment)
rchat_provider("gateway")
```

## Provider Architecture

### AI Horde (Default, Free)

- **No API key required** - uses anonymous access
- **Distributed inference** - community-run workers
- **Dynamic models** - discovers available models at runtime
- **Async processing** - submits jobs, polls for results
- **Limitations**: Queue times vary; not suitable for production SLAs

### Secure Backend Gateway (Optional)

Deploy a Cloudflare Worker to access:
- **NVIDIA Nemotron** - via NVIDIA API (requires authorization)
- **OpenAI-compatible** - any compatible endpoint
- **Rate limiting** - per-IP and global limits
- **Credential isolation** - API keys stored only in Cloudflare secrets

> **Important**: NVIDIA developer/free API access does NOT automatically permit operating a publicly shared multi-user AI service. Verify NVIDIA terms and obtain required authorization before enabling shared NVIDIA inference.

## Backend Deployment (Optional)

For NVIDIA Nemotron and other authenticated providers:

```bash
cd backend
npm install
npx wrangler secret put NVIDIA_API_KEY
npx wrangler deploy
```

Then configure in R:

```r
rchat_config(gateway_url = "https://your-worker.your-subdomain.workers.dev")
rchat_provider("gateway")
```

See [Backend Deployment Guide](backend/README.md) for details.

## Privacy & Security

- **No telemetry** - RConsoleAI collects no usage data
- **Local history** - Conversations saved locally only (opt-in)
- **No secrets in client** - API keys only in backend environment
- **Consent for data** - `rchat_data(include_data = TRUE)` requires explicit consent
- **No code execution** - AI-generated code is never auto-executed

## Limitations

- AI Horde queue times can be 10-60+ seconds
- No streaming support (AI Horde limitation)
- Backend requires Cloudflare account (free tier available)
- NVIDIA Nemotron requires separate authorization for shared use
- Offline use not supported (requires internet for AI Horde)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests: `devtools::test()`
5. Run checks: `devtools::check()`
6. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## Acknowledgments

- [AI Horde](https://aihorde.net/) for free distributed inference
- [NVIDIA](https://build.nvidia.com/) for Nemotron models
- [Cloudflare Workers](https://workers.cloudflare.com/) for serverless backend
- [httr2](https://httr2.r-lib.org/) for HTTP client
- [R6](https://r6.r-lib.org/) for OOP

---

**RConsoleAI** - Making AI assistance native to the R console.