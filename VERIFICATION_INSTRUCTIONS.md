# RConsoleAI - Local Verification Instructions

## Prerequisites

Before running verification, ensure you have:

1. **R >= 4.1.0** installed
2. **RStudio** (recommended) or terminal
3. **Git** for cloning
4. **Internet connection** (for AI Horde and package installation)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/rconsoleai.git
cd rconsoleai

# Open in RStudio (recommended)
# File > Open Project > rconsoleai.Rproj
```

## Install Development Dependencies

```r
# In R console
install.packages(c(
  "devtools",
  "roxygen2",
  "testthat",
  "knitr",
  "rmarkdown",
  "httr2",
  "jsonlite",
  "R6"
))
```

## Run Verification Steps

### 1. Load Package in Development Mode

```r
devtools::load_all(".")
```

This loads the package without installing, useful for quick iteration.

### 2. Generate Documentation

```r
devtools::document()
```

This runs `roxygen2` to:
- Generate `NAMESPACE` file
- Create `.Rd` man pages in `man/`
- Update `DESCRIPTION` if needed

**Expected output:** No errors. Man pages created in `man/`.

### 3. Run Tests

```r
devtools::test()
```

This runs all testthat tests in `tests/testthat/`.

**Expected output:** All tests pass (green). Some tests may be skipped if offline.

### 4. Run Full Package Check

```r
devtools::check()
```

This runs `R CMD check` - the gold standard for R package validation.

**Expected output:** 
- 0 errors
- 0 warnings (ideally)
- 0 notes (or only acceptable notes)

Common acceptable notes:
- "No manual found" (we don't have a PDF manual)
- "Checking CRAN incoming feasibility" (not submitting to CRAN yet)

### 5. Build Package

```r
devtools::build()
```

Creates `rconsoleai_0.1.0.tar.gz` in parent directory.

### 6. Install and Test

```r
# Install the built package
install.packages("../rconsoleai_0.1.0.tar.gz", repos = NULL, type = "source")

# Test basic functionality
library(rconsoleai)
rchat_config()  # Should show defaults
rchat_provider()  # Should show "auto"
```

## Test Interactive Chat (Manual)

```r
# This starts interactive session - test manually
rchat()
# Type: /help
# Type: Explain pnorm in R
# Type: /exit
```

## Test Single Prompt

```r
rchat("What is the mean of 1:10?")
```

## Test R Programming Functions

```r
# Code debugging
rchat_code("x <- rnorm(100); hist(x)")

# Code explanation
rchat_explain("model <- lm(mpg ~ wt, data = mtcars); summary(model)")

# Dataset analysis
rchat_data(mtcars)

# Environment query
rchat_env("What data frames do I have?")
```

## Test Provider Switching

```r
# Check available providers
list_providers()

# Switch to AI Horde explicitly
rchat_provider("horde")
rchat_models("horde")

# Switch to auto
rchat_provider("auto")
```

## Backend Verification (Optional)

If you've deployed the Cloudflare Workers backend:

```bash
cd backend
npm install
npm run typecheck
npm run lint
npm test
```

### Deploy Backend

```bash
cd backend
npx wrangler login
npx wrangler secret put NVIDIA_API_KEY
npx wrangler secret put OPENAI_API_KEY
npx wrangler deploy
```

### Configure R Package for Gateway

```r
rchat_config(gateway_url = "https://your-worker.your-subdomain.workers.dev")
rchat_provider("gateway")
rchat_models("gateway")
rchat("Test gateway")
```

## Common Issues & Fixes

### "Package 'httr2' not available"
```r
install.packages("httr2")
```

### Tests fail due to no internet
```r
# Tests with skip_if_offline() will be skipped
# This is expected behavior
```

### devtools::check() shows warnings
- Check `check/` directory for details
- Most warnings are about missing manual or CRAN checks
- Fix any real code issues

### Roxygen2 warnings
```r
# Re-run document
devtools::document()
# Check man/ files generated correctly
```

## GitHub Actions Verification

The CI/CD runs automatically on push/PR:
- `.github/workflows/R-CMD-check.yaml` - Runs on Ubuntu, macOS, Windows
- `.github/workflows/deploy-backend.yaml` - Deploys backend on backend changes

Check status at: `https://github.com/yourusername/rconsoleai/actions`

## Publishing to GitHub

```bash
# 1. Ensure all checks pass locally
devtools::check()

# 2. Update version in DESCRIPTION if needed
# Version: 0.1.0 -> 0.1.1

# 3. Update NEWS.md

# 4. Commit and push
git add .
git commit -m "Release v0.1.0"
git tag v0.1.0
git push origin main --tags

# 5. GitHub Actions will run checks automatically
# 6. Create GitHub Release from tag
```

## Publishing to CRAN (Future)

