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
# ------------------------------------------------------------------------------


# System Initialization
# ───────────────────────────────────────────────────────────────────────
## We load the terminfo module to communicate with the terminal
## emulator correctly. This allows us to ask "what is the code for Key X?"
## instead of hardcoding raw ANSI escape sequences that might vary.

# Load the Zsh Terminal Info module
zmodload zsh/terminfo

# Load the 'complist' module to enable keybindings inside the completion menu.
zmodload zsh/complist


# ── key code definitions ───────────────────────────────────────────────

#

# Define a global associative array to map human-readable key names
# to their specific terminal codes.
typeset -g -A key_map

# Logic:
# 1. Try to get the code from 'terminfo' (best practice for portability).
# 2. If 'terminfo' fails (returns empty), fallback (':-') to standard ANSI codes.
key_map[Up]="${terminfo[kcuu1]:-^[[A}"
key_map[Down]="${terminfo[kcud1]:-^[[B}"
key_map[Left]="${terminfo[kcub1]:-^[[D}"
key_map[Right]="${terminfo[kcuf1]:-^[[C}"
key_map[Home]="${terminfo[khome]:-^[[H}"
key_map[End]="${terminfo[kend]:-^[[F}"
key_map[Insert]="${terminfo[kich1]:-^[[2~}"
key_map[Delete]="${terminfo[kdch1]:-^[[3~}"
key_map[BackTab]="${terminfo[kcbt]:-^[[Z}"
key_map[Ctrl-Left]="${terminfo[kLFT5]:-^[[1;5D}"
key_map[Ctrl-Right]="${terminfo[kRIT5]:-^[[1;5C}"


# ── standard editing fixes ─────────────────────────────────────────────

# Standard Backspace logic (delete character to the left).
# We use the $DEL variable (defined in zle.zsh) which handles autopair logic.
bindkey "^?" "$DEL"
bindkey "^H" "$DEL"

# Buffer Deletion Commands:
# Ctrl + U: Clear the entire line to the left of the cursor.
bindkey "^U" backward-kill-line

# Ctrl + K: Clear the entire line to the right of the cursor.
bindkey "^K" kill-line

# Ctrl + W: Delete the previous word (stops at separators defined in $WORDCHARS).
bindkey "^W" backward-kill-word

# magic-space: Expand history aliases (e.g., !! -> last command) immediately upon space.
bindkey " " magic-space

# Ensure Tab triggers completion.
bindkey '^I' complete-word


# Navigation & Cursor Movement
# ───────────────────────────────────────────────────────────────────────
## Bindings for moving the cursor efficiently across the command line.

# ------------------------------------------------------------------------------
# Character & Word Jumping

# Move one character at a time (Left/Right Arrows)
[[ -n "${key_map[Left]}" ]]  && bindkey -- "${key_map[Left]}"  backward-char
[[ -n "${key_map[Right]}" ]] && bindkey -- "${key_map[Right]}" forward-char

# Move one word at a time (Ctrl + Left/Right)
[[ -n "${key_map[Ctrl-Left]}" ]]  && bindkey -- "${key_map[Ctrl-Left]}"  backward-word
[[ -n "${key_map[Ctrl-Right]}" ]] && bindkey -- "${key_map[Ctrl-Right]}" forward-word

# ------------------------------------------------------------------------------
# Line Navigation

# Jump to start of line (Home key)
[[ -n "${key_map[Home]}" ]] && bindkey -- "${key_map[Home]}" beginning-of-line

# Jump to end of line (End key)
[[ -n "${key_map[End]}" ]]  && bindkey -- "${key_map[End]}"  end-of-line


# Deletion Logic
# ───────────────────────────────────────────────────────────────────────

# Delete the character under the cursor (Forward Delete)
[[ -n "${key_map[Delete]}" ]] && bindkey -- "${key_map[Delete]}" delete-char

# Delete from cursor to end of word (Ctrl + Delete)
bindkey '^[[3;5~' kill-word


# Smart History Search
# ───────────────────────────────────────────────────────────────────────
## Upgrades arrows to "history substring search".
## Example: Type "git", press Up -> filters for previous "git" commands.

# Bind to standard ANSI Up/Down codes (fallbacks)
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Bind to terminfo-detected codes (primary)
[[ -n "${key_map[Up]}" ]]   && bindkey -- "${key_map[Up]}"   up-line-or-beginning-search
[[ -n "${key_map[Down]}" ]] && bindkey -- "${key_map[Down]}" down-line-or-beginning-search


# Menu Selection System
# ───────────────────────────────────────────────────────────────────────
## Configuration for the tab completion menu.

# Shift + Tab: Cycle backwards through the completion menu.
[[ -n "${key_map[BackTab]}" ]] && bindkey -- "${key_map[BackTab]}" reverse-menu-complete

# ── vi-mode navigation ─────────────────────────────────────────────────
#

if [[ "${ENABLE_VI_MODE:l}" == "yes" ]]; then

    # 1. Activate Vi-Mode
    bindkey -v
    export KEYTIMEOUT=1 # Reduce delay when switching modes

    # 2. Restore standard Ctrl keys lost by 'bindkey -v'
    bindkey '^?' "$DEL"
    bindkey '^h' "$DEL"
    bindkey '^w' backward-kill-word
    bindkey '^r' history-incremental-search-backward

    # 3. Menu Navigation (hjkl) inside the completion menu
    bindkey -M menuselect 'h' vi-backward-char         # Left
    bindkey -M menuselect 'j' vi-down-line-or-history  # Down
    bindkey -M menuselect 'k' vi-up-line-or-history    # Up
    bindkey -M menuselect 'l' vi-forward-char          # Right

    # 4. Menu Control
    bindkey -M menuselect '^[' send-break  # Escape: Cancel menu
    bindkey -M menuselect '^M' accept-line # Enter: Accept selection
fi


# Custom Widgets & Macros
# ───────────────────────────────────────────────────────────────────────
## Advanced functions mapped to specific keystrokes.

# Edit Command Line: Opens current buffer in $EDITOR (Vim/Nano).
bindkey '^e' edit-command-line

# Smart Sudo Toggle: Toggles 'sudo' at start of line (Esc, Esc, Esc).
bindkey "\e\e\e" toggle_sudo_prefix

# Magic Dot: Typing '...' becomes '../..'.
bindkey '.' magic_dot_expansion

# Magic Enter: Context-aware enter (runs ls or git status on empty line).
bindkey '^M' magic_enter

# Fancy Ctrl-Z: Toggles between background and foreground jobs.
bindkey '^Z' fancy_ctrl_z

# Copy Buffer: Alt+c copies current command line to clipboard.
bindkey '^[c' copy_buffer_to_clipboard

# Git FZF Fixup: Alt+f to select a commit to fixup.
bindkey '^[f' git_fzf_fixup

# Docker Connect: Alt+s to select and connect to a running container.
bindkey '^[s' docker_connect_widget

# Keybinding: Alt + p (for 'Popup')
bindkey '^[p' pop-command

# Autosuggest Acceptance: Ctrl + Space.
bindkey '^ ' autosuggest-accept

# Expand Aliases on Space: When you type an alias and press space, it expands to the full command.
# bindkey ' ' expand-alias-on-space
