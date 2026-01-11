#!/usr/bin/env zsh

#    ░█▀█░█▀█░▀█▀░▀█▀░█▀█░█▀█░█▀▀░░░░▀▀█░█▀▀░█░█
#    ░█░█░█▀▀░░█░░░█░░█░█░█░█░▀▀█░░░░▄▀░░▀▀█░█▀█
#    ░▀▀▀░▀░░░░▀░░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This file configures the core Zsh options (setopt), history behavior,
#   completion engine, and initializes external tools like Starship and Zoxide.
#
# Problems Solved
#   - Optimizes history storage (deduplication, timestamps).
#   - Configures "sane defaults" for file globbing and navigation.
#   - Sets up the completion system with a smart caching strategy to speed up load.
#   - Lazy-loads external tools to reduce startup latency.
#
# Features / Responsibilities
#   - `setopt` definitions.
#   - History file management.
#   - Autosuggestion tweaking.
#   - Compinit (Completion) caching logic.
#   - External tool initialization (Starship, Atuin, Zoxide).
#
# Usage Notes
#   - Sourced during startup.
#   - Requires `_eval_cache` function (from lib/_core.utils) for tool init.
#
# Project: Zsh-conf
# ------------------------------------------------------------------------------

# Basic Permissions & Input
# ─────────────────────────────────────────────────────────────
## Standard file creation masks and word delimiters.

# umask 022: User has full access, group/others have read/execute only.
umask 022

# Characters considered part of a word when using Ctrl+W (Delete Word).
# Removing '/' allows deleting path segments one by one.
WORDCHARS='|-.'


# Navigation Options
# ─────────────────────────────────────────────────────────────
## options to make moving directories faster.

setopt AUTO_CD              # Typing 'dir' becomes 'cd dir'
setopt AUTO_LIST            # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH     # Tab completing a directory appends a slash
setopt LIST_PACKED          # Minimize space in completion lists


# Completion Behavior
# ─────────────────────────────────────────────────────────────
## Modernizing the tab completion experience.



setopt COMPLETE_IN_WORD     # Allow completion from within a word/cursor position
setopt GLOB_COMPLETE        # Show autocompletion menu for globs
setopt HASH_LIST_ALL        # Hash entire path for faster completion
setopt EXTENDED_GLOB        # Use '#', '~', and '^' for advanced matching
setopt GLOB_DOTS            # Allow globbing to match hidden files (dotfiles)
setopt ALWAYS_TO_END        # Move cursor to end of word after completion

# Disable standard menu completion behavior in favor of fzf-tab/external plugins
unsetopt MENU_COMPLETE

# Corrections & Safety
unsetopt FLOWCONTROL        # Disable Ctrl+S/Ctrl+Q output freezing
unsetopt NOMATCH            # Don't error if a glob has no matches (pass to command)
unsetopt CORRECT            # Disable "Did you mean..?" spelling correction (often annoying)


# History Configuration
# ─────────────────────────────────────────────────────────────
## High-performance history settings.

setopt SHARE_HISTORY             # Share history between open terminals immediately
setopt INC_APPEND_HISTORY_TIME   # Append to history file as soon as command finishes
setopt EXTENDED_HISTORY          # Save timestamp and duration of commands
setopt HIST_IGNORE_ALL_DUPS      # Don't save duplicates
setopt HIST_IGNORE_SPACE         # Don't save commands starting with a space
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks
setopt HIST_VERIFY               # Show command with substitutions before executing

# Paths & Limits
HISTFILE="${ZDOTDIR:-$HOME/.cache}/zhistory"
HISTSIZE=50000
SAVEHIST=50000

# Formatting
HISTTIMEFORMAT="%Y/%m/%d %H:%M:%S:   "
HIST_STAMPS="mm/dd/yyyy"
export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"


# Job Control & Feedback
# ─────────────────────────────────────────────────────────────

setopt NOTIFY                  # Report status of background jobs immediately
setopt NOHUP                   # Don't kill background jobs on exit
setopt MAILWARN                # Print mail warning message
setopt INTERACTIVE_COMMENTS    # Allow comments (#) in interactive shell
setopt NOBEEP                  # No beep on error


# Autosuggestions Config
# ─────────────────────────────────────────────────────────────
## Tweaking the zsh-autosuggestions plugin variables.

# Async Mode: Prevents lagging while typing large commands
ZSH_AUTOSUGGEST_USE_ASYNC="true"

# Strategy: Try history first, then completion engine
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Styling: Blue text on grey background, bold
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=blue,bg=242,bold"

# Performance limits
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Manual Rebind: Allows us to map custom keys (like Ctrl+Space) in `keys.zsh`
export ZSH_AUTOSUGGEST_MANUAL_REBIND=1


# Completion Engine Initialization
# ─────────────────────────────────────────────────────────────
## Smart caching logic for `compinit`.
## Re-running `compinit` on every shell start is slow. We only run it fully
## once every 20 hours.

# Ensure completion can see dotfiles
export ZSH_COMPLETION_DUMP="${ZDOTDR:-$HOME/.cache}/zcompdump"

_comp_options+=(globdots)

# Glob Logic:
# #q : Start glob qualifiers
# N  : Nullglob (don't error if file missing)
# .  : Plain files only
# mh : Modification time in hours
# +20: Older than 20 hours

if [[ -n "$ZSH_COMPLETION_DUMP"(#qN.mh+20) ]]; then
    # Scenario A: Cache is old or missing. Rebuild.
    # -i: Ignore insecure directories (don't ask user)
    # -u: Use insecure directories (silently)
    # -d: Dump path
    compinit -i -u -d "$ZSH_COMPLETION_DUMP"
else
    # Scenario B: Cache is fresh. Fast Load.
    # -C: Skip ALL security checks, trust the dump file
    compinit -C -d "$ZSH_COMPLETION_DUMP"
fi


# Tool Initialization (Eval Cache)
# ─────────────────────────────────────────────────────────────
## Initialize external binaries. We use `_eval_cache` to cache the output
## of their init commands (which rarely change), saving ~100ms+ on startup.
echo "Initializing external tools..."
plug

# 1. Starship (Prompt)
#    MUST be 'immediate' so the prompt is ready before the shell draws.
is_installed starship && _eval_cache "starship" "starship init zsh" "immediate"

# 2. Zoxide (Smart Navigation)
#    Safe to defer (aliases load milliseconds after prompt).
is_installed zoxide && _eval_cache "zoxide" "zoxide init zsh" "defer"

# 3. Atuin (Magic History)
#    Safe to defer (keybindings load milliseconds after prompt).
is_installed atuin && _eval_cache "atuin" "atuin init zsh" "defer"

# 4. Dircolors (LS Colors)
#    Often slow to generate, perfect for caching.
is_installed dircolors && _eval_cache "dircolors" "dircolors -b" "immediate"
