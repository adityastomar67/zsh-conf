#!/usr/bin/env zsh

#    ░█░█░█▀█░█▀█░█░█░█▀▀░░░░▀▀█░█▀▀░█░█
#    ░█▀█░█░█░█░█░█▀▄░▀▀█░░░░▄▀░░▀▀█░█▀█
#    ░▀░▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This module defines custom Zsh Line Editor (ZLE) widgets and lifecycle hooks.
#   It prepares advanced functionality (like smart history searching and terminal
#   mode synchronization) without assigning specific keybindings.
#
# Problems Solved
#   - Defines the logic for "Smart Sudo" (toggling sudo on the current/last command).
#   - Prepares the "Edit in Editor" functionality.
#   - Fixes input issues in programs like Vim/Nano by managing terminal modes.
#
# Features / Responsibilities
#   - Widget Registration (`zle -N`).
#   - Autoloading of Zsh contrib functions.
#   - Terminal Application Mode hooks (`smkx`/`rmkx`).
#
# Usage Notes
#   - This file creates the widgets. You must bind keys to them in `keybinds.zsh`.
#
# Project: Zsh-conf
# ------------------------------------------------------------------------------


# Smart History Search Setup
# ─────────────────────────────────────────────────────────────
## Prepares the "Up/Down" arrow logic to filter history based on current input
## rather than just cycling through every command.

# Load the function definitions from Zsh's function path
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search add-zsh-hook

# Register them as ZLE widgets so they can be bound to keys
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search


# Custom Editor Widgets
# ─────────────────────────────────────────────────────────────

# 4. Register as a Widget (so you can bind a key to it)
zle -N ftmux

## Advanced macros to speed up command line editing.

# ------------------------------------------------------------------------------
# Widget: Edit Command Line
# Description:
#   Opens the current buffer in your external $EDITOR (Vim, Nano, VS Code).
#   Useful for complex multi-line commands or scripting on the fly.
# ------------------------------------------------------------------------------
autoload -Uz edit-command-line
zle -N edit-command-line


