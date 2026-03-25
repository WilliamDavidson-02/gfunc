# lib/clone.zsh — gfunc clone subcommand

_gfunc_cmd_clone() {
  local branch_mode=false

  case "$1" in
    -h|--help)
      cat <<'EOF'

  Usage: gfunc clone [-b]

  Interactively select a GitHub account and repo to clone.
  After cloning, automatically cd's into the repo directory.

  Steps (without -b):
    1. Select an account (your user + any orgs you belong to)
    2. Select a repo from that account

  Steps (with -b):
    1. Select an account
    2. Select a repo
    3. Multi-select branches to track locally
       TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=abort
       Checks out the first selected branch after cloning.

  Flags:
    -b    After selecting a repo, pick which remote branches to track

  Examples:
    gfunc clone
    gfunc clone -b

EOF
      return ;;
    -b)
      branch_mode=true
      ;;
  esac

  # ── step 1: select account ─────────────────────────────────────────────────
  local user
  user=$(gh api user --jq '.login')

  # Collect orgs into array first to avoid word-splitting on org names
  local -a orgs
  orgs=("${(@f)$(gh api user/orgs --jq '.[].login' 2>/dev/null)}")

  local step_total
  step_total="${branch_mode:+3}${branch_mode:-2}"

  local account
  account=$(printf "%s\n" "${user}" "${orgs[@]}" | \
    fzf --prompt="Step 1/${step_total}  Select account> " \
        --header="ENTER=select  ESC=abort" \
        --preview 'gh repo list {} --limit 50 --json name --jq ".[].name" 2>/dev/null' \
        --preview-window=right:50%)

  [[ -z "${account}" ]] && echo "  Aborted." && return

  # ── step 2: select repo ────────────────────────────────────────────────────
  local repo
  repo=$(gh repo list "${account}" --limit 100 --json name --jq '.[].name' | \
    fzf --prompt="Step 2/${step_total}  Select repo (${account})> " \
        --header="ENTER=select  ESC=abort" \
        --preview "gh api repos/${account}/{}/readme --jq '.content' 2>/dev/null \
          | base64 -d 2>/dev/null \
          || gh repo view ${account}/{} --json description --jq '.description' 2>/dev/null" \
        --preview-window=right:50%)

  [[ -z "${repo}" ]] && echo "  Aborted." && return

  # ── step 3: select branches (only with -b) ─────────────────────────────────
  local -a selected_branches

  if [[ "${branch_mode}" == true ]]; then
    echo "  Fetching remote branch list for ${account}/${repo}..."

    local branch_list
    branch_list=$(gh api "repos/${account}/${repo}/branches" \
      --paginate --jq '.[].name' 2>/dev/null)

    if [[ -z "${branch_list}" ]]; then
      echo "  Could not fetch branch list — cloning default branch only."
    else
      local selected_raw
      selected_raw=$(echo "${branch_list}" | \
        fzf --multi \
            --prompt="Step 3/3  Select branches> " \
            --header="TAB=toggle  CTRL-A=select all  ENTER=confirm  ESC=abort" \
            --preview "gh api repos/${account}/${repo}/commits?sha={} \
              --jq '.[0:5] | .[] | \"\(.sha[0:7])  \(.commit.message | split(\"\n\")[0])\"' \
              2>/dev/null" \
            --preview-window=right:50%:wrap)

      [[ -z "${selected_raw}" ]] && echo "  Aborted." && return

      selected_branches=("${(@f)${selected_raw}}")
    fi
  fi

  # ── clone ──────────────────────────────────────────────────────────────────
  echo ""
  echo "  Cloning ${account}/${repo}..."
  git clone "git@github.com:${account}/${repo}.git" || return 1
  cd "${repo}" || return 1

  if [[ "${branch_mode}" == true && ${#selected_branches[@]} -gt 0 ]]; then
    echo "  Setting up ${#selected_branches[@]} branch(es)..."

    local first_branch="${selected_branches[1]}"
    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
      | sed 's|refs/remotes/origin/||')

    for branch in "${selected_branches[@]}"; do
      if [[ "${branch}" == "${default_branch}" ]]; then
        echo "  Already on default: ${branch}"
        continue
      fi
      if git fetch origin "${branch}:${branch}" 2>/dev/null; then
        echo "  Fetched: ${branch}"
      else
        echo "  Failed:  ${branch}"
      fi
    done

    # Check out the first selected branch unless it is the default
    if [[ "${first_branch}" != "${default_branch}" ]]; then
      echo ""
      echo "  Checking out ${first_branch}..."
      git checkout "${first_branch}" 2>/dev/null \
        || git checkout -b "${first_branch}" --track "origin/${first_branch}"
    else
      echo ""
      echo "  Staying on default branch: ${default_branch}"
    fi
  fi

  echo ""
  echo "  Done — $(pwd)"
}