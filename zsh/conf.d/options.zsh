#    ░█▀█░█▀█░▀█▀░▀█▀░█▀█░█▀█░█▀▀░░░░▀▀█░█▀▀░█░█
#    ░█░█░█▀▀░░█░░░█░░█░█░█░█░▀▀█░░░░▄▀░░▀▀█░█▀█
#    ░▀▀▀░▀░░░░▀░░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This file configures the core Zsh options (setopt), history behavior,
#   completion engine, and initializes external tools.
#
# Problems Solved
#   - Optimizes history storage (deduplication, timestamps).
#   - Configures "sane defaults" for file globbing and navigation.
#   - Sets up the completion system with a smart caching strategy.
#   - Configures fzf-tab for rich, interactive completions.
#
# Features / Responsibilities
#   - `setopt` definitions.
#   - History file management.
#   - Autosuggestion tweaking.
#   - Compinit (Completion) caching logic.
#   - Fzf-Tab previews.
#
# Usage Notes
#   - Sourced during startup.
#   - Requires `_eval_cache` function (from lib/_core.utils).
# ------------------------------------------------------------------------------


# Basic Permissions & Input
# ───────────────────────────────────────────────────────────────────────

# umask 022: User has full access, group/others have read/execute only.
umask 022

# Characters considered part of a word when using Ctrl+W (Delete Word).
# Removing '/' allows deleting path segments one by one.
WORDCHARS='|-.'


# Navigation Options
# ───────────────────────────────────────────────────────────────────────

setopt AUTO_CD              # Typing 'dir' becomes 'cd dir'
setopt AUTO_LIST            # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH     # Tab completing a directory appends a slash
setopt LIST_PACKED          # Minimize space in completion lists
setopt AUTO_PUSHD           # Push every visited directory to the stack
setopt PUSHD_IGNORE_DUPS    # Do not record the same directory twice
setopt PUSHD_SILENT         # Do not print the stack every time you cd


# Completion Behavior
# ───────────────────────────────────────────────────────────────────────

setopt COMPLETE_IN_WORD     # Allow completion from within a word/cursor position
setopt GLOB_COMPLETE        # Show autocompletion menu for globs
setopt HASH_LIST_ALL        # Hash entire path for faster completion
setopt EXTENDED_GLOB        # Use '#', '~', and '^' for advanced matching
setopt GLOB_DOTS            # Allow globbing to match hidden files (dotfiles)
setopt ALWAYS_TO_END        # Move cursor to end of word after completion

# Disable standard menu completion behavior in favor of fzf-tab
unsetopt MENU_COMPLETE

# Corrections & Safety
unsetopt FLOWCONTROL        # Disable Ctrl+S/Ctrl+Q output freezing
unsetopt NOMATCH            # Don't error if a glob has no matches (pass to command)
unsetopt CORRECT            # Disable "Did you mean..?" spelling correction


# History Configuration
# ───────────────────────────────────────────────────────────────────────

setopt SHARE_HISTORY             # Share history between open terminals immediately
setopt INC_APPEND_HISTORY_TIME   # Append to history file as soon as command finishes
setopt EXTENDED_HISTORY          # Save timestamp and duration of commands
setopt HIST_IGNORE_ALL_DUPS      # Don't save duplicates
setopt HIST_IGNORE_SPACE         # Don't save commands starting with a space
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks
setopt HIST_VERIFY               # Show command with substitutions before executing

# Paths & Limits
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-cache/zhistory"
HISTSIZE=50000
SAVEHIST=50000
export HISTORY_IGNORE="(zsh|clear|ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"


# Job Control & Feedback
# ───────────────────────────────────────────────────────────────────────

setopt NOTIFY                  # Report status of background jobs immediately
setopt NOHUP                   # Don't kill background jobs on exit
setopt MAILWARN                # Print mail warning message
setopt INTERACTIVE_COMMENTS    # Allow comments (#) in interactive shell
setopt NOBEEP                  # No beep on error


# Autosuggestions Config
# ───────────────────────────────────────────────────────────────────────

# Async Mode: Prevents lagging while typing large commands
ZSH_AUTOSUGGEST_USE_ASYNC=1

# Strategy: Try history first, then completion engine
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Styling: Grey text (240 is standard dark grey)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=240"

# Increase the minimum length before a suggestion is fetched
ZSH_AUTOSUGGEST_MIN_BUFFER_SIZE=4

