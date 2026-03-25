# lib/search.zsh — gfunc search subcommand
# Depends on: _gfunc_base_url, _gfunc_open_commit, _gfunc_resolve_branch (lib/helpers.zsh)

# ── _gfunc_extract_symbols ────────────────────────────────────────────────────
# Extracts function and type definitions from a source file.
# Outputs lines of "KIND\tNAME\tLINENUM" where KIND is "func" or "type".
#
# Uses universal-ctags if available (most accurate, language-aware).
# Falls back to anchored BOL regex per file extension — for-loops, if-blocks
# and call sites are excluded by requiring a declaration keyword at line start.
#
# Usage: _gfunc_extract_symbols <filepath>
_gfunc_extract_symbols() {
  local file="$1"
  local ext="${file##*.}"

  if command -v ctags &>/dev/null; then
    ctags -x --_xformat="%{kind}	%N	%n" "${file}" 2>/dev/null | \
      awk -F'\t' '{
        k = $1
        if (k ~ /^(function|method|arrow|f|constant|variable|v)$/) kind = "func"
        else if (k ~ /^(class|type|interface|struct|enum|alias|t|c|i|e|g)$/) kind = "type"
        else next
        printf "%s\t%s\t%s\n", kind, $2, $3
      }'
    return
  fi

  # ── regex fallback — anchored to BOL, keyed by file extension ─────────────
  case "${ext}" in
    ts|tsx)
      grep -En \
        '^(export[[:space:]]+)?(default[[:space:]]+)?(async[[:space:]]+)?function[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*function[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/func\t\2\t\1/"
      grep -En \
        '^(export[[:space:]]+)?(const|let)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*(async[[:space:]]*)?\(' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*\b(const|let)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=.*/func\t\3\t\1/"
      grep -En \
        '^(export[[:space:]]+)?(type|interface|class|enum|abstract[[:space:]]+class)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*\b(type|interface|class|enum|abstract class)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/type\t\3\t\1/"
      ;;
    js|jsx|mjs|cjs)
      grep -En \
        '^(export[[:space:]]+)?(default[[:space:]]+)?(async[[:space:]]+)?function[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*function[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/func\t\2\t\1/"
      grep -En \
        '^(export[[:space:]]+)?(const|let)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=[[:space:]]*(async[[:space:]]*)?\(' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*\b(const|let)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=.*/func\t\3\t\1/"
      grep -En \
        '^(export[[:space:]]+)?(class)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*(class)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/type\t\3\t\1/"
      ;;
    py)
      grep -En \
        '^(async[[:space:]]+)?def[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*def[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/func\t\2\t\1/"
      grep -En \
        '^class[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*class[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/type\t\2\t\1/"
      ;;
    go)
      grep -En \
        '^func[[:space:]]+(\([^)]+\)[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):func[[:space:]]+(\([^)]+\)[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*).*/func\t\3\t\1/"
      grep -En \
        '^type[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]+(struct|interface|[A-Za-z])' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):type[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/type\t\2\t\1/"
      ;;
    rs)
      grep -En \
        '^[[:space:]]*(pub[[:space:]]+)?(async[[:space:]]+)?fn[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):[[:space:]]*(pub[[:space:]]+)?(async[[:space:]]+)?fn[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/func\t\4\t\1/"
      grep -En \
        '^[[:space:]]*(pub[[:space:]]+)?(struct|enum|type|trait)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):[[:space:]]*(pub[[:space:]]+)?(struct|enum|type|trait)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/type\t\4\t\1/"
      ;;
    rb)
      grep -En \
        '^[[:space:]]*(def)[[:space:]]+[A-Za-z_][A-Za-z0-9_?!]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):[[:space:]]*def[[:space:]]+([A-Za-z_][A-Za-z0-9_?!]*).*/func\t\2\t\1/"
      grep -En \
        '^(class|module)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*(class|module)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/type\t\3\t\1/"
      ;;
    *)
      grep -En \
        '^(function|def|fn|func)[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
        "${file}" 2>/dev/null | \
        sed -E "s/^([0-9]+):.*(function|def|fn|func)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*/func\t\3\t\1/"
      ;;
  esac
}

