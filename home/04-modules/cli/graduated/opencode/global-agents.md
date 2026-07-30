# Global Preferences

Personal preferences that apply across all projects.

## Commit Style

- Conventional commits: `feat(scope):`, `fix:`, `docs:`, `refactor:`, `chore:`
- DCO sign-off required: always use `git commit -s`
- Keep subject line under 72 characters
- Write imperative mood ("add feature" not "added feature")

## Code Style

- Prefer clarity over cleverness
- Comments explain *why*, not *what*
- Keep functions short and focused
- Follow each project's existing patterns and conventions

## Shell Scripts

- Shebang: `#!/usr/bin/env bash`
- Strict mode: `set -euo pipefail`
- Quote all variables: `"${variable}"`
- Use `local` for function variables

## Documentation

- Write concise docs — avoid unnecessary verbosity
- Use relative links between docs files
- Keep README files as entry points, not exhaustive references
