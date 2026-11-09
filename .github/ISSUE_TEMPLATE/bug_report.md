---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description
A clear and concise description of what the bug is.

## To Reproduce
Steps to reproduce the behavior:
1. Run `library(rconsoleai)`
2. Execute `rchat("...")`
3. See error

## Expected Behavior
A clear and concise description of what you expected to happen.

## Actual Behavior
What actually happened. Include error messages, stack traces, etc.

```r
# Paste your code here
# Include any error output
```

## Environment
- **R Version**: (run `R.version.string`)
- **OS**: (e.g., Windows 11, macOS 14, Ubuntu 22.04)
- **RStudio Version** (if applicable): 
- **rconsoleai Version**: (run `packageVersion("rconsoleai")`)
- **Provider Used**: (horde / gateway / auto)

## Provider Details (if applicable)
- **AI Horde**: Model name, queue time
- **Gateway**: Backend URL, provider (nvidia/openai-compatible)

## Additional Context
Add any other context about the problem here:
- Screenshots if applicable
- Log output
- Configuration used (`rchat_config()`)

## Checklist
- [ ] I have searched existing issues for duplicates
- [ ] I have provided a minimal reproducible example
- [ ] I have included all relevant environment information
- [ ] I have checked the troubleshooting guide in README