# Disable suggestions for long buffers (prevents lag on large pastes)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Ignore internal/unrelated widgets to drastically speed up startup binding
ZSH_AUTOSUGGEST_IGNORE_WIDGETS=(
    orig-\*
    beep
    run-help
    set-local-history
    which-command
    yank
    yank-pop
)


# Completion Engine Initialization
# ───────────────────────────────────────────────────────────────────────

## Smart caching logic for `compinit`.
# Allow completion to match dotfiles
_comp_options+=(globdots)

# Glob Logic:
#   #q : Start glob qualifiers
#   N  : Nullglob (don't error if file missing)
#   .  : Plain files only
#   mh : Modification time in hours
#   +24: Older than 24 hours

if [[ ! -f "$ZSH_COMPLETION_DUMP" || -n "$ZSH_COMPLETION_DUMP"(#qN.mh+24) ]]; then
    # Scenario A: Cache is old or missing. Rebuild.
    #   -i: Ignore insecure directories
    #   -u: Use insecure directories (silently)
    #   -d: Dump path
    compinit -i -u -d "$ZSH_COMPLETION_DUMP"

    # Touch the cache file to reset the 24-hour expiration timer
    # since compinit doesn't update the mtime if no new completion files are found.
    touch "$ZSH_COMPLETION_DUMP"
else
    # Scenario B: Cache is fresh. Fast Load.
    #   -C: Skip ALL security checks, trust the dump file
    #   -d: Dump path
    compinit -C -d "$ZSH_COMPLETION_DUMP"
fi


# Zstyle Configuration
# ───────────────────────────────────────────────────────────────────────
## Visuals and behavior for the completion menu.

# ── Matching Strategy ──
#   1. Exact match
#   2. Case insensitive (a=A)
#   3. Partial matching (f-b -> foo-bar)
zstyle ':completion:*' matcher-list '' \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# ── Caching ──
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZSH_CACHE}"

# ── Grouping & Sorting ──
zstyle ':completion:*' group-name ''        # Enable grouping
zstyle ':completion:*' list-dirs-first true # Directories on top
zstyle ':completion:*' verbose yes          # Show descriptions

# ── Interaction ──
zstyle ':completion:*' menu select          # Allow arrow key selection

# ── Visual Styling ──
# Effectively passing the ls color rules
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Group Descriptions (Magenta Arrow -> Bold Text)
zstyle ':completion:*:*:*:*:descriptions' format \
    "${COLOR[MAGENTA]} ${COLOR[BOLD]}${COLOR[DIM]}%d${COLOR[RESET]}"

# Corrections ("Did you mean...")
zstyle ':completion:*:*:*:*:corrections' format \
    "${COLOR[YELLOW]} %d${COLOR[RESET]}"

# System Messages
zstyle ':completion:*:*:*:*:messages' format \
    "${COLOR[BLUE]} %d${COLOR[RESET]}"

# Warnings ("No matches")
zstyle ':completion:*:*:*:*:warnings' format \
    "${COLOR[RED]} No Matches Found${COLOR[RESET]}"

# Default Fallback
# zstyle ':completion:*' format \
#     "${COLOR[B_YELLOW]}Suggesting: %d${COLOR[RESET]}"


# Tool Initialization
# ───────────────────────────────────────────────────────────────────────

# Define your tools configuration
#    Format: "Binary : Command : Mode"
local -a init_tools=(
    "starship  : starship init zsh   : immediate" # Prompt
    "dircolors : dircolors -b        : immediate" # Colors
    "zoxide    : zoxide init zsh     : defer"     # Smart cd
    "atuin     : atuin init zsh      : defer"     # Shell History
    "but       : but completions zsh : defer"     # GitButler
)

# Iterate and Execute
for entry in "${init_tools[@]}"; do
    # Zsh Magic: Split the string by ':' into an array (@s/:/)
    local parts=("${(@s/:/)entry}")

    # Clean up whitespace using ${var// /} for single words
    # and ${var## } to trim leading spaces for commands
    local bin="${${parts[1]## #}%% #}"
    local cmd="${${parts[2]## #}%% #}"
    local mode="${${parts[3]## #}%% #}"

    # Logic: Only run if installed
    if (( $+commands[$bin] )) then
        _eval_cache "$bin" "$cmd" "$mode"
    fi
done

