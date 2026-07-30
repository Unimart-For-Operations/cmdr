Declarative Git hooks managed by Home Manager

This directory contains helper content for setting up a per-user
`.githooks/` directory that Home Manager will place in the user's
home directory and configure Git to use via `core.hooksPath`.

Approach
- The `programs.git.settings.core.hooksPath` option is set to
  `$HOME/.githooks` in `home/04-modules/cli/graduated/git/default.nix`.
- A lightweight `pre-commit` script is written into `$HOME/.githooks/pre-commit`.
- The script delegates to repo-local checks (for example, `cmdr/scripts/check-theme-lint.sh`).

Notes
- Keep the repo-local scripts in the source tree and ensure they are
  executable; Home Manager will only place the hooks into `$HOME/.githooks`.
- This avoids writing into `.git/hooks` and makes hooks reproducible via Nix.
