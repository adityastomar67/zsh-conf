# ........................[  1. Core Shell Options  ]........................ #

# Navigation
setopt AUTO_CD
setopt AUTO_LIST
setopt AUTO_PARAM_SLASH
setopt LIST_PACKED

# Completion Behavior (Updated for 2026)
setopt COMPLETE_IN_WORD
setopt GLOB_COMPLETE
setopt HASH_LIST_ALL
setopt EXTENDED_GLOB
setopt GLOB_DOTS
setopt ALWAYS_TO_END
unsetopt MENU_COMPLETE      # Disable this: Let fzf-tab/autocomplete handle the insertion
unsetopt FLOWCONTROL
unsetopt NOMATCH
unsetopt CORRECT

# History (Modern High-Performance)
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY_TIME
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# ........................[  2. Completion System  ]........................ #

# Initialize compinit with modern performance check (only once per 24h or on change)
# () {
  if [[ -s "$ZSH_COMPDUMP" && (! "$ZSH_COMPDUMP" -nt "${ZDOTDIR:-$HOME}/.zshrc") ]]; then
    autoload -Uz compinit && compinit -C -d "$ZSH_COMPDUMP"
  else
    autoload -Uz compinit && compinit -i -d "$ZSH_COMPDUMP"
  fi
# }

# General Styles
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zstyle ':completion:*' sort false
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# UI Styling (Unified Theme)
() {
    local c_meta='%f' c_ivory='%F{#d5c4a1}' c_accent='%F{#d3869b}'
    local c_warn='%F{#fabd2f}' c_err='%F{#fb4934}' c_note='%F{#83a598}'
    local i_warn='  ' i_desc='  ' i_note='  ' i_err='  '

    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*:descriptions' format "${c_accent}${i_desc} ${c_ivory}%d${c_meta}"
    zstyle ':completion:*:corrections'  format "${c_warn}${i_warn} ${c_ivory}%d (errors: %e)${c_meta}"
    zstyle ':completion:*:messages'     format "${c_note}${i_note} ${c_ivory}%d${c_meta}"
    zstyle ':completion:*:warnings'     format "${c_err}${i_err} ${c_ivory}No Matches Found${c_meta}"
}

# ........................[  3. Fzf-tab Refinement  ]........................ #

# Ensure fzf-tab doesn't flicker with zsh-autocomplete
zstyle ':fzf-tab:*' continuous-trigger '/' # Use / to descend into dirs without leaving fzf
zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border --ansi

# Context-aware previews
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=always --color=always $realpath'
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
zstyle ':fzf-tab:complete:(-command-):*' fzf-preview '[[ -n $builtins[$word] ]] && man $word || bat --color=always --style=plain $realpath 2>/dev/null'

# ........................[  4. Fast Rehash (Arch)  ]........................ #

if [[ -f /etc/arch-release ]]; then
    # Optimization: Check pacman log instead of creating a custom trigger file
    rehash_precmd() {
        if [[ /var/lib/pacman/db.lck -nt /proc/self/fd/0 ]]; then rehash; fi
    }
    add-zsh-hook precmd rehash_precmd
fi