# ── _gfunc_cmd_search ─────────────────────────────────────────────────────────
_gfunc_cmd_search() {
  local mode="" author="" branch_arg="" branch_ref="" branch_set=false

  # ── parse flags ─────────────────────────────────────────────────────────────
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --latest-file)        mode="file";    shift ;;
      --symbol|--function)  mode="symbol";  shift ;;
      --message)            mode="message"; shift ;;
      -a|--author)          author="$2";    shift 2 ;;
      -b|--branch)
        branch_set=true
        if [[ -n "$2" && "$2" != -* ]]; then
          branch_arg="$2"; shift 2
        else
          branch_arg=""; shift
        fi
        ;;
      -h|--help|"")
        cat <<'EOF'

  Usage: gfunc search <mode> [options]

  Modes:
    --latest-file     Fuzzy search all tracked files.
                      Preview shows last 10 commits per file.
                      Opens the latest commit for the selected file.

    --symbol          Step 1: pick a file.
                      Step 2: pick a func or type definition.
                      Opens the latest commit that touched the symbol.
                      (--function is a backwards-compat alias)

    --message         Live search by commit message keyword.
                      List updates as you type via git log --grep.
                      Preview shows full git show --stat per commit.

  Options:
    -a, --author <n>     Filter by author (combines with any mode)

    -b, --branch [name]  Branch scope:
                         omit flag entirely  → all remote branches
                         -b (no name)        → remote of current branch
                         -b develop          → origin/develop

  Examples:
    gfunc search --message
    gfunc search --message -b develop
    gfunc search --message -b -a <author>
    gfunc search --latest-file -b main
    gfunc search --symbol -b main

