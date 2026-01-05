# ------------------------[  ZSH SHELL OPTIONS  ]------------------------ #
# This file configures the core behavior of Zsh (options, completion, history).


# ........................[  1. Initialization & Modules  ]........................ #

# Initialize core modules once
autoload -Uz vcs_info
autoload -Uz add-zsh-hook
autoload -U colors && colors
autoload _vi_search_fix

# Faster completion loading (Cache check once a day)
autoload -Uz compinit

# Check if the dump file exists (-f) to decide whether to regenerate or use cache (-C)
if [[ -f "$ZSH_COMPDUMP" ]]; then
  # File exists: Use cache (-C) and specify path (-d)
  compinit -C -d "$ZSH_COMPDUMP"
else
  # File missing: Full build and specify path (-d)
  compinit -d "$ZSH_COMPDUMP"
fi

# Load Zsh Modules
zmodload zsh/zle
zmodload zsh/zpty
zmodload zsh/complist


# Permissions mask
umask 022

# Word Characters (Allow Ctrl+w to delete parts of paths/IPs)
WORDCHARS='|-.'


# ........................[  2. Terminal Title  ]........................ #

function xterm_title_precmd() {
    print -Pn -- '\e]2;%n@%m %~\a'
    [[ "$TERM" == 'screen'* ]] && print -Pn -- '\e_\005{g}%n\005{-}@\005{m}%m\005{-} \005{B}%~\005{-}\e\\'
}

function xterm_title_preexec() {
    print -Pn -- '\e]2;%n@%m %~ %# ' && print -n -- "${(q)1}\a"
    [[ "$TERM" == 'screen'* ]] && { print -Pn -- '\e_\005{g}%n\005{-}@\005{m}%m\005{-} \005{B}%~\005{-} %# ' && print -n -- "${(q)1}\e\\"; }
}

case "$TERM" in
    Eterm*|alacritty*|termite*|gnome*|konsole*|kterm*|putty*|rxvt*|screen*|tmux*|xterm*)
        add-zsh-hook -Uz precmd xterm_title_precmd
        add-zsh-hook -Uz preexec xterm_title_preexec
        ;;
esac


# ........................[  3. Zsh Options (Setopt)  ]........................ #

# Navigation & Listing
setopt AUTO_CD                 # cd by typing directory name
setopt AUTO_LIST               # List choices on ambiguous completion
setopt AUTO_MENU               # Show completion menu on successive tab press
setopt AUTO_PARAM_SLASH        # Tab completing directory appends a slash
setopt LIST_PACKED             # Compact completion list
   
# Completion Behavior   
setopt COMPLETE_IN_WORD        # Complete from both ends of a word
setopt MENU_COMPLETE           # Insert first match immediately
setopt GLOB_COMPLETE           # Show autocompletion menu with globs
setopt HASH_LIST_ALL           # Hash entire command path first
setopt EXTENDED_GLOB           # Use extended globbing syntax
setopt GLOB_DOTS               # files beginning with a . are matched without explicitly specifying the dot

# History
setopt APPEND_HISTORY          # Append history instead of replacing
setopt SHARE_HISTORY           # Share history between sessions
setopt INC_APPEND_HISTORY      # Write to history file immediately
setopt INC_APPEND_HISTORY_TIME # Add timestamps to history
setopt EXTENDED_HISTORY        # Save timestamp and duration
setopt HIST_IGNORE_ALL_DUPS    # Remove older duplicate entries
setopt HIST_IGNORE_SPACE       # Don't save commands starting with space
setopt HIST_NO_FUNCTIONS       # Don't save function definitions
setopt HIST_EXPIRE_DUPS_FIRST  # Expire duplicates first when trimming
setopt HIST_SAVE_NO_DUPS       # Don't write duplicates to history file
setopt HIST_REDUCE_BLANKS      # Remove superfluous blanks
setopt HIST_VERIFY             # Don't execute immediately upon history expansion
setopt BANG_HIST               # Treat the '!' character specially during expansion

# General
setopt NOTIFY                  # Report status of background jobs immediately
setopt NOHUP                   # Don't kill background jobs on exit
setopt MAILWARN                # Print mail warning message
setopt INTERACTIVE_COMMENTS    # Allow comments in interactive shell
setopt ALWAYS_TO_END           # Move cursor to end of word after completion
setopt NOBEEP                  # No beep on error

# Disable unwanted features
unsetopt FLOWCONTROL           # Disable start/stop characters (Ctrl-S/Ctrl-Q)
unsetopt NOMATCH               # Don't print error on no match (pass glob to command)
unsetopt CORRECT               # Disable spelling correction
unsetopt EQUALS                # Disable =filename expansion


# ........................[  4. ZLE & Cursor  ]........................ #

# Waiting Dots (Visual feedback during slow completion)
expand-or-complete-with-dots() {
    echo -n "\e[31m…\e[0m"
    zle expand-or-complete
    zle redisplay
}
zle -N expand-or-complete-with-dots
bindkey "^I" expand-or-complete-with-dots

# Cursor Shape (Beam for insert, Block for normal)
function set_cursor_shape() {
    echo -ne "$1"
}

function zle-keymap-select() {
    case $KEYMAP in
        vicmd)      set_cursor_shape '\e[1 q' ;; # Block
        viins|main) set_cursor_shape '\e[5 q' ;; # Beam
    esac
}
zle -N zle-keymap-select

zle-line-init() {
    zle -K viins
    set_cursor_shape '\e[5 q'
}
zle -N zle-line-init

