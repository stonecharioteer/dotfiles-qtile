#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
cd "$repo_root"

chmod +x .githooks/pre-commit .githooks/commit-msg
git config core.hooksPath .githooks

printf 'Git hooks installed. core.hooksPath=.githooks\n'
printf 'Hooks enabled:\n'
printf '  - pre-commit: ruff, prettier, shellcheck\n'
printf '  - commit-msg: conventional commit validation\n'
