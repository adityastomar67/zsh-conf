#    ░█░█░█▀▀░█░█░░░█▀▄░▀█▀░█▀█░█▀▄░█▀▀░░░░▀▀█░█▀▀░█░█
#    ░█▀▄░█▀▀░░█░░░░█▀▄░░█░░█░█░█░█░▀▀█░░░░▄▀░░▀▀█░█▀█
#    ░▀░▀░▀▀▀░░▀░░░░▀▀░░▀▀▀░▀░▀░▀▀░░▀▀▀░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This file defines the keyboard shortcuts (key bindings) for the Zsh shell.
#   It maps physical keys (Arrows, Home, End, Delete) to specific Zsh line
#   editor (ZLE) internal commands.
#
# Problems Solved
#   - Fixes "garbage" characters (like ^[[A) appearing when using keys in Vim.
#   - Enables "history substring search" (typing "git" + Up arrow filters history).
#   - Standardizes behavior across Linux and macOS terminals.
#   - Adds productivity macros (toggle sudo, edit line in text editor).
#
# Features / Responsibilities
#   - Terminfo detection (adapts to the specific terminal emulator).
#   - Smart History Search (filters based on current input).
#   - Vi-style navigation for Tab completion menus.
#   - Custom widgets (Sudo toggle, Edit in $EDITOR).
#
# Usage Notes
#   - MacOS Users: Ensure your terminal sends 'Esc+' for the Option key to use
#     Alt/Meta bindings.
#   - Key Conflicts: If 'Ctrl+Arrow' switches desktops, disable that system
#     shortcut in OS settings or remap in the terminal emulator.
#
# Project: Zsh-conf
# ------------------------------------------------------------------------------

# System Initialization
# ─────────────────────────────────────────────────────────────
## We need to load the terminfo module to communicate with the terminal
## emulator correctly. This allows us to ask "what is the code for Key X?"
## instead of hardcoding raw ANSI escape sequences that might vary.

# Load the Zsh Terminal Info module
zmodload zsh/terminfo

# Load the 'complist' module to enable keybindings inside the menu.
zmodload zsh/complist

# ── key code definitions ───────────────────────────────────────────────

# Define a global associative array to map human-readable key names
# to their specific terminal codes.
typeset -g -A key_map

# Logic:
# 1. Try to get the code from 'terminfo' (best practice).
# 2. If 'terminfo' fails (returns empty), fallback (':-') to standard ANSI codes.
key_map[Up]="${terminfo[kcuu1]:-^[[A}"      # Arrow Up
key_map[Down]="${terminfo[kcud1]:-^[[B}"      # Arrow Down
key_map[Left]="${terminfo[kcub1]:-^[[D}"      # Arrow Left
key_map[Right]="${terminfo[kcuf1]:-^[[C}"      # Arrow Right
key_map[Home]="${terminfo[khome]:-^[[H}"      # Home (Fn+Left)
key_map[End]="${terminfo[kend]:-^[[F}"       # End (Fn+Right)
key_map[Insert]="${terminfo[kich1]:-^[[2~}"     # Insert
key_map[Delete]="${terminfo[kdch1]:-^[[3~}"     # Forward Delete
key_map[BackTab]="${terminfo[kcbt]:-^[[Z}"       # Shift + Tab
key_map[Ctrl-Left]="${terminfo[kLFT5]:-^[[1;5D}"   # Ctrl + Left
key_map[Ctrl-Right]="${terminfo[kRIT5]:-^[[1;5C}"   # Ctrl + Right

# ── standard editing fixes ─────────────────────────────────────────────

# Make sure the Backspace key works as expected (delete to left).
# ^? is the standard ASCII code for Backspace.
bindkey "^?" backward-delete-char

# Legacy compatibility for Backspace (Ctrl + H).
bindkey "^H" backward-delete-char

# Ctrl + U: Clear the entire line to the left of the cursor.
bindkey "^U" backward-kill-line

# Ctrl + K: Clear the entire line to the right of the cursor.
bindkey "^K" kill-line

# Ctrl + W: Delete the previous word (stops at separators defined in $WORDCHARS).
bindkey "^W" backward-kill-word

# Spacebar: Expand history aliases (e.g., !! -> last command) immediately.
bindkey " "  magic-space

bindkey '^I' complete-word


# Navigation & Cursor Movement
# ─────────────────────────────────────────────────────────────
## Bindings for moving the cursor efficiently across the command line.
## We use the 'key_map' defined above to ensure portability.

# ------------------------------------------------------------------------------
# Character & Word Jumping

# Move one character at a time (Left/Right Arrows)
[[ -n "${key_map[Left]}" ]]  && bindkey -- "${key_map[Left]}"  backward-char
[[ -n "${key_map[Right]}" ]] && bindkey -- "${key_map[Right]}" forward-char