# Reset cursor on startup/new prompt
set_cursor_shape '\e[2 q'
preexec() { set_cursor_shape '\e[5 q'; }

# Register Custom Widgets
zle -N _vi_search_fix
zle -N _sudo_command_line
zle -N _toggle-right-prompt
zle -N _toggle-left-prompt


# ........................[  5. Completion System  ]........................ #

# On-demand Rehash (Only run this on Arch Linux)
if [[ -f /etc/arch-release ]]; then
    zshcache_time="$(date +%s%N)"
    rehash_precmd() {
        if [[ -a /var/cache/zsh/pacman ]]; then
            local paccache_time="$(date -r /var/cache/zsh/pacman +%s%N)"
            if (( zshcache_time < paccache_time )); then
                rehash
                zshcache_time="$paccache_time"
            fi
        fi
    }
    add-zsh-hook -Uz precmd rehash_precmd
fi

# --- Unified Zstyle Configuration ---

# 1. Base Options
zstyle ":completion:*" sort false
zstyle ":completion:*" special-dirs true
zstyle ":completion:*" ignored-patterns
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' verbose true
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' complete-options true
zstyle ':completion:*' complete true

# 2. Matchers & Completers
# Combine _extensions, _complete, _correct, and _approximate
zstyle ':completion:*' completer _extensions _complete _correct _approximate
# Case insensitive matching (hyphen/underscore tolerant)
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# 3. Menu & UI
zstyle ':completion:*' menu select=2
zstyle ':completion:*' list-prompt '' # Disable "Display all possibilities?"
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s

# 4. Grouping & Formatting
zstyle ':completion:*' group-name ''
zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands
zstyle ':completion:*' file-sort modification

# Colors for groups
local meta='%f' orange='%F{#fe8019}' ivory='%F{#d5c4a1}'
local green='%F{#b8bb26}' yellow='%F{#fabd2f}' red='%F{#fb4934}'
local blue='%F{#83a598}' magenta='%F{#d3869b}'

zstyle ':completion:*' format 'Suggesting %d'
zstyle ':completion:*:*:*:*:corrections' format "${yellow}  ${ivory}%d${meta}"
zstyle ':completion:*:*:*:*:descriptions' format "${magenta} 硫${ivory}%d${meta}"
zstyle ':completion:*:*:*:*:messages'     format "${blue}  ${ivory}%d${meta}"
zstyle ':completion:*:*:*:*:warnings'     format "${red}  ${ivory}No Matches Found${meta}"

# 5. Specific Completions
# Alias Expansion Widget (Ctrl-x a)
zle -C alias-expension complete-word _generic
bindkey '^xa' alias-expension
zstyle ':completion:alias-expension:*' completer _expand_alias

# SSH/Remote Hosts
zstyle -e ':completion:*:(pssh|ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

# 6. Fzf-tab styling
zstyle ':fzf-tab:*' fzf-flags --style=full --height=90% --pointer '>' \
                --color 'pointer:green:bold,bg+:-1:,fg+:green:bold,info:blue:bold,marker:yellow:bold,hl:gray:bold,hl+:yellow:bold' \
                --input-label ' Search ' --color 'input-border:blue,input-label:blue:bold' \
                --list-label ' Results ' --color 'list-border:green,list-label:green:bold' \
                --preview-label ' Preview ' --color 'preview-border:magenta,preview-label:magenta:bold'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons=always --color=always -a $realpath'
zstyle ':fzf-tab:complete:eza:*' fzf-preview 'eza -1 --icons=always --color=always -a $realpath'
zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --color=always --theme=base16 $realpath'
zstyle ':fzf-tab:*' fzf-bindings 'space:accept'

# Zoxide
if is_installed z; then
    compdef _dirs z
fi


# ........................[  6. Autocomplete Plugin Hooks  ]........................ #
# These settings apply if using zsh-autocomplete plugin
## Define where Zap installs the plugins
local ZAP_AC_DIR="$HOME/.local/share/zap/plugins/marlonrichert/zsh-autocomplete"

# --- LOGIC SWITCH ---
if [[ -d "$ZAP_AC_DIR" ]]; then
    zstyle ':autocomplete:*' default-context ''
    zstyle ':autocomplete:*' min-delay 0.05
    zstyle ':autocomplete:*' min-input 1
    zstyle ':autocomplete:*' ignored-input ''
    zstyle ':autocomplete:*' list-lines 16
    zstyle ':autocomplete:history-search:*' list-lines 16
    zstyle ':autocomplete:history-incremental-search-*:*' list-lines 16
    zstyle ':autocomplete:*' recent-dirs cdr
    zstyle ':autocomplete:*' insert-unambiguous no
    zstyle ':autocomplete:*' widget-style complete-word
    zstyle ':autocomplete:*' fzf-completion no
    zstyle ':autocomplete:*' add-space executables aliases functions builtins reserved-words commands
fi

# ........................[  7. History & Syntax Highlighting  ]........................ #

# History File Configuration
export HISTFILE="${ZDOTDIR:-$HOME}/zhistory"
HISTSIZE=50000
SAVEHIST=50000
HISTTIMEFORMAT="%Y/%m/%d %H:%M:%S:   "
HIST_STAMPS="mm/dd/yyyy"
HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"

# Syntax Highlighting & Autosuggestions
ZSH_AUTOSUGGEST_USE_ASYNC="true"
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor regexp root line)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_HIGHLIGHT_MAXLENGTH=512
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,bold"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

# Misc Flags
ENABLE_CORRECTION="true"
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
COMPLETION_WAITING_DOTS="true"
KEYTIMEOUT=1

