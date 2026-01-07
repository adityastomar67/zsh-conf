# ------------------------[  ZSH KEY BINDINGS (2026)  ]------------------------ #
# Optimized for modern terminals (Ghostty, WezTerm, Alacritty, Kitty).
#
# OS NOTES:
# - Linux: Keys usually work out of the box.
# - macOS: 'Option' key behavior varies. Ensure your terminal is set to treat
#          Option as 'Meta' or 'Esc+' for Alt bindings to work.
#          'Ctrl+Arrows' often conflict with Mission Control (Spaces); disable
#          those in System Settings -> Keyboard -> Shortcuts if needed.


# ........................[  1. Initialization & Key Map  ]........................ #

# Load the Terminfo module. This allows Zsh to ask the terminal "What code do you send
# when the Up arrow is pressed?" rather than guessing.
zmodload zsh/terminfo

# Define a dictionary of Keys -> Hex/ANSI Codes.
# We try to get the code from 'terminfo'. If that fails (e.g., on a bare SSH connection),
# we fall back to the hardcoded ANSI standard defaults (after the ':-').
typeset -g -A key
key[Up]="${terminfo[kcuu1]:-^[[A}"             # Arrow Up
key[Down]="${terminfo[kcud1]:-^[[B}"           # Arrow Down
key[Left]="${terminfo[kcub1]:-^[[D}"           # Arrow Left
key[Right]="${terminfo[kcuf1]:-^[[C}"          # Arrow Right
key[Home]="${terminfo[khome]:-^[[H}"           # Home Key (Fn+Left on Mac)
key[End]="${terminfo[kend]:-^[[F}"             # End Key (Fn+Right on Mac)
key[Insert]="${terminfo[kich1]:-^[[2~}"        # Insert Key
key[Delete]="${terminfo[kdch1]:-^[[3~}"        # Forward Delete (Fn+Backspace on Mac)
key[BackTab]="${terminfo[kcbt]:-^[[Z}"         # Shift + Tab
key[Ctrl-Left]="${terminfo[kLFT5]:-^[[1;5D}"   # Ctrl + Arrow Left
key[Ctrl-Right]="${terminfo[kRIT5]:-^[[1;5C}"  # Ctrl + Arrow Right

# --- Standard Zsh Text Editing Fixes ---
# Action: Delete character to the left
# Key: Backspace (Mac/Linux)
bindkey "^?" backward-delete-char

# Action: Delete character to the left (Legacy compat)
# Key: Ctrl + H (Mac/Linux)
bindkey "^H" backward-delete-char

# Action: Delete everything from cursor to start of line
# Key: Ctrl + U (Mac/Linux)
bindkey "^U" backward-kill-line

# Action: Delete everything from cursor to end of line
# Key: Ctrl + K (Mac/Linux)
bindkey "^K" kill-line

# Action: Delete previous word (stops at spaces/slashes based on WORDCHARS)
# Key: Ctrl + W (Mac/Linux)
bindkey "^W" backward-kill-word

# Action: Expand history aliases (e.g., !! expands to last command)
# Key: Spacebar (Mac/Linux)
bindkey " "  magic-space


# ........................[  2. Smart Navigation  ]........................ #

# --- Basic Cursor Movement ---
# Action: Move cursor one character left/right
# Key: Left / Right Arrows
[[ -n "${key[Left]}" ]]  && bindkey -- "${key[Left]}"  backward-char
[[ -n "${key[Right]}" ]] && bindkey -- "${key[Right]}" forward-char

# --- Word Jumping ---
# Action: Jump cursor one word left/right
# Key: Ctrl + Left / Ctrl + Right
# Note (Mac): By default, Ctrl+Arrows switch desktops. You must disable that in
#             System Settings or map 'Option+Arrows' to send these codes in iTerm2/WezTerm.
[[ -n "${key[Ctrl-Left]}" ]]  && bindkey -- "${key[Ctrl-Left]}"  backward-word
[[ -n "${key[Ctrl-Right]}" ]] && bindkey -- "${key[Ctrl-Right]}" forward-word

