<!--
Thank you for contributing to RConsoleAI!

Please fill out this template to help us review your PR efficiently.
-->

## Description
<!-- Describe your changes in detail -->

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Refactoring / code cleanup
- [ ] Test improvements
- [ ] Backend / infrastructure changes

## Related Issues
<!-- Link to related issues using "Fixes #123" or "Relates to #123" -->
Fixes #

## Changes Made
- 
- 
- 

## Testing
<!-- Describe how you tested your changes -->

### Unit Tests
- [ ] All existing tests pass (`devtools::test()`)
- [ ] New tests added for new functionality

### Manual Testing
- [ ] Tested `rchat()` interactive session
- [ ] Tested `rchat("prompt")` single prompt
- [ ] Tested slash commands (`/help`, `/models`, `/provider`, etc.)
- [ ] Tested R programming functions (`rchat_code`, `rchat_explain`, `rchat_data`, `rchat_env`)
- [ ] Tested provider switching (`rchat_provider()`)
- [ ] Tested configuration (`rchat_config()`)
- [ ] Tested with AI Horde provider
- [ ] Tested with Gateway provider (if applicable)

### Backend Testing (if applicable)
- [ ] TypeScript compiles (`npm run typecheck`)
- [ ] Linting passes (`npm run lint`)
- [ ] Backend tests pass (`npm test`)
- [ ] Deployed to Cloudflare Workers and verified

## Checklist
- [ ] Code follows the project style guide (tidyverse style for R)
- [ ] Self-review of code completed
- [ ] Documentation updated (roxygen2 comments, README, NEWS.md)
- [ ] No new warnings from `devtools::check()`
- [ ] No secrets or credentials committed
- [ ] Backward compatibility maintained (or breaking change documented)
- [ ] Changelog entry added to NEWS.md

## Screenshots / Demo (if applicable)
<!-- Add screenshots or console output showing the feature working -->

## Additional Notes
<!-- Any additional information for reviewers -->