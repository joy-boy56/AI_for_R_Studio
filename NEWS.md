# NEWS.md

## RConsoleAI 0.1.0 (Development)

### New Features

- **Interactive Chat Interface** (`rchat()`): Full-featured REPL with slash commands
- **Single-Prompt Mode**: `rchat("question")` for quick queries
- **AI Horde Provider**: Free, anonymous access to distributed AI inference
- **Secure Backend Gateway**: Cloudflare Workers for authenticated providers
- **Provider Auto-Selection**: Tries gateway first, falls back to AI Horde
- **Slash Commands**: `/help`, `/models`, `/model`, `/provider`, `/system`, `/status`, `/retry`, `/save`, `/load`, `/history`, `/context`
- **Conversation Management**: Persistent history, export/import, configurable limits
- **R Programming Integration**:
  - `rchat_code()` - Code debugging and review
  - `rchat_explain()` - Code explanation
  - `rchat_data()` - Dataset analysis with visualization suggestions
  - `rchat_env()` - R environment inspection
  - `rchat_generate()` - Code generation
- **Model Discovery**: Dynamic model listing with worker availability
- **Configuration System**: `rchat_config()` with persistent options
- **R Context Helper**: Safe environment inspection with consent

### Provider Architecture

- Modular provider system with `ProviderBase` abstract class
- `AIHordeProvider`: Async job submission, polling, model discovery
- `GatewayProvider`: REST API to Cloudflare Workers backend
- Extensible for future providers

### Backend (Cloudflare Workers)

- Request validation and sanitization
- Rate limiting (per-IP and global)
- CORS configuration
- Provider adapters: NVIDIA Nemotron, OpenAI-compatible
- Server-side credential storage via Cloudflare secrets
- Health check endpoint

### Testing

- Unit tests for all core components
- Mocked API responses for provider tests
- testthat 3rd edition
- CI/CD via GitHub Actions

### Documentation

- Comprehensive README with examples
- MIT License
- Contributing guidelines
- Security policy
- Inline roxygen2 documentation

---

## Template for Future Releases

## RConsoleAI X.Y.Z (YYYY-MM-DD)

### New Features

- Feature description

### Bug Fixes

- Fix description

### Breaking Changes

- Change description

### Deprecations

- Deprecation notice

### Internal

- Refactoring, test improvements, etc.