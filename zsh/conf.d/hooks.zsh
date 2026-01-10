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
#   - This file creates the widgets. You must bind keys to them in `keys.zsh`.
#
# Project: Zsh-conf
# ------------------------------------------------------------------------------


# Smart History Search Setup
# ─────────────────────────────────────────────────────────────
## Prepares the "Up/Down" arrow logic to filter history based on current input
## rather than just cycling through every command.
## Note: This just loads the functions; keybindings are handled elsewhere.

# Load the function definitions from Zsh's function path
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search add-zsh-hook

# Register them as ZLE widgets so they can be bound to keys
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search


# Custom Editor Widgets
# ─────────────────────────────────────────────────────────────
## Advanced macros to speed up command line editing.

# ------------------------------------------------------------------------------
# Widget: Edit Command Line
# Description:
#   Opens the current buffer in your external $EDITOR (Vim, Nano, VS Code).
#   Useful for complex multi-line commands or scripting on the fly.

autoload -Uz edit-command-line
zle -N edit-command-line

# ------------------------------------------------------------------------------
# Widget: Smart Sudo Toggle
# Description:
#   Toggles 'sudo' at the start of the line. Smartly handles empty buffers
#   by targeting the previous command in history.

toggle_sudo_prefix() {
    # Case 1: Buffer is empty -> Retrieve last command and prepend sudo
    if [[ -z $BUFFER ]]; then
        LBUFFER="sudo $(fc -ln -1)"

    # Case 2: Buffer already starts with sudo -> Remove it
    elif [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"

    # Case 3: Buffer has text -> Prepend sudo
    else
        LBUFFER="sudo $LBUFFER"
    fi
}

# Register the function as a widget
zle -N toggle_sudo_prefix


# Terminal Mode Synchronization (Hooks)
# ─────────────────────────────────────────────────────────────
## Lifecycle hooks that ensure the terminal emulator is in the correct mode.
##
## Context:
##   Terminals have two modes for arrow keys: "Application" (smkx) and "Raw" (rmkx).
##   Zsh likes Application mode, but tools like Vim/Nano expect Raw mode.
##   Without this hook, pressing arrows in Vim might output garbage like "^[[A".

if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget

    # Hook: Line Init (Start of typing)
    # Action: Enable Application Mode (smkx)
    function _enable_app_mode() {
        echoti smkx
    }

    # Hook: Line Finish (Execution of command)
    # Action: Disable Application Mode (rmkx)
    function _disable_app_mode() {
        echoti rmkx
    }

    # Register the hooks
    add-zle-hook-widget zle-line-init   _enable_app_mode
    add-zle-hook-widget zle-line-finish _disable_app_mode
fi

# ........................[  4. Fast Rehash (Arch)  ]........................ #

# -------------------------------------------------------------------------
# [OPTIMIZATION] Arch Linux Fast Rehash
# Uses zmodload to avoid spawning 'date' subshells in precmd
# -------------------------------------------------------------------------
if [[ -f /etc/arch-release ]]; then
    zmodload zsh/stat 2>/dev/null
    typeset -g _pacman_trigger="/var/cache/zsh/pacman"
    typeset -g _pacman_last_mtime=0

    rehash_precmd() {
        [[ -f "$_pacman_trigger" ]] || return
        local -a st
        zstat -A st +mtime "$_pacman_trigger" 2>/dev/null
        if (( st[1] > _pacman_last_mtime )); then
            rehash
            _pacman_last_mtime=$st[1]
        fi
    }
    add-zsh-hook -Uz precmd rehash_precmd
fi
