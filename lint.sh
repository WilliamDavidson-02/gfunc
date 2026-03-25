#!/usr/bin/env bash
# lint.sh — run shellcheck across all lib files
set -euo pipefail

files=(
  gfunc.plugin.zsh
  lib/helpers.zsh
  lib/clone.zsh
  lib/open.zsh
  lib/prune.zsh
  lib/gone.zsh
  lib/search.zsh
)

echo "Running shellcheck..."
shellcheck --source-path=. "${files[@]}"
echo "All clear."