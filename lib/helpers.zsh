# lib/helpers.zsh — shared helpers for gfunc
# Sourced by gfunc.plugin.zsh — do not source directly

# ── _gfunc_base_url ───────────────────────────────────────────────────────────
# Resolves the GitHub HTTPS base URL from the current repo's origin remote.
# Handles both standard SSH (git@github.com:) and private SSH host aliases
# (e.g. git@github-work: or git@private.github.com:) as well as HTTPS remotes.
#
# Output: https://github.com/<owner>/<repo>  (no trailing slash, no .git)
# Returns 1 if no origin remote is found.
_gfunc_base_url() {
  local remote
  remote=$(git remote get-url origin 2>/dev/null)
  [[ -z "${remote}" ]] && return 1
  echo "${remote}" | sed \
    -e 's|^git@[^:]*:|https://github.com/|' \
    -e 's|^https://[^/]*/|https://github.com/|' \
    -e 's|\.git$||'
}

# ── _gfunc_open_commit ────────────────────────────────────────────────────────
# Opens a specific commit SHA in the browser.
# Usage: _gfunc_open_commit <sha>
_gfunc_open_commit() {
  local sha="$1"
  local base_url
  base_url=$(_gfunc_base_url) || {
    echo "  Not a git repo or no origin remote."
    return 1
  }
  local url="${base_url}/commit/${sha}"
  echo "  Opening ${url}"
  open "${url}"
}

# ── _gfunc_resolve_branch ─────────────────────────────────────────────────────
# Resolves which git ref to pass to git log based on the -b flag:
#   ""           → "--all"  (no -b flag given)
#   " "          → remote tracking branch of current branch, or "--all" as fallback
#   "develop"    → "origin/develop"
#
# Usage: _gfunc_resolve_branch "${branch_arg}"
# Output: a ref string safe to pass directly to git log
_gfunc_resolve_branch() {
  local branch_arg="$1"
  if [[ -n "${branch_arg}" ]]; then
    echo "origin/${branch_arg}"
  else
    local tracking
    tracking=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
    if [[ -n "${tracking}" ]]; then
      echo "${tracking}"
    else
      echo "--all"
    fi
  fi
}

# ── _gfunc_check_deps ─────────────────────────────────────────────────────────
# Checks for required dependencies at plugin load time.
# Warns if anything is missing — does not abort shell startup.
_gfunc_check_deps() {
  local missing=()
  command -v git &>/dev/null || missing+=("git")
  command -v gh  &>/dev/null || missing+=("gh")
  command -v fzf &>/dev/null || missing+=("fzf")
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "[gfunc] missing required dependencies: ${missing[*]}"
    echo "[gfunc] install with: brew install ${missing[*]}"
    echo "[gfunc] or run: \$(dirname \$0)/install.sh"
    return 1
  fi
}