EOF
        return ;;
      *)
        echo "  Unknown flag: $1"
        return 1
        ;;
    esac
  done

  if [[ -z "${mode}" ]]; then
    echo "  Specify a mode: --latest-file, --symbol, or --message"
    echo "  Run 'gfunc search --help' for usage."
    return 1
  fi

  git rev-parse --git-dir &>/dev/null || { echo "  Not a git repo."; return 1; }

  echo "  Fetching remote refs..."
  git fetch --all --quiet 2>/dev/null

  # Resolve branch ref once — reused across all modes
  if [[ "${branch_set}" == true ]]; then
    branch_ref=$(_gfunc_resolve_branch "${branch_arg}")
  else
    branch_ref="--all"
  fi

  # Validate named branch exists on remote
  if [[ "${branch_ref}" != "--all" ]]; then
    git rev-parse --verify "${branch_ref}" &>/dev/null || {
      echo "  Branch not found: ${branch_ref}"
      echo "  Available remote branches:"
      git branch -r | sed 's|origin/||' | grep -v HEAD | awk '{print "    " $1}'
      return 1
    }
    echo "  Searching in: ${branch_ref}"
  else
    echo "  Searching in: all remote branches"
  fi
  echo ""

  # ── mode: latest-file ───────────────────────────────────────────────────────
  if [[ "${mode}" == "file" ]]; then

    local file_list
    file_list=$(git ls-tree -r --name-only "${branch_ref}" 2>/dev/null \
      || git ls-tree -r --name-only HEAD 2>/dev/null)

    local selected_file
    selected_file=$(echo "${file_list}" | sort -u | \
      fzf --prompt="Select file> " \
          --header="Branch: ${branch_ref}  |  ENTER=open latest commit  ESC=abort" \
          --preview "git log ${branch_ref} --oneline --color=always -10 -- {} 2>/dev/null" \
          --preview-window=right:50%:wrap \
          --ansi)

    [[ -z "${selected_file}" ]] && echo "  Aborted." && return

    local -a log_args=(log "${branch_ref}" -1 --format="%H")
    [[ -n "${author}" ]] && log_args+=(--author="${author}")

    local sha
    sha=$(git "${log_args[@]}" -- "${selected_file}" 2>/dev/null)

    if [[ -z "${sha}" ]]; then
      echo "  No commits found for '${selected_file}'${author:+ by '${author}'} in ${branch_ref}."
      return 1
    fi

    _gfunc_open_commit "${sha}"

  # ── mode: symbol ────────────────────────────────────────────────────────────
  elif [[ "${mode}" == "symbol" ]]; then

    # Step 1 — pick a file
    local file_list
    file_list=$(git ls-tree -r --name-only "${branch_ref}" 2>/dev/null \
      || git ls-tree -r --name-only HEAD 2>/dev/null)

    local selected_file
    selected_file=$(echo "${file_list}" | sort -u | \
      fzf --prompt="Select file> " \
          --header="Step 1 of 2 — Branch: ${branch_ref}  |  ESC=abort" \
          --preview "git log ${branch_ref} --oneline --color=always -10 -- {} 2>/dev/null" \
          --preview-window=right:55%:wrap \
          --ansi)

    [[ -z "${selected_file}" ]] && echo "  Aborted." && return

    # Step 2 — extract symbols and display in GitHub Symbols style
    local raw_symbols
    raw_symbols=$(_gfunc_extract_symbols "${selected_file}")

    if [[ -z "${raw_symbols}" ]]; then
      echo "  No symbols found in '${selected_file}'."
      echo "  Tip: install universal-ctags for broader language support:"
      echo "       brew install universal-ctags"
      return 1
    fi

    # Format: "func  symbolName                      line 21"
    # Hidden tab column carries the symbol name for clean extraction after select
    local display_list
    display_list=$(echo "${raw_symbols}" | sort -t$'\t' -k3 -n | \
      awk -F'\t' '{
        printf "%-4s  %-40s  line %-5s\t%s\n", $1, $2, $3, $2
      }')

    local selected_sym
    selected_sym=$(echo "${display_list}" | \
      fzf --prompt="Select symbol> " \
          --header="Step 2 of 2 — Branch: ${branch_ref}  |  ENTER=open latest commit  ESC=abort" \
          --delimiter='\t' \
          --with-nth=1 \
          --preview "
            sym=\$(echo {2});
            git log -L \":\${sym}:${selected_file}\" ${branch_ref} --oneline --color=always -10 2>/dev/null \
              || git log ${branch_ref} --oneline --color=always -10 -- ${selected_file} 2>/dev/null
          " \
          --preview-window=right:50%:wrap \
          --ansi)

    [[ -z "${selected_sym}" ]] && echo "  Aborted." && return

    local sym_name
    sym_name=$(echo "${selected_sym}" | awk -F'\t' '{print $2}')

    if [[ -z "${sym_name}" ]]; then
      echo "  Could not extract symbol name."
      return 1
    fi

    local -a log_args=(log -L ":${sym_name}:${selected_file}" "${branch_ref}" -1 --format="%H")
    [[ -n "${author}" ]] && log_args+=(--author="${author}")

    local sha
    sha=$(git "${log_args[@]}" 2>/dev/null)

    # Fallback: latest commit touching the file
    if [[ -z "${sha}" ]]; then
      sha=$(git log "${branch_ref}" -1 --format="%H" ${author:+--author="${author}"} -- "${selected_file}" 2>/dev/null)
    fi

    if [[ -z "${sha}" ]]; then
      echo "  No commits found for '${sym_name}' in '${selected_file}' on ${branch_ref}."
      return 1
    fi

    _gfunc_open_commit "${sha}"

  # ── mode: message ────────────────────────────────────────────────────────────
  elif [[ "${mode}" == "message" ]]; then

    local author_flag=""
    [[ -n "${author}" ]] && author_flag="--author=${author}"

    # --disabled turns off fzf's own fuzzy filter — only the reload drives results
    # change:reload re-runs git log --grep on every keystroke
    local selected
    selected=$(FZF_DEFAULT_COMMAND='echo ""' \
      fzf --disabled \
          --prompt="Search message> " \
          --header="Branch: ${branch_ref}  |  Type to search  ENTER=open in browser  ESC=abort" \
          --info=inline \
          --bind "change:reload:git log ${branch_ref} \
              --format='%H%x09%ad%x09%an%x09%s' \
              --date=short \
              --color=never \
              -i --grep={q} \
              ${author_flag} 2>/dev/null \
            | awk -F'\t' '{printf \"%.8s  %s  %-22s  %s\t%s\n\", \$1, \$2, \$3, \$4, \$1}' \
            || echo 'No matches'" \
          --preview 'sha=$(echo {} | awk -F"\t" "{print \$2}"); git show --stat --color=always "${sha}" 2>/dev/null' \
          --preview-window=right:50%:wrap \
          --delimiter='\t' \
          --with-nth=1 \
          --ansi)

    [[ -z "${selected}" ]] && echo "  Aborted." && return

    local sha
    sha=$(echo "${selected}" | awk -F'\t' '{print $2}')

    if [[ -z "${sha}" || "${sha}" == "No matches" ]]; then
      echo "  Could not resolve commit SHA."
      return 1
    fi

    _gfunc_open_commit "${sha}"
  fi
}
