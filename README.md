# gfunc

A zsh plugin for GitHub workflow automation — fuzzy branch management, repo navigation, and commit search, all from the terminal.

## Requirements

- macOS Catalina (10.15) or later — ships with zsh as default
- `git`, `gh` (GitHub CLI), `fzf` — see [Installation](#installation)

## Installation

### Automated (recommended)

```zsh
git clone https://github.com/WilliamDavidson-02/gfunc ~/.config/zsh/gfunc
~/.config/zsh/gfunc/install.sh
```

The install script will:
- Check/install `git`, `gh`, and `fzf` via Homebrew
- Optionally install `universal-ctags` (for better `gfunc search --symbol` support)
- Run `gh auth login` if not already authenticated
- Print the line to add to your `.zshrc`

### Plugin managers

**Oh My Zsh**
```zsh
git clone https://github.com/WilliamDavidson-02/gfunc \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/gfunc
# Add gfunc to plugins=() in ~/.zshrc
```

**Manual**
```zsh
# Add to ~/.zshrc:
source ~/.config/zsh/gfunc/gfunc.plugin.zsh
```

---

## Commands

### `gfunc clone`
Interactively pick a GitHub account and repo to clone via fzf. After cloning, automatically `cd`s into the repo.

```zsh
gfunc clone
```

---

### `gfunc open [flag]`
Open the current repo on GitHub in your browser.

```zsh
gfunc open          # repo root
gfunc open -b       # current branch
gfunc open -pr      # open PR for current branch
```

---

### `gfunc prune [timeframe]`
Preview and bulk-delete stale **local** branches by last-commit age. All matching branches are pre-selected in fzf — TAB to deselect any you want to keep. Requires typing `yes` to confirm.

Never touches `main`, `master`, `develop`, `dev`, `trunk`, or your current branch.

```zsh
gfunc prune        # default: 1 month
gfunc prune 1w     # older than 1 week
gfunc prune 2w
gfunc prune 3m
gfunc prune 6m
```

---

### `gfunc gone`
Find local branches whose **remote tracking branch has been deleted** (e.g. merged PRs). Runs `git fetch --prune` first, then shows matching branches in fzf with a commit preview. Requires typing `yes` to confirm deletion.

```zsh
gfunc gone
```

---

### `gfunc search <mode> [options]`
Search commit history and open results in the browser.

#### Modes

| Mode | Description |
|------|-------------|
| `--latest-file` | Fuzzy search all tracked files — opens the latest commit for the selected file |
| `--symbol` | Step 1: pick a file. Step 2: pick a `func` or `type` definition. Opens the latest commit that touched it |
| `--message` | Live search by commit message — list updates as you type |

#### Options

| Flag | Description |
|------|-------------|
| `-a, --author <name>` | Filter by author (works with any mode) |
| `-b, --branch [name]` | Scope to a branch (see below) |

#### Branch scoping with `-b`

```zsh
gfunc search --message                  # all remote branches
gfunc search --message -b              # remote of your current branch
gfunc search --message -b develop      # origin/develop specifically
```

#### Examples

```zsh
gfunc search --message
gfunc search --message -b develop
gfunc search --message -b -a <author>
gfunc search --latest-file -b main
gfunc search --symbol -b main
```

---

## Dependencies

| Package | Required | Used by |
|---------|----------|---------|
| `git` | ✅ | everything |
| `gh` | ✅ | `clone`, `open -pr` |
| `fzf` | ✅ | everything |
| `universal-ctags` | optional | `search --symbol` (falls back to regex without it) |

Install everything:
```zsh
brew install git gh fzf universal-ctags
```

---

## Shell compatibility

gfunc requires **zsh 5.0+**. It uses zsh-specific features (`[[`, arrays, process substitution) that are not compatible with `fish`, `nushell`, or POSIX `sh`. It will also work in bash 4+ but is not officially supported there.

macOS Catalina (2019) and later ship with zsh as the default shell, so no setup is needed on modern Macs.

---

## Repo structure

```
gfunc/
├── gfunc.plugin.zsh   ← entry point — sources libs, defines dispatcher
├── install.sh         ← dependency bootstrapper
├── README.md
└── lib/
    ├── helpers.zsh    ← shared: _gfunc_base_url, _gfunc_open_commit, etc.
    ├── clone.zsh
    ├── open.zsh
    ├── prune.zsh
    ├── gone.zsh
    └── search.zsh
```
