# gfunc.plugin.zsh — GitHub CLI helper functions for zsh
# https://github.com/WilliamDavidson-02/gfunc
 
# ── zsh guard ─────────────────────────────────────────────────────────────────
if [[ -z "${ZSH_VERSION}" ]]; then
  echo "[gfunc] requires zsh. Current shell: ${SHELL}"
  return 1 2>/dev/null || exit 1
fi
 
# ── source lib files ──────────────────────────────────────────────────────────
# GFUNC_DIR resolves to this file's directory regardless of how it is sourced
0="${ZERO:-${(%):-%N}}"
typeset -g GFUNC_DIR="${0:A:h}"
 
source "${GFUNC_DIR}/lib/helpers.zsh"
source "${GFUNC_DIR}/lib/clone.zsh"
source "${GFUNC_DIR}/lib/open.zsh"
source "${GFUNC_DIR}/lib/prune.zsh"
source "${GFUNC_DIR}/lib/gone.zsh"
source "${GFUNC_DIR}/lib/search.zsh"
 
# ── dependency check at load time ─────────────────────────────────────────────
_gfunc_check_deps
 
# ── main dispatcher ───────────────────────────────────────────────────────────
gfunc() {
  case "$1" in
    clone)
      shift
      _gfunc_cmd_clone "$@"
      ;;
    open)
      shift
      _gfunc_cmd_open "$@"
      ;;
    prune)
      shift
      _gfunc_cmd_prune "$@"
      ;;
    gone)
      shift
      _gfunc_cmd_gone "$@"
      ;;
    search)
      shift
      _gfunc_cmd_search "$@"
      ;;
    -h|--help|help|"")
      cat <<'EOF'
 
  gfunc — GitHub helper functions
 
  Commands:
    clone             Clone a repo interactively via fzf
    open              Open the current repo on GitHub
    prune [timeframe] Delete stale local branches by age
    gone              Delete branches whose remote has been removed
    search <mode>     Search commit history and open in browser
 
  Run 'gfunc <command> --help' for detailed usage.
 
EOF
      ;;
    *)
      echo "Unknown subcommand: $1"
      echo "Usage: gfunc <clone|open|prune|gone|search>"
      echo "Run 'gfunc help' for a list of commands."
      return 1
      ;;
  esac
}