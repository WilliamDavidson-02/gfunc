# lib/gone.zsh — gfunc gone subcommand

_gfunc_cmd_gone() {
  case "$1" in
    -h|--help)
      cat <<'EOF'

  Usage: gfunc gone

  Find and delete local branches whose remote tracking branch has been
  deleted — typically branches merged via PR on GitHub.

  How it works:
    1. Runs git fetch --prune to sync remote state
    2. Finds local branches marked as 'gone' (remote deleted)
    3. Shows them in fzf — all pre-selected, TAB to deselect any to keep
    4. Requires typing 'yes' to confirm deletion

  Always skips your currently checked-out branch.

EOF
      return ;;
  esac

  local current
  current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [[ -z "${current}" ]] && echo "Not a git repo." && return 1

  echo "  Fetching and pruning remote refs..."
  git fetch --prune

  # Find branches whose upstream tracking ref is marked as gone
  local entries=()
  while IFS= read -r line; do
    local branch
    branch=$(echo "${line}" | awk '{print $1}' | sed 's/^\*//')
    [[ -z "${branch}" ]]            && continue
    [[ "${branch}" == "${current}" ]] && continue
    entries+=("${branch}")
  done < <(git branch -vv | grep ': gone]' | awk '{$1=$1; print}')

  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "  No branches with a deleted remote tracking branch."
    return
  fi

  local selected
  selected=$(printf '%s\n' "${entries[@]}" | \
    fzf --multi \
        --bind 'ctrl-a:select-all,start:select-all' \
        --prompt="Branches to delete (remote gone)> " \
        --header="TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=abort" \
        --preview 'git log --oneline --graph -15 {} 2>/dev/null' \
        --preview-window=right:55%:wrap)

  [[ -z "${selected}" ]] && echo "  Nothing selected — aborted." && return

  local to_delete=()
  while IFS= read -r branch; do
    to_delete+=("${branch}")
  done <<< "${selected}"

  echo ""
  echo "  About to delete ${#to_delete[@]} branch(es):"
  printf '    ✖  %s\n' "${to_delete[@]}"
  echo ""
  printf "  Type 'yes' to confirm: "
  local confirm
  read -r confirm

  if [[ "${confirm}" == "yes" ]]; then
    local deleted=0 failed=0
    for branch in "${to_delete[@]}"; do
      if git branch -d "${branch}" 2>/dev/null || git branch -D "${branch}" 2>/dev/null; then
        echo "  Deleted: ${branch}"
        (( deleted++ ))
      else
        echo "  Failed:  ${branch}"
        (( failed++ ))
      fi
    done
    echo ""
    echo "  Done — ${deleted} deleted, ${failed} failed."
  else
    echo "  Aborted."
  fi
}
