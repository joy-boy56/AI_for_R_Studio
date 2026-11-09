# Contributing to RConsoleAI

Thank you for your interest in contributing to RConsoleAI! This document provides guidelines for contributing to the project.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:
- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect differing viewpoints and experiences

## How to Contribute

### Reporting Bugs

1. Check [existing issues](https://github.com/yourusername/rconsoleai/issues) first
2. Create a new issue with:
   - Clear, descriptive title
   - Steps to reproduce
   - Expected vs actual behavior
   - R version, OS, package version
   - Minimal reproducible example

### Suggesting Features

1. Check existing issues and discussions
2. Create a feature request issue with:
   - Clear description of the feature
   - Use cases and motivation
   - Possible implementation approach

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature-name`
3. Make your changes
4. Ensure tests pass: `devtools::test()`
5. Ensure checks pass: `devtools::check()`
6. Update documentation if needed
7. Submit a pull request

## Development Setup

```r
# Clone your fork
git clone https://github.com/YOUR_USERNAME/rconsoleai.git
cd rconsoleai

# Install development dependencies
install.packages(c("devtools", "roxygen2", "testthat", "knitr", "rmarkdown"))

# Load package in development mode
devtools::load_all(".")

# Run tests
devtools::test()

# Run full checks
devtools::check()

# Build documentation
devtools::document()
```

## Coding Standards

### R Code Style

- Follow the [tidyverse style guide](https://style.tidyverse.org/)
- Use `roxygen2` for all exported functions
- Maximum line length: 100 characters
- Use 2-space indentation
- Prefer `<-` for assignment

### Documentation

- Every exported function must have roxygen2 documentation
- Include `@examples` with `\dontrun{}` for interactive examples
- Update README.md for user-facing changes
- Update NEWS.md for notable changes

### Testing

- Write tests for new functionality
- Use `testthat` 3rd edition
- Mock external API calls
- Test error conditions
- Aim for >80% coverage

### Git Commits

- Use conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`
- Keep commits focused and atomic
- Reference issues: `fix: resolve timeout issue (#123)`

## Provider Development

When adding new AI providers:

1. Create new provider class inheriting from `ProviderBase`
2. Implement required methods: `fetch_models()`, `chat()`, `is_available()`
3. Register in `ProviderManager$initialize()`
4. Add tests with mocked API responses
5. Document in README.md

## Backend Development

For Cloudflare Worker changes:

```bash
cd backend
npm install
npm run dev  # Local development
npm run deploy  # Deploy to Cloudflare
```

- Follow TypeScript best practices
- Add request validation
- Implement rate limiting
- Never log sensitive data

## Release Process

1. Update version in `DESCRIPTION`
2. Update `NEWS.md`
3. Create release tag
4. GitHub Actions builds and publishes

## Questions?

Open a [discussion](https://github.com/yourusername/rconsoleai/discussions) or [issue](https://github.com/yourusername/rconsoleai/issues).

Thank you for contributing!