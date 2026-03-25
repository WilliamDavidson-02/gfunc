# lib/clone.zsh — gfunc clone subcommand

_gfunc_cmd_clone() {
  case "$1" in
    -h|--help)
      cat <<'EOF'

  Usage: gfunc clone

  Interactively select a GitHub account and repo to clone.
  After cloning, automatically cd's into the repo directory.

  Steps:
    1. Select an account (your user + any orgs you belong to)
    2. Select a repo from that account

  Preview shows available repos for the selected account.
  Uses SSH cloning: git@github.com:<account>/<repo>.git

EOF
      return ;;
  esac

  local user
  user=$(gh api user --jq '.login')

  # Collect orgs into array first to avoid SC2046 word-splitting on org names
  local -a orgs
  orgs=("${(@f)$(gh api user/orgs --jq '.[].login' 2>/dev/null)}")

  local account
  account=$(printf "%s\n" "${user}" "${orgs[@]}" | \
    fzf --prompt="Select account> " \
        --preview 'gh repo list {} --limit 50 --json name --jq ".[].name" 2>/dev/null' \
        --preview-window=right:50%)

  [[ -z "${account}" ]] && return

  local repo
  repo=$(gh repo list "${account}" --limit 100 --json name --jq '.[].name' | \
    fzf --prompt="Select repo (${account})> " \
        --preview "gh api repos/${account}/{}/readme --jq '.content' 2>/dev/null \
          | base64 -d 2>/dev/null \
          || gh repo view ${account}/{} --json description --jq '.description' 2>/dev/null" \
        --preview-window=right:50%)

  [[ -z "${repo}" ]] && return

  git clone "git@github.com:${account}/${repo}.git" && cd "${repo}" || return 1
}
