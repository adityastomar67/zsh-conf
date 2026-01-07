# ........................[  1. Core Shell Options  ]........................ #

# Load binary modules first (fastest)
zmodload zsh/zle
zmodload zsh/zpty
zmodload zsh/complist

# Autoload shell functions
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
autoload -U colors && colors

# Basic Permissions & Input settings
umask 022
WORDCHARS='|-.'

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
export HISTFILE="${ZDOTDIR:-$HOME}/zhistory"
HISTSIZE=50000
SAVEHIST=50000
HISTTIMEFORMAT="%Y/%m/%d %H:%M:%S:   "
HIST_STAMPS="mm/dd/yyyy"
export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"

# General Job Control & Feedback
setopt NOTIFY                  # Report status of background jobs immediately
setopt NOHUP                   # Don't kill background jobs on exit
setopt MAILWARN                # Print mail warning message
setopt INTERACTIVE_COMMENTS    # Allow comments in interactive shell
setopt ALWAYS_TO_END           # Move cursor to end of word after completion
setopt NOBEEP                  # No beep on error

# 1. Performance Tweak: Fast Syntax Highlighting
#    (Define these even if the plugin isn't loaded yet; they are global vars)
typeset -gA FAST_HIGHLIGHT
FAST_HIGHLIGHT[chroma-git]=0
FAST_HIGHLIGHT[chroma-man]=0
FAST_HIGHLIGHT[use_async]=1

# 2. Misc Flags
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
COMPLETION_WAITING_DOTS="true"
KEYTIMEOUT=1


# ........................[  2. Completion System  ]........................ #

# Initialize compinit with modern performance check (only once per 24h or on change)
## Initialize Completion (Only if not already done by plugin manager)
if [[ -z "$_comp_initialized" ]]; then
    autoload -Uz compinit
    # Check cache once a day
    if [[ -s "$ZSH_COMPDUMP" && (! "$ZSH_COMPDUMP" -nt "${ZDOTDIR:-$HOME}/.zshrc") ]]; then
        compinit -C -d "$ZSH_COMPDUMP"
    else
        compinit -i -d "$ZSH_COMPDUMP"
    fi
    _comp_initialized=1
fi

## Completions
# 1. Caching (Fixed)
# Ensure the cache path is a DIRECTORY, not the dump file.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"

# 2. Matching (Improved)
# Pass 1: Exact match ('' returns if exact match found)
# Pass 2: Case insensitive (a=A)
# Pass 3: Partial matching before/after cursor (f-b -> foo-bar)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# 3. Sorting & Grouping (Better UX)
# Don't use "sort false" globally; it messes up file listings.
# Instead, group directories first (like standard file managers).
zstyle ':completion:*' list-dirs-first true

# 4. Interaction
# Allow selecting items with arrow keys (Menu Select)
zstyle ':completion:*' menu select

## Completions Stylings
# 1. Group Descriptions (e.g. "Files", "Aliases")
#    Format: Magenta Arrow -> Bold Text
zstyle ':completion:*:*:*:*:descriptions' format \
    "${Colors[Magenta]} ${Colors[Bold]}%d${Colors[Off]}${Colors[Reset]}"

# 2. Corrections (e.g. "Did you mean...")
zstyle ':completion:*:*:*:*:corrections' format \
    "${Colors[Yellow]} %d${Colors[Reset]}"

# 3. System Messages
zstyle ':completion:*:*:*:*:messages' format \
    "${Colors[Blue]} %d${Colors[Reset]}"

# 4. Warnings (e.g. "No matches")
zstyle ':completion:*:*:*:*:warnings' format \
    "${Colors[Red]} No Matches Found${Colors[Reset]}"

# 5. Default Fallback
zstyle ':completion:*' format \
    "${Colors[Ivory]}Suggesting: %d${Colors[Reset]}"


# ........................[  3. Fzf-tab Refinement  ]........................ #

# Check if FZF is installed before configuring it
if is_installed fzf; then

    # 1. Global FZF Options (Colors & Keybindings)
    #    Applied to: Ctrl-T, Alt-C, and fzf-tab
    export FZF_DEFAULT_OPTS="
    --color fg:#d4d4d5,fg+:#f5c9c9,bg+:-1,hl:#0080ff,hl+:#FCE700
    --color info:#79dcaa,prompt:#00788A,spinner:#3877ff,pointer:#d4d4d5
    --color marker:#ffe59e,border:#101317,gutter:-1,header:#949494
    --bind 'ctrl-j:preview-down,ctrl-k:preview-up,ctrl-a:select-all'
    --bind 'ctrl-y:execute-silent(echo {+} | $CLIP_CMD)'
    --bind 'ctrl-e:execute(echo {+} | xargs -o nvim)'
    --bind 'ctrl-v:execute(code {+})'
    --bind 'tab:down,shift-tab:up'
    --prompt '  ' --pointer ' ' --border none --height 40% --layout=reverse
    "

    # 2. Default Command Logic (Prioritize rg > fd > find)
    if is_installed rg; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!node_modules/*"'
    elif is_installed fd; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'
    else
        export FZF_DEFAULT_COMMAND='find . -type f'
    fi

    # 3. Widget Specific Options
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_CTRL_T_OPTS="
    --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {} 2>/dev/null || tree -C {} 2>/dev/null'
    --bind 'ctrl-/:toggle-preview'
    "
    export FZF_ALT_C_OPTS="
    --preview 'eza --tree --color=always {} | head -200'
    "

    # ........................[  2. Fzf-Tab Configuration  ]........................ #
    # Only configure fzf-tab if fzf is present (as it depends on it)

    # 1. Behavior
    zstyle ':fzf-tab:*' continuous-trigger '/'

    # 2. Styling (Minimal - inherits FZF_DEFAULT_OPTS colors)
    zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse

    # 3. Context-Aware Previews
    zstyle ':fzf-tab:complete:cd:*' fzf-preview \
        'eza -1 --icons=always --color=always --group-directories-first $realpath'

    zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview \
        'SYSTEMD_COLORS=1 systemctl status $word'

    zstyle ':fzf-tab:complete:(-command-):*' fzf-preview \
        '[[ -n $builtins[$word] ]] && man $word || bat --color=always --style=plain $realpath 2>/dev/null'

fi

# Autosuggestions (Variables)
ZSH_AUTOSUGGEST_USE_ASYNC="true"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,bold"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Autocomplete (Zstyle)
local ZAP_AC_DIR="$HOME/.local/share/zap/plugins/marlonrichert/zsh-autocomplete"
if [[ -d "$ZAP_AC_DIR" ]]; then
    zstyle ':autocomplete:history-search:*' list-lines 16
    zstyle ':autocomplete:history-incremental-search-*:*' list-lines 16
    zstyle ':autocomplete:*' default-context ''
    zstyle ':autocomplete:*' min-delay 0.05
    zstyle ':autocomplete:*' min-input 1
    zstyle ':autocomplete:*' ignored-input ''
    zstyle ':autocomplete:*' list-lines 16
    zstyle ':autocomplete:*' recent-dirs cdr
    zstyle ':autocomplete:*' insert-unambiguous no
    zstyle ':autocomplete:*' widget-style complete-word
    zstyle ':autocomplete:*' fzf-completion no
    zstyle ':autocomplete:*' add-space executables aliases functions builtins reserved-words commands
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
