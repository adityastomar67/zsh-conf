# ------------------------[  ZSH KEY BINDINGS  ]------------------------ #

# ........................[  1. Initialization  ]........................ #

# Ensure terminfo is available for arrow key detection
zmodload zsh/terminfo

# Use a cleaner way to map keys
typeset -g -A key=(
  Up             "${terminfo[kcuu1]}"
  Down           "${terminfo[kcud1]}"
  Left           "${terminfo[kcub1]}"
  Right          "${terminfo[kcuf1]}"
  Backspace      "${terminfo[kbs]}"
  Home           "${terminfo[khome]}"
  End            "${terminfo[kend]}"
  Delete         "${terminfo[kdch1]}"
  Control-Left   "${terminfo[kLFT5]}"
  Control-Right  "${terminfo[kRIT5]}"
)

# Standard Fixes
bindkey "^?" backward-delete-char
bindkey "^U" backward-kill-line
bindkey "^W" backward-kill-word
bindkey " "  magic-space            # Expand history (e.g., !! <space>)

# ........................[  2. Smart Navigation  ]........................ #

# Word Jumping (Control + Arrows)
[[ -n "${key[Control-Left]}" ]]  && bindkey -- "${key[Control-Left]}"  backward-word
[[ -n "${key[Control-Right]}" ]] && bindkey -- "${key[Control-Right]}" forward-word

# Home/End Fixes (common in modern terminals)
[[ -n "${key[Home]}" ]] && bindkey -- "${key[Home]}" beginning-of-line
[[ -n "${key[End]}" ]]  && bindkey -- "${key[End]}"  end-of-line

# Search History by Prefix (Type 'ls' then press Up)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
[[ -n "${key[Up]}" ]]   && bindkey -- "${key[Up]}"   up-line-or-beginning-search
[[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search

# ........................[  3. Menu Selection (Vi-Style)  ]........................ #

# These only trigger when the completion menu is open
# IMPORTANT: fzf-tab uses its own keys, but these are backups for standard zsh menus
# bindkey -M menuselect 'h' vi-backward-char
# bindkey -M menuselect 'j' vi-down-line-or-history
# bindkey -M menuselect 'k' vi-up-line-or-history
# bindkey -M menuselect 'l' vi-forward-char
# bindkey -M menuselect '^g' clear-screen          # Abort menu
# bindkey -M menuselect '^i' accept-line           # Tab to accept

# ........................[  4. Custom Widgets  ]........................ #

# 1. Edit current command line in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^e' edit-command-line

# 2. Improved Sudo Toggle (handles cursor position better)
sudo-command-line() {
    [[ -z $BUFFER ]] && LBUFFER="$(fc -ln -1 | sed 's/^[[:space:]]*//')"
    if [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

# 3. Directory Stack Quick Navigation (Alt + Arrows)
# Go back/forward in directory history (cd -1, cd +1)
# bindkey '^[OA' cd -1   # Alt + Up
# bindkey '^[OB' cd +1   # Alt + Down

# ........................[  5. Terminal Mode Sync  ]........................ #

# The "Smkx" hook ensures terminal sends the correct escape codes for terminfo to work
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function _zle_smkx() { echoti smkx }
    function _zle_rmkx() { echoti rmkx }
    add-zle-hook-widget zle-line-init _zle_smkx
    add-zle-hook-widget zle-line-finish _zle_rmkx
fi
