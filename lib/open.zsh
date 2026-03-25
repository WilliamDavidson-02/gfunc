# lib/open.zsh — gfunc open subcommand
# Depends on: _gfunc_base_url (lib/helpers.zsh)

_gfunc_cmd_open() {
  local base_url
  base_url=$(_gfunc_base_url) || {
    echo "Not a git repo or no origin remote."
    return 1
  }

  case "$1" in
    -h|--help)
      cat <<'EOF'

  Usage: gfunc open [flag]

  Open the current repo on GitHub in your browser.

  Flags:
    -b      Open the current branch
    -pr     Open the open PR for the current branch
    (none)  Open the repo root

  Examples:
    gfunc open
    gfunc open -b
    gfunc open -pr

EOF
      return ;;
    -b)
      local branch
      branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
      echo "Opening branch ${branch}"
      open "${base_url}/tree/${branch}"
      ;;
    -pr)
      local pr
      pr=$(gh pr view --json url --jq '.url' 2>/dev/null)
      if [[ -z "${pr}" ]]; then
        echo "No open PR found for branch $(git rev-parse --abbrev-ref HEAD)"
        return 1
      fi
      echo "Opening PR ${pr}"
      open "${pr}"
      ;;
    *)
      echo "Opening ${base_url}"
      open "${base_url}"
      ;;
  esac
}
