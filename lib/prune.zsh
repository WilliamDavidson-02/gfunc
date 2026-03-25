# lib/prune.zsh — gfunc prune subcommand

_gfunc_cmd_prune() {
  local cutoff_days label

  case "$1" in
    1w)       cutoff_days=7;   label="1 week"   ;;
    2w)       cutoff_days=14;  label="2 weeks"  ;;
    1m|"")    cutoff_days=30;  label="1 month"  ;;
    3m)       cutoff_days=90;  label="3 months" ;;
    6m)       cutoff_days=180; label="6 months" ;;
    -h|--help)
      cat <<'EOF'

  Usage: gfunc prune [timeframe]

  Preview and delete stale local branches by last-commit age.
  All matching branches are pre-selected — TAB to deselect any to keep.
  Requires typing 'yes' to confirm deletion.

  Timeframes:
    1w    Older than 1 week
    2w    Older than 2 weeks
    1m    Older than 1 month  (default)
    3m    Older than 3 months
    6m    Older than 6 months

  Always skips:
    - Your currently checked-out branch
    - main, master, develop, dev, trunk

  Example:
    gfunc prune
    gfunc prune 3m

EOF
      return ;;
    *)
      echo "Unknown timeframe: '$1'. Use 1w, 2w, 1m, 3m, or 6m."
      return 1
      ;;
  esac

  local current
  current=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  [[ -z "${current}" ]] && echo "Not a git repo." && return 1

  # Compute cutoff epoch — macOS (date -v) vs Linux (date -d)
  local cutoff_epoch
  if date -v -1d +%s &>/dev/null 2>&1; then
    cutoff_epoch=$(date -v -${cutoff_days}d +%s)
  else
    cutoff_epoch=$(date -d "${cutoff_days} days ago" +%s)
  fi

  # Collect stale branches as "YYYY-MM-DD    <branch>" entries
  local entries=()
  while IFS=$'\t' read -r branch epoch datestr; do
    [[ "${branch}" == "${current}" ]]                         && continue
    [[ "${branch}" =~ ^(main|master|develop|dev|trunk)$ ]] && continue
    (( epoch < cutoff_epoch ))                            && entries+=("${datestr}    ${branch}")
  done < <(git for-each-ref \
    --sort=committerdate \
    --format='%(refname:short)%09%(committerdate:unix)%09%(committerdate:short)' \
    refs/heads/)

  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "No local branches with last commit older than ${label}."
    return
  fi

  local selected
  selected=$(printf '%s\n' "${entries[@]}" | \
    fzf --multi \
        --bind 'ctrl-a:select-all,start:select-all' \
        --prompt="Branches to delete> " \
        --header="last-commit  branch | TAB=toggle  CTRL-A=all  ENTER=confirm  ESC=abort" \
        --preview 'git log --oneline --graph -15 "$(echo {} | awk "{print \${NF}}")" 2>/dev/null' \
        --preview-window=right:55%:wrap)

  [[ -z "${selected}" ]] && echo "Nothing selected — aborted." && return

  local to_delete=()
  while IFS= read -r line; do
    to_delete+=("$(echo "${line}" | awk '{print ${NF}}')")
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
