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
#
# Project: Zsh-conf
# ------------------------------------------------------------------------------


# 1. Basic Permissions & Input
# ─────────────────────────────────────────────────────────────

# umask 022: User has full access, group/others have read/execute only.
umask 022

# Characters considered part of a word when using Ctrl+W (Delete Word).
# Removing '/' allows deleting path segments one by one.
WORDCHARS='|-.'


# 2. Navigation Options
# ─────────────────────────────────────────────────────────────

setopt AUTO_CD              # Typing 'dir' becomes 'cd dir'
setopt AUTO_LIST            # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH     # Tab completing a directory appends a slash
setopt LIST_PACKED          # Minimize space in completion lists


# 3. Completion Behavior
# ─────────────────────────────────────────────────────────────

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


# 4. History Configuration
# ─────────────────────────────────────────────────────────────

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


# 5. Job Control & Feedback
# ─────────────────────────────────────────────────────────────

setopt NOTIFY                  # Report status of background jobs immediately
setopt NOHUP                   # Don't kill background jobs on exit
setopt MAILWARN                # Print mail warning message
setopt INTERACTIVE_COMMENTS    # Allow comments (#) in interactive shell
setopt NOBEEP                  # No beep on error


# 6. Autosuggestions Config
# ─────────────────────────────────────────────────────────────

# Async Mode: Prevents lagging while typing large commands
ZSH_AUTOSUGGEST_USE_ASYNC="true"

# Strategy: Try history first, then completion engine
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Styling: Grey text (240 is standard dark grey)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=240"

# Performance limits
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=200


# 7. Completion Engine Initialization
# ─────────────────────────────────────────────────────────────

## Smart caching logic for `compinit`.
# Allow completion to match dotfiles
_comp_options+=(globdots)

# Ensure cache dump location is defined
# ZSH_COMPLETION_DUMP="${ZDOTDIR:-$HOME}/.zcompdump"

# Glob Logic:
# #q : Start glob qualifiers
# N  : Nullglob (don't error if file missing)
# .  : Plain files only
# mh : Modification time in hours
# +24: Older than 24 hours

if [[ -n "$ZSH_COMPLETION_DUMP"(#qN.mh+24) ]]; then
    # Scenario A: Cache is old or missing. Rebuild.
    # -i: Ignore insecure directories
    # -u: Use insecure directories (silently)
    # -d: Dump path
    compinit -i -u -d "$ZSH_COMPLETION_DUMP"
else
    # Scenario B: Cache is fresh. Fast Load.
    # -C: Skip ALL security checks, trust the dump file
    compinit -C -d "$ZSH_COMPLETION_DUMP"
fi


# 8. Zstyle Configuration
# ─────────────────────────────────────────────────────────────
## Visuals and behavior for the completion menu.

# ── Matching Strategy ──
# 1. Exact match
# 2. Case insensitive (a=A)
# 3. Partial matching (f-b -> foo-bar)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# ── Caching ──
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZSH_CACHE}"

# ── Grouping & Sorting ──
zstyle ':completion:*' group-name ''       # Enable grouping
zstyle ':completion:*' list-dirs-first true # Directories on top
zstyle ':completion:*' verbose yes         # Show descriptions

# ── Interaction ──
zstyle ':completion:*' menu select         # Allow arrow key selection

# ── Visual Styling ──
# Group Descriptions (Magenta Arrow -> Bold Text)
zstyle ':completion:*:*:*:*:descriptions' format \
    "${COLOR[MAGENTA]} ${COLOR[BOLD]}%d${COLOR[DIM]}${COLOR[RESET]}"

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


# 9. Fzf-Tab Configuration
# ─────────────────────────────────────────────────────────────
## Configuration for the fzf-tab plugin (rich previews).

# ── Behavior ──
# Trigger fzf on path completion automatically
zstyle ':fzf-tab:*' continuous-trigger '/'

# ── Styling ──
# Inherits FZF_DEFAULT_OPTS, but forces 40% height
zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse

# ── Context-Aware Previews ──

# 'cd': Preview directory contents using eza
zstyle ':fzf-tab:complete:cd:*' fzf-preview \
    'eza -1 --icons=always --color=always --group-directories-first $realpath'

# 'systemctl': Preview service status
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview \
    'SYSTEMD_COLORS=1 systemctl status $word'

# 'command': Preview man page or file content
zstyle ':fzf-tab:complete:(-command-):*' fzf-preview \
    '[[ -n $builtins[$word] ]] && man $word || bat --color=always --style=plain $realpath 2>/dev/null'


# 10. Tool Initialization
# ─────────────────────────────────────────────────────────────

# Install Plugins (if ZPLUGINS array is set)
plug

# 1. Starship (Prompt)
is_installed starship  && _eval_cache "starship" "starship init zsh" "immediate"

# 2. Zoxide (Smart Navigation)
is_installed zoxide    && _eval_cache "zoxide" "zoxide init zsh" "defer"

# 3. Atuin (Magic History)
is_installed atuin     && _eval_cache "atuin" "atuin init zsh" "defer"

# 4. Dircolors (LS Colors)
is_installed dircolors && _eval_cache "dircolors" "dircolors -b" "immediate"