# ------------------------------------------------------------------------------
# Widget: Smart Sudo Toggle
# Description:
#   Toggles 'sudo' at the start of the line. Smartly handles empty buffers
#   by targeting the previous command in history via 'fc'.
# ------------------------------------------------------------------------------
toggle_sudo_prefix() {
    if [[ -z $BUFFER ]]; then
        # Retrieve last command from history and prepend sudo
        LBUFFER="sudo $(fc -ln -1)"
    elif [[ $BUFFER == sudo\ * ]]; then
        # Remove sudo if already present
        LBUFFER="${LBUFFER#sudo }"
    else
        # Prepend sudo to current buffer
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N toggle_sudo_prefix


# ------------------------------------------------------------------------------
# Widget: Magic Dot Expansion
# Description: Typing '...' becomes '../..', '....' becomes '../../..'
# ------------------------------------------------------------------------------
magic_dot_expansion() {
    if [[ $LBUFFER = *.. ]]; then
        LBUFFER+="/.."
    else
        LBUFFER+="."
    fi
}
zle -N magic_dot_expansion


# Interactive User Assistance
# ─────────────────────────────────────────────────────────────
## Widgets that provide context-aware information when the line is empty.

# ------------------------------------------------------------------------------
# Widget: Magic Enter
# Description: Executes command if buffer has text; otherwise shows status.
# ------------------------------------------------------------------------------
magic_enter() {
    if [[ -n "$BUFFER" ]]; then
        zle accept-line
        return 0
    fi

    # Tell ZLE we are outputting text to prevent prompt overlap
    zle -I
    echo ""

    # ::: Background Jobs Detector :::
    if [[ $(jobs | wc -l) -gt 0 ]]; then
        print -P "%F{cyan}::: Background Jobs :::%f"
        jobs
        echo ""
    fi

    # ::: Python VirtualEnv Detector :::
    if [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
        if [[ -z "$VIRTUAL_ENV" ]]; then
             print -P "%F{red}::: ⚠️  PYTHON PROJECT DETECTED (No VirtualEnv Active) ⚠️  :::%f"
             echo ""
        fi
    fi

    # ::: Smart Git Status :::
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        if [[ -n $(git status --porcelain) ]]; then
            print -P "%F{yellow}::: Git Status (Dirty) :::%f"
            git status -sb
        else
            print -P "%F{green}::: Git Status (Clean) :::%f"
            git log -n 3 --oneline --color=always
        fi
        echo ""
    fi

    # ::: Directory Listing :::
    if (( $+commands[eza] )); then
        eza --icons --git --group-directories-first --header
    else
        ls -F --color=auto --group-directories-first
    fi

    zle redisplay
}
zle -N magic_enter


# ------------------------------------------------------------------------------
# Hook: Auto LS on CD
# Description: Automatically lists files when changing directories.
# ------------------------------------------------------------------------------
function chpwd_auto_ls() {
    emulate -L zsh
    ls -F --color=auto
}
add-zsh-hook chpwd chpwd_auto_ls


# Terminal State Synchronization
# ─────────────────────────────────────────────────────────────
## Lifecycle hooks to manage Terminal Application Mode (smkx/rmkx).

if [[ "$TERM" != "dumb" ]] && (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget

    function _enable_app_mode() {
        print -n "${terminfo[smkx]}"
    }

    function _disable_app_mode() {
        print -n "${terminfo[rmkx]}"
    }

    add-zle-hook-widget zle-line-init   _enable_app_mode
    add-zle-hook-widget zle-line-finish _disable_app_mode
fi


# Productivity & UI Enhancements
# ─────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# Widget: Fancy Ctrl-Z
# Description: Toggles between backgrounding and foregrounding jobs.
# ------------------------------------------------------------------------------
fancy_ctrl_z() {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="fg"
        zle accept-line
    else
        zle push-input
        zle clear-screen
    fi
}
zle -N fancy_ctrl_z


# ------------------------------------------------------------------------------
# Widget: Copy Buffer to Clipboard
# Description: Cross-platform command line copying.
# ------------------------------------------------------------------------------
copy_buffer_to_clipboard() {
    local copy_cmd
    if [[ "$OSTYPE" == darwin* ]]; then
        copy_cmd="pbcopy"
    elif (( $+commands[wl-copy] )); then
        copy_cmd="wl-copy"
    elif (( $+commands[xclip] )); then
        copy_cmd="xclip -selection clipboard"
    elif (( $+commands[xsel] )); then
        copy_cmd="xsel --clipboard --input"
    fi

    if [[ -n "$copy_cmd" ]]; then
        echo -n "$BUFFER" | eval "$copy_cmd"
        zle -M "Copied buffer to clipboard."
    else
        zle -M "Error: No clipboard utility found."
    fi
}
zle -N copy_buffer_to_clipboard


# ------------------------------------------------------------------------------
# Widget: Transient Prompt
# Description: Shrinks the prompt to a minimal symbol after execution.
# ------------------------------------------------------------------------------
typeset -g _TRANS_PROMPT="%F{8}❯%f "
typeset -g _OLD_PROMPT=""

_transient_restore() {
    if [[ -n "$_OLD_PROMPT" ]]; then
        PROMPT="$_OLD_PROMPT"
    fi
}
add-zsh-hook precmd _transient_restore

_transient_finish() {
    if [[ "$PROMPT" != "$_TRANS_PROMPT" ]]; then
        _OLD_PROMPT="$PROMPT"
    fi
    PROMPT="$_TRANS_PROMPT"
    zle reset-prompt
}
add-zle-hook-widget line-finish _transient_finish


# Integration Widgets (External Tools)
# ─────────────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# Widget: Git FZF Fixup
# Description: Interactively select a commit to fixup via FZF.
# ------------------------------------------------------------------------------
git_fzf_fixup() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        zle -M "Not in a git repository."
        return
    fi

    local commit
    commit=$(git log -n 50 --oneline --color=always | \
        fzf --ansi --no-sort --height=40% --layout=reverse --prompt="🛠️ Fixup Commit > " | \
        awk '{print $1}')

    if [[ -n "$commit" ]]; then
        LBUFFER="git commit -a --no-verify --fixup=$commit"
        zle accept-line
    else
        zle redisplay
    fi
}
zle -N git_fzf_fixup


# ------------------------------------------------------------------------------
# Widget: Docker Smart Connect
# Description: Select a running container and attach to its shell via FZF.
# ------------------------------------------------------------------------------
docker_connect_widget() {
    if ! command -v docker >/dev/null; then
        zle -M "Docker not installed."
        return
    fi

    local cid
    cid=$(docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" | \
          fzf --header-lines=1 \
              --prompt="🐳 Shell > " \
              --height=40% \
              --layout=reverse \
              --preview='docker logs --tail 20 {1}' \
              --preview-window='right:50%:wrap:nohidden' | \
          awk '{print $1}')

    if [[ -n "$cid" ]]; then
        LBUFFER="docker exec -it $cid /bin/sh -c '(bash || sh)'"
        zle accept-line
    fi
    zle redisplay
}
zle -N docker_connect_widget