```r
# 1. Ensure devtools::check() has 0 errors, 0 warnings, 0 notes
devtools::check(cran = TRUE)

# 2. Build for CRAN
devtools::build(cran = TRUE)

# 3. Submit via CRAN web form
# https://cran.r-project.org/submit.html
```

## File Structure Summary

```
RConsoleAI/
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Exported functions (auto-generated)
├── LICENSE                     # MIT License
├── README.md                   # Main documentation
├── CONTRIBUTING.md             # Contribution guide
├── SECURITY.md                 # Security policy
├── NEWS.md                     # Changelog
├── .gitignore                  # Git ignore rules
├── .Rbuildignore               # Build ignore
├── R/                          # R source code
│   ├── options.R               # Configuration options
│   ├── providers.R             # Provider base classes
│   ├── horde_provider.R        # AI Horde provider
│   ├── gateway_provider.R      # Gateway provider
│   ├── provider_manager.R      # Provider management
│   ├── conversation.R          # Conversation class
│   ├── r_context.R             # R environment inspection
│   ├── rchat.R                 # Main chat interface
│   └── r_programming.R         # R integration functions
├── man/                        # Generated documentation (after document())
├── tests/
│   ├── testthat.R              # Test config
│   └── testthat/
│       ├── helper.R            # Test helpers
│       ├── test-options.R
│       ├── test-conversation.R
│       ├── test-providers.R
│       ├── test-provider_manager.R
│       ├── test-r_context.R
│       ├── test-rchat.R
│       └── test-r_programming.R
├── vignettes/
│   ├── getting-started.Rmd
│   ├── provider-guide.Rmd
│   ├── backend-deployment.Rmd
│   └── troubleshooting.Rmd
├── backend/
│   ├── package.json
│   ├── tsconfig.json
│   ├── wrangler.toml
│   ├── README.md
│   └── src/
│       ├── index.ts
│       ├── router.ts
│       ├── providers/
│       │   ├── nvidia.ts
│       │   └── openai-compatible.ts
│       └── middleware/
│           ├── rate-limit.ts
│           ├── validation.ts
│           └── error-handler.ts
└── .github/
    ├── workflows/
    │   ├── R-CMD-check.yaml
    │   └── deploy-backend.yaml
    ├── ISSUE_TEMPLATE/
    │   ├── bug_report.md
    │   ├── feature_request.md
    │   └── provider_issue.md
    └── pull_request_template.md
```

## Features Implemented

✅ **Core Chat Interface**
- Interactive `rchat()` session with slash commands
- Single prompt `rchat("question")`
- Provider switching (`horde`, `gateway`, `auto`)

✅ **Slash Commands**
- `/help`, `/exit`, `/clear`, `/models`, `/model`, `/provider`
- `/system`, `/status`, `/retry`, `/save`, `/load`
- `/history`, `/context`

✅ **Provider Architecture**
- AI Horde (free, anonymous, default)
- Secure Gateway (NVIDIA, OpenAI-compatible)
- Auto-selection with fallback

✅ **R Programming Integration**
- `rchat_code()` - Debug code
- `rchat_explain()` - Explain code
- `rchat_data()` - Analyze datasets
- `rchat_env()` - Query environment
- `rchat_generate()` - Generate code

✅ **Conversation Management**
- Persistent history across sessions
- Export/import conversations
- Configurable history limits

✅ **Backend (Cloudflare Workers)**
- Request validation
- Rate limiting (per-IP + global)
- NVIDIA Nemotron provider
- OpenAI-compatible provider
- CORS support
- Health checks

✅ **Documentation**
- Comprehensive README
- Getting started vignette
- Provider guide vignette
- Backend deployment vignette
- Troubleshooting vignette
- Contributing guide
- Security policy

✅ **Testing**
- Unit tests for all core components
- Mocked API responses
- testthat 3rd edition

✅ **CI/CD**
- GitHub Actions for R package checks (3 OS)
- GitHub Actions for backend deployment
- Issue templates
- PR template

## Known Limitations

1. **AI Horde queue times**: 10-60+ seconds
2. **No streaming**: AI Horde doesn't support streaming
3. **NVIDIA shared use**: Requires authorization for multi-user
4. **Offline not supported**: Requires internet
5. **Colors on Windows**: Best in RStudio/Windows Terminal
6. **Context window**: Limited by provider (4k-8k tokens)

## Next Steps for User

1. **Run verification locally**: `devtools::document()`, `devtools::test()`, `devtools::check()`
2. **Fix any issues** that arise
3. **Deploy backend** if you want NVIDIA/OpenAI providers
4. **Test interactively** with `rchat()`
5. **Push to GitHub** and enable Actions
6. **Create release** when satisfied

---

**Need help?** Check the troubleshooting vignette or open an issue on GitHub.