# Move one word at a time (Ctrl + Left/Right)
# Note: On macOS, this often requires unbinding Mission Control shortcuts.
[[ -n "${key_map[Ctrl-Left]}" ]]  && bindkey -- "${key_map[Ctrl-Left]}"  backward-word
[[ -n "${key_map[Ctrl-Right]}" ]] && bindkey -- "${key_map[Ctrl-Right]}" forward-word

# ------------------------------------------------------------------------------
# Line Navigation

# Jump to start of line (Home key)
[[ -n "${key_map[Home]}" ]] && bindkey -- "${key_map[Home]}" beginning-of-line

# Jump to end of line (End key)
[[ -n "${key_map[End]}" ]]  && bindkey -- "${key_map[End]}"  end-of-line


# Deletion Logic
# ─────────────────────────────────────────────────────────────
## Standardizing how text is removed when using Delete keys.

# Delete the character under the cursor (Forward Delete / Fn+Backspace)
[[ -n "${key_map[Delete]}" ]] && bindkey -- "${key_map[Delete]}" delete-char

# Delete from cursor to end of word (Ctrl + Delete)
# Hardcoded ANSI sequence often required for this specific combo.
bindkey '^[[3;5~' kill-word


# Smart History Search
# ─────────────────────────────────────────────────────────────
## Upgrades the Up/Down arrow keys. Instead of just cycling history blindly,
## this filters history based on what you have already typed.
## Example: Type "npm", press Up -> shows only previous "npm" commands.

# Bind to standard ANSI Up/Down codes (fallback)
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Bind to terminfo-detected codes (primary)
[[ -n "${key_map[Up]}" ]]   && bindkey -- "${key_map[Up]}"   up-line-or-beginning-search
[[ -n "${key_map[Down]}" ]] && bindkey -- "${key_map[Down]}" down-line-or-beginning-search


# Menu Selection System
# ─────────────────────────────────────────────────────────────
## Configuration for the completion menu (triggered when you press Tab).

# Shift + Tab: Cycle backwards through the completion menu.
[[ -n "${key_map[BackTab]}" ]] && bindkey -- "${key_map[BackTab]}" reverse-menu-complete

# ── vi-mode navigation ─────────────────────────────────────────────────
if [[ "${ENABLE_VI_MODE:l}" == "yes" ]]; then

    # ── 1. Core Activation ─────────────────────────────────────────────────
    bindkey -v
    export KEYTIMEOUT=1

    # ── 2. Command Line Fixes ──────────────────────────────────────────────
    # 'bindkey -v' breaks standard Ctrl keys. We restore them here.

    bindkey '^?' backward-delete-char                  # Backspace
    bindkey '^h' backward-delete-char                  # Ctrl + H
    bindkey '^w' backward-kill-word                    # Ctrl + W
    bindkey '^r' history-incremental-search-backward   # Ctrl + R

    # ── 3. Menu Navigation (hjkl) ──────────────────────────────────────────
    # These bindings only exist in the 'menuselect' keymap (the tab menu).

    bindkey -M menuselect 'h' vi-backward-char         # Left
    bindkey -M menuselect 'j' vi-down-line-or-history  # Down
    bindkey -M menuselect 'k' vi-up-line-or-history    # Up
    bindkey -M menuselect 'l' vi-forward-char          # Right

    # ── 4. Menu Control ────────────────────────────────────────────────────

    # Escape: Cancel menu and return to typing
    bindkey -M menuselect '^[' send-break

    # Enter: Accept the currently highlighted selection (Explicit definition)
    bindkey -M menuselect '^M' accept-line
fi


# Custom Widgets & Macros
# ─────────────────────────────────────────────────────────────
## Advanced functions mapped to specific keystrokes to speed up workflow.

# ------------------------------------------------------------------------------
# Widget: Edit Command Line
# Opens the current command buffer in your default $EDITOR (Vim, Nano, Code).
# Useful for writing complex loops or editing long commands.

bindkey '^e' edit-command-line  # Ctrl + E

# ------------------------------------------------------------------------------
# Widget: Smart Sudo Toggle
# Toggles 'sudo' at the beginning of the command line.
# If line is empty, it retrieves the LAST command and prepends sudo.

bindkey "\e\e\e" toggle_sudo_prefix  # Esc, Esc, Esc (Triple Escape)

# ------------------------------------------------------------------------------
# Widget: Autosuggest Acceptance
# If zsh-autosuggestions is installed, map Ctrl + Space to accept the suggestion.

# ---- NOTE: Check OS settings if Ctrl+Space conflicts with input switching.
if [[ -n "${aliases[zsh-autosuggestions]}" || -f "$ZSH_AUTOSUGGEST_MANUAL_REBIND" ]]; then
    bindkey '^ ' autosuggest-accept
fi

