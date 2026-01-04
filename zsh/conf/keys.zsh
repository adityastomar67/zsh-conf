# ------------------------[  ZSH KEY BINDINGS  ]------------------------ #
# This file configures keymaps, ZLE widgets, and terminal input modes.


# ........................[  1. Input Mode & Basics  ]........................ #

# Use Vi Mode (Change to -e for Emacs)
bindkey -v

# Standard Backspace/Delete Fixes
bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char
bindkey "^U" backward-kill-line

# History Search (Ctrl+R)
bindkey "^r" history-incremental-search-backward

# Magic Space (History expansion on space)
bindkey " " magic-space


# ........................[  2. Terminfo & Arrow Keys  ]........................ #
# Map keys using terminfo codes for better compatibility across terminals.

typeset -g -A key

key[Up]="${terminfo[kcuu1]}"
key[Down]="${terminfo[kcud1]}"
key[Left]="${terminfo[kcub1]}"
key[Right]="${terminfo[kcuf1]}"
key[Backspace]="${terminfo[kbs]}"
key[Shift-Tab]="${terminfo[kcbt]}"
key[Control-Left]="${terminfo[kLFT5]}"
key[Control-Right]="${terminfo[kRIT5]}"

# Basic Bindings
[[ -n "${key[Backspace]}" ]]     && bindkey -- "${key[Backspace]}"     backward-delete-char
[[ -n "${key[Shift-Tab]}" ]]     && bindkey -- "${key[Shift-Tab]}"     reverse-menu-complete
[[ -n "${key[Control-Left]}" ]]  && bindkey -- "${key[Control-Left]}"  backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey -- "${key[Control-Right]}" forward-word

# Smart History Search (Type + Arrow Up/Down)
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

if [[ -n "${key[Up]}" ]]; then
    bindkey -- "${key[Up]}" up-line-or-beginning-search
else
    bindkey "^k" up-line-or-beginning-search
fi

if [[ -n "${key[Down]}" ]]; then
    bindkey -- "${key[Down]}" down-line-or-beginning-search
else
    bindkey "^j" down-line-or-beginning-search
fi


# ........................[  3. Menu Selection  ]........................ #
# Use Vi keys (h/j/k/l) to navigate the tab completion menu.

# [NEW] Enable searching inside the completion menu
bindkey -M menuselect '?' history-incremental-search-forward
bindkey -M menuselect '/' history-incremental-search-backward
bindkey -M menuselect '^h' vi-backward-char
bindkey -M menuselect '^k' vi-up-line-or-history
bindkey -M menuselect '^l' vi-forward-char
bindkey -M menuselect '^j' vi-down-line-or-history
bindkey -M menuselect '^[[Z' vi-up-line-or-history


# ........................[  4. Custom Widgets  ]........................ #

# Edit the current command line in $EDITOR (Ctrl+x, Ctrl+e)
autoload -U edit-command-line
zle -N edit-command-line
bindkey "\C-x\C-e" edit-command-line

# Copy previous shell word (Ctrl+p)
bindkey "^p" copy-prev-shell-word

# Quick 'ls' (Ctrl+k) - Note: Conflicts with history search if not careful
bindkey -s '^K' 'ls^M'

# Sudo Toggle (Double Esc)
# Puts 'sudo ' at the beginning of the line, or removes it if present.
function _sudo-command-line() {
    [[ -z $BUFFER ]] && LBUFFER=$(fc -ln -1)

    # Save beginning space
    local WHITESPACE=""
    if [[ ${LBUFFER:0:1} = " " ]]; then
        WHITESPACE=" "
        LBUFFER="${LBUFFER:1}"
    fi

    if [[ $BUFFER = sudo\ * ]]; then
        LBUFFER=${BUFFER:5}
    else
        LBUFFER="sudo $LBUFFER"
    fi

    # Restore beginning space
    LBUFFER=${WHITESPACE}${LBUFFER}
}

zle -N _sudo-command-line
bindkey "\e\e" _sudo-command-line


# [NEW] Quick Reload Config (Ctrl+x)
# Checks if ZDOTDIR is set, otherwise defaults to HOME
bindkey -s '^x' '^usource "${ZDOTDIR:-$HOME}/.zshrc"\n'


# ........................[  5. Terminal Application Mode  ]........................ #
# Ensures the terminal is in the correct mode when ZLE is active.

if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function zle_application_mode_start { echoti smkx }
    function zle_application_mode_stop { echoti rmkx }
    add-zle-hook-widget -Uz zle-line-init zle_application_mode_start
    add-zle-hook-widget -Uz zle-line-finish zle_application_mode_stop
fi

