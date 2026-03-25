#!/usr/bin/env bash
# install.sh — bootstrap dependencies for gfunc
# https://github.com/WilliamDavidson-02/gfunc
#
# Usage:
#   ./install.sh              — install required + optional deps
#   ./install.sh --required   — required deps only (git, gh, fzf)
#   ./install.sh --check      — check what is/isn't installed, exit

set -euo pipefail

# ── colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

ok()   { echo -e "  ${GREEN}✔${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}!${RESET}  $*"; }
info() { echo -e "  ${CYAN}→${RESET}  $*"; }
err()  { echo -e "  ${RED}✖${RESET}  $*"; }
header() { echo -e "\n${BOLD}$*${RESET}"; }

# ── flags ─────────────────────────────────────────────────────────────────────
REQUIRED_ONLY=false
CHECK_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --required) REQUIRED_ONLY=true ;;
    --check)    CHECK_ONLY=true ;;
    --help|-h)
      echo ""
      echo "  Usage: ./install.sh [--required] [--check]"
      echo ""
      echo "    (no flags)   Install required + recommended deps"
      echo "    --required   Install required deps only"
      echo "    --check      Check status without installing anything"
      echo ""
      exit 0
      ;;
  esac
done

# ── check: macOS ──────────────────────────────────────────────────────────────
header "gfunc installer"
echo ""

if [[ "$(uname)" != "Darwin" ]]; then
  warn "This installer is designed for macOS."
  warn "On Linux, install: git, gh, fzf, universal-ctags via your package manager."
  exit 1
fi

# ── check: zsh ────────────────────────────────────────────────────────────────
header "Checking shell"
if [[ -n "${ZSH_VERSION:-}" ]]; then
  ok "Running in zsh ${ZSH_VERSION}"
elif command -v zsh &>/dev/null; then
  warn "Not running in zsh (current: ${SHELL})"
  info "zsh is installed at $(command -v zsh) — make sure you source gfunc from .zshrc"
else
  err "zsh not found. Install with: brew install zsh"
fi

# ── check: homebrew ───────────────────────────────────────────────────────────
header "Checking Homebrew"
if ! command -v brew &>/dev/null; then
  err "Homebrew is not installed."
  info "Install it first: https://brew.sh"
  exit 1
else
  ok "Homebrew $(brew --version | head -1)"
fi

[[ "$CHECK_ONLY" == true ]] && header "Dependency status" || header "Installing required dependencies"

# ── helper: install or report a brew package ─────────────────────────────────
install_pkg() {
  local pkg="$1"
  local label="${2:-$pkg}"
  local optional="${3:-false}"

  if command -v "$pkg" &>/dev/null; then
    ok "$label — already installed ($(command -v "$pkg"))"
    return
  fi

  if [[ "$CHECK_ONLY" == true ]]; then
    if [[ "$optional" == true ]]; then
      warn "$label — not installed (optional)"
    else
      err "$label — not installed (required)"
    fi
    return
  fi

  info "Installing $label..."
  if brew install "$pkg"; then
    ok "$label — installed"
  else
    err "Failed to install $label"
    [[ "$optional" == false ]] && exit 1
  fi
}

# ── required ──────────────────────────────────────────────────────────────────
install_pkg "git" "git"
install_pkg "gh"  "GitHub CLI (gh)"
install_pkg "fzf" "fzf"

# ── optional ──────────────────────────────────────────────────────────────────
if [[ "$REQUIRED_ONLY" == false ]]; then
  echo ""
  [[ "$CHECK_ONLY" == true ]] && header "Optional dependencies" || header "Installing optional dependencies"

  # universal-ctags — used by gfunc search --symbol for precise symbol extraction
  # The macOS default 'ctags' (BSD) does not support --_xformat; we need universal-ctags
  if command -v ctags &>/dev/null && ctags --version 2>&1 | grep -qi "universal"; then
    ok "universal-ctags — already installed"
  elif [[ "$CHECK_ONLY" == true ]]; then
    warn "universal-ctags — not installed"
    info "Used by 'gfunc search --symbol' for accurate symbol extraction"
    info "Install with: brew install universal-ctags"
  else
    info "Installing universal-ctags (used by gfunc search --symbol)..."
    if brew install universal-ctags; then
      ok "universal-ctags — installed"
    else
      warn "universal-ctags install failed — gfunc search --symbol will use regex fallback"
    fi
  fi
fi

# ── gh auth check ─────────────────────────────────────────────────────────────
echo ""
header "Checking GitHub CLI auth"
if command -v gh &>/dev/null; then
  if gh auth status &>/dev/null 2>&1; then
    ok "gh is authenticated ($(gh api user --jq '.login' 2>/dev/null || echo 'unknown user'))"
  else
    warn "gh is installed but not authenticated"
    if [[ "$CHECK_ONLY" == false ]]; then
      info "Launching 'gh auth login'..."
      gh auth login
    else
      info "Run: gh auth login"
    fi
  fi
fi

# ── plugin setup hint ─────────────────────────────────────────────────────────
echo ""
header "Plugin setup"

GFUNC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$CHECK_ONLY" == false ]]; then
  echo ""
  info "Add one of the following to your ~/.zshrc:"
  echo ""
  echo "    # Manual source:"
  echo "    source \"${GFUNC_DIR}/gfunc.plugin.zsh\""
  echo ""
  echo "    # Oh My Zsh (after cloning to custom plugins):"
  echo "    plugins=(... gfunc)"
  echo ""
  info "Then reload your shell:"
  echo "    source ~/.zshrc"
fi

echo ""
ok "All done."
echo ""