# --- Line Navigation ---
# Action: Jump to very beginning or very end of the line
# Key: Home (Fn+Left on Mac) / End (Fn+Right on Mac)
[[ -n "${key[Home]}" ]] && bindkey -- "${key[Home]}" beginning-of-line
[[ -n "${key[End]}" ]]  && bindkey -- "${key[End]}"  end-of-line

# --- Modern Deletion ---
# Action: Forward delete (delete character under cursor)
# Key: Delete (Fn+Backspace on Mac)
[[ -n "${key[Delete]}" ]] && bindkey -- "${key[Delete]}" delete-char

# Action: Kill word forward (delete from cursor to end of word)
# Key: Ctrl + Delete (Mac users might need to map Option+Delete to send this code)
bindkey '^[[3;5~' kill-word

# --- History Search (The "Magic" Up Arrow) ---
# Action: Filters history based on what you have already typed.
# Example: Type "git c", press Up, and it only shows commands starting with "git c".
# Key: Up Arrow / Down Arrow
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search      # ANSI Up
bindkey '^[OA' up-line-or-beginning-search      # Terminfo Up
[[ -n "${key[Up]}" ]] && bindkey -- "${key[Up]}" up-line-or-beginning-search

bindkey '^[[B' down-line-or-beginning-search    # ANSI Down
bindkey '^[OB' down-line-or-beginning-search    # Terminfo Down
[[ -n "${key[Down]}" ]] && bindkey -- "${key[Down]}" down-line-or-beginning-search


# ........................[  3. Menu Selection & Completion  ]........................ #

# Action: Cycle backwards through completion menu
# Key: Shift + Tab (Mac/Linux)
[[ -n "${key[BackTab]}" ]] && bindkey -- "${key[BackTab]}" reverse-menu-complete

# Action: Enable Vi-style navigation inside the Tab completion menu
# Notes: Once you press Tab and the menu appears:
#   - 'h' moves left, 'l' moves right
#   - 'j' moves down, 'k' moves up
#   - 'Enter' accepts, 'Esc' cancels
zmodload zsh/complist
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect '^[' send-break         # Escape Key
bindkey -M menuselect '^M' accept-line        # Enter Key


# ........................[  4. Custom Widgets  ]........................ #

# --- 1. Edit in Editor ---
# Action: Opens the current command line in Vim/Nano/VSCode (based on $EDITOR)
#         Great for editing long, complex commands.
# Key: Ctrl + E (Mac/Linux)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^e' edit-command-line

# --- 2. Smart Sudo Toggle ---
# Action:
#   - If line is empty: Puts 'sudo' before the LAST command run.
#   - If line has text: Toggles 'sudo' at the start of the CURRENT line.
# Key: Esc pressed twice fast (Esc, Esc)
sudo-command-line() {
    if [[ -z $BUFFER ]]; then
        LBUFFER="sudo $(fc -ln -1)"
    elif [[ $BUFFER == sudo\ * ]]; then
        LBUFFER="${LBUFFER#sudo }"
    else
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N sudo-command-line
bindkey "\e\e" sudo-command-line

# --- 3. Autosuggestion Integration ---
# Action: Accepts the gray ghost-text suggestion offered by zsh-autosuggestions.
# Key: Ctrl + Space
# Note (Mac): Ctrl+Space is default for Input Sources/Spotlight. You may need to
#             change this binding here or disable the macOS shortcut.
if [[ -n "${aliases[zsh-autosuggestions]}" || -f "$ZSH_AUTOSUGGEST_MANUAL_REBIND" ]]; then
    bindkey '^ ' autosuggest-accept
fi


# ........................[  5. Terminal Sync Hooks  ]........................ #

# Action: Ensures the terminal is in "Application Mode" when ZLE is active.
# Use Case: Fixes issues where pressing Up/Down in Zsh works, but pressing them
#           inside Vim/Nano prints garbage like "^[[A".
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function _zle_smkx() { echoti smkx }
    function _zle_rmkx() { echoti rmkx }
    add-zle-hook-widget zle-line-init _zle_smkx
    add-zle-hook-widget zle-line-finish _zle_rmkx
fi
