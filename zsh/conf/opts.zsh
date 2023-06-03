# █▀█ █▀█ ▀█▀ █ █▀█ █▄ █ █▀
# █▄█ █▀▀  █  █ █▄█ █ ▀█ ▄█

autoload -Uz add-zsh-hook
autoload _vi_search_fix
autoload -U colors && colors

# Load more completions
fpath=(
  $ZSH_PATH/zsh/comp
  $fpath
)

# Allow C-w to delete words separated by | or - or .
WORDCHARS='|-.'

##--> Changing the Title of the Terminals <--##
function xterm_title_precmd () {
	print -Pn -- '\e]2;%n@%m %~\a'
	[[ "$TERM" == 'screen'* ]] && print -Pn -- '\e_\005{g}%n\005{-}@\005{m}%m\005{-} \005{B}%~\005{-}\e\\'
}

function xterm_title_preexec () {
	print -Pn -- '\e]2;%n@%m %~ %# ' && print -n -- "${(q)1}\a"
	[[ "$TERM" == 'screen'* ]] && { print -Pn -- '\e_\005{g}%n\005{-}@\005{m}%m\005{-} \005{B}%~\005{-} %# ' && print -n -- "${(q)1}\e\\"; }
}

if [[ "$TERM" == (Eterm*|alacritty*|termite*|gnome*|konsole*|kterm*|putty*|rxvt*|screen*|tmux*|xterm*) ]]; then
	add-zsh-hook -Uz precmd xterm_title_precmd
	add-zsh-hook -Uz preexec xterm_title_preexec
fi

##--> Setting/Unsetting the options <--##
while read -r OPT
do
  setopt $OPT
done <<-EOF
AUTO_CD
AUTO_LIST
AUTO_MENU
AUTO_PARAM_SLASH
COMPLETE_IN_WORD
MENU_COMPLETE
HASH_LIST_ALL
ALWAYS_TO_END
LIST_PACKED
promptsubst
NOTIFY
NOHUP
MAILWARN
INTERACTIVE_COMMENTS
NOBEEP
GLOB_COMPLETE
APPEND_HISTORY
SHARE_HISTORY
INC_APPEND_HISTORY
EXTENDED_HISTORY
HIST_IGNORE_ALL_DUPS
HIST_IGNORE_SPACE
HIST_NO_FUNCTIONS
HIST_EXPIRE_DUPS_FIRST
HIST_SAVE_NO_DUPS
HIST_REDUCE_BLANKS
EOF

while read -r OPT
do
  unsetopt $OPT
done <<-EOF
FLOWCONTROL
NOMATCH
CORRECT
EQUALS
EOF

##--> Waiting dots <--##
expand-or-complete-with-dots() {
  echo -n "\e[31m…\e[0m"
  zle expand-or-complete
  zle redisplay
}
zle -N expand-or-complete-with-dots
bindkey "^I" expand-or-complete-with-dots

##--> Change cursor shape for different vi modes. <--##
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select

zle-line-init() {
    # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    zle -K viins
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[2 q' # Use beam shape cursor on startup.

preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

##--> Denying write permission for group and others <--##
umask 022
zmodload zsh/zle
zmodload zsh/zpty
zmodload zsh/complist

autoload -Uz compinit

zle -N _vi_search_fix
zle -N _sudo_command_line
zle -N _toggle-right-prompt
zle -N _toggle-left-prompt

for dump in $ZSH_PATH/zsh/zcompdump(N.mh+24); do
  compinit -d $ZSH_PATH/zsh/zcompdump
done

compinit -C -d $ZSH_PATH/zsh/zcompdump
_comp_options+=(globdots)

## On-demand rehash
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

# ==== Colors ====
local meta='%f'  # default foreground
local orange='%F{#fe8019}'
local ivory='%F{#d5c4a1}'
local green='%F{#b8bb26}'
local yellow='%F{#fabd2f}'
local red='%F{#fb4934}'
local blue='%F{#83a598}'
local magenta='%F{#d3869b}'

##--> Completion Hooks <--##
zstyle ":completion:*" sort false
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ":completion:*" special-dirs true
zstyle ":completion:*" ignored-patterns
zstyle ":completion:*" completer _complete
zstyle ':completion:*' menu select=2
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
zstyle ':completion:*' format 'Suggesting %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive tab completion

# Groups format
zstyle ':completion:*:*:*:*:corrections' format "${yellow}  ${ivory}%d${meta}"
zstyle ':completion:*:*:*:*:descriptions' format "${magenta} 硫${ivory}%d${meta}"
zstyle ':completion:*:*:*:*:messages' format "${blue}  ${ivory}%d${meta}"
zstyle ':completion:*:*:*:*:warnings' format "${red}  ${ivory}No Matches Found${meta}"

##--> Autocompletion Hooks <--##
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

# ======== General =======
# Define completers
zstyle ':completion:*' completer _extensions _complete _approximate

# Use cache for commands using cache
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZSH_PATH/zsh/zcompcache

# Highlights menu selection
zstyle ':completion:*' menu select

# Sort by modification date for every completer
zstyle ':completion:*' file-sort modification

# Disable "Display all possibilities?" message
zstyle ':completion:*' list-prompt ''

# Required for completion to be in good groups (named after the tags)
zstyle ':completion:*' group-name ''

# Groups order
zstyle ':completion:*:*:-command-:*:*' group-order aliases builtins functions commands

# Setting the style matcher-list allows you to filter the matches of the completion with even more patterns.
# See ZSHCOMPWID "completion matching control"
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# ==== Specifics ====
# Autocomplete options for cd instead of directory stack
zstyle ':completion:*' complete-options true

# Complete the alias when _expand_alias is used as a function
zstyle ':completion:*' complete true

# Expand aliases by pressing Ctrl-x a
zle -C alias-expension complete-word _generic
bindkey '^xa' alias-expension
zstyle ':completion:alias-expension:*' completer _expand_alias

# Host completions for remote connections
zstyle -e ':completion:*:(pssh|ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'

##--> A little OMZ Config <--##
HISTFILE="$ZSH_PATH/zsh/zhistory"
HISTSIZE=50000
SAVEHIST=50000
HISTTIMEFORMAT="%Y/%m/%d %H:%M:%S:   "

ZSH_AUTOSUGGEST_USE_ASYNC="true"
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor regexp root line)
ZSH_HIGHLIGHT_MAXLENGTH=512
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$color8,bold"
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

ENABLE_CORRECTION="true"
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="mm/dd/yyyy"

# Complete zoxide with dirs only
compdef _dirs z

# vim:filetype=zsh
