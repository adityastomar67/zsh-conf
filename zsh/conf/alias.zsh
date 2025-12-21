# ------------------------[  ZSH ALIAS CONFIGURATION  ]------------------------ #
# This file defines shortcuts, replacements, and command enhancements.
#
# NOTE: To disable all aliases, set USE_ALIAS="No" in ~/.zshenv


# ........................[  1. Initialization  ]........................ #

# Helper: Check if a program is installed (Arch Linux specific check)
is_installed() {
    if command -v pacman &>/dev/null; then
        pacman -Qi "$1" &>/dev/null
    else
        command -v "$1" &>/dev/null
    fi
    return $?
}

# Start clean
unalias -a

# Exit if aliases are disabled in config
[[ "$USE_ALIAS" != "Yes" ]] && return


# ........................[  2. System & Privileges  ]........................ #

# Auto-sudo for common system commands
for cmd in mount umount sv pacman updatedb su shutdown poweroff reboot; do
    alias -g "$cmd"="sudo $cmd"
done
unset cmd

# Safety & Verbosity
alias mv="mv -i"
alias cp="cp -i"
alias ln="ln -i"
alias rm="rm -I"  # Prompt once before removing more than 3 files
alias chown="chown --preserve-root"
alias chmod="chmod --preserve-root"
alias chgrp="chgrp --preserve-root"
alias md="mkdir -p"
alias _="sudo "
alias please='sudo $(fc -ln -1)'  # Re-run last command with sudo


# ........................[  3. Navigation & Directories  ]........................ #

# Basic Movement
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"
alias .....="cd ../../../../"
alias ......="cd ../../../../../"
alias ~="cd ~"
alias "-"="cd -"

# Numbered Shortcuts
alias .1="cd -"
alias .2="cd -2"
alias .3="cd -3"
alias .4="cd -4"
alias .5="cd -5"

# Directory Shortcuts (Dynamic)
[ -d $DOT_PATH ]    && alias dt="cd $DOT_PATH"
[ -d ~/Projects ]   && alias pj="cd ~/Projects"
[ -d ~/Documents ]  && alias dc="cd ~/Documents"
[ -d ~/Downloads ]  && alias dl="cd ~/Downloads"
[ -d ~/Developer ]  && alias dv="cd ~/Developer"
[ -d ~/Workspace ]  && alias wk="cd ~/Workspace"


# ........................[  4. Editors & Configs  ]........................ #

alias zedit="$EDITOR ~/.zshrc"
alias bedit="$EDITOR ~/.bashrc"
alias fedit="$EDITOR ~/.config/fish/config.fish"
alias visudo="$EDITOR /etc/sudoers"

if [ -n "$XDG_NVIM" ]; then
    alias nvedit="cd $XDG_NVIM && $EDITOR init.lua"
fi

is_installed nvim  && alias vim="nvim"              && alias vimdiff="nvim -d"
is_installed emacs && alias em="/usr/bin/emacs -nw" && alias emacs="emacsclient -c -a 'emacs'"
is_installed code  && alias code="code --extensions-dir=\"$HOME/.config/Code/User/extensions\""


# ........................[  5. Utilities & Tools  ]........................ #

# Replacement Tools (Rust/Modern alternatives)
is_installed bat     && alias cat='bat'
is_installed duf     && alias df="duf" || alias df="df -h"
is_installed trash   && alias rm="trash --trash-dir='$HOME/.Trash' --recursive"
is_installed ripgrep && alias grep="ripgrep"

# Listing (ls -> eza/lsd)
if is_installed eza; then
    alias l.="eza -a | egrep '^\.'"
    alias la="eza -a --color=always --icons --group-directories-first"
    alias ll="eza -l --color=always --icons --group-directories-first"
    alias lt="eza -aT --level=2 --color=always --group-directories-first"
    alias l="eza -l --color=always --icons --git --group-directories-first"
    alias ls="eza -al --color=always --icons --git --group-directories-first"
elif is_installed lsd; then
    alias ls="lsd -a --group-directories-first"
    alias ll="lsd -la --group-directories-first"
else
    alias ls="ls --color=auto"
    alias ll="ls -la --color=auto"
fi

# Clipboard
alias copy='xsel --clipboard --input'
alias paste='xsel --clipboard --output'
alias xclip='xclip -selection clipboard'

# Networking
alias ip="curl ipinfo.io/ip"
alias ping='ping -c 5'
alias fastping='ping -c 100 -s .2'
alias gping="ping -c 5 google.com"

# Process Management
alias p="ps -f"
alias paux='ps aux | grep'
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'
alias killl='killall -q'


# ........................[  6. Package Management (Arch)  ]........................ #

if is_installed pacman; then
    # Pacman
    alias pacin="sudo pacman -S"
    alias pacrem="sudo pacman -Rns"
    alias pacupd="sudo pacman -Sy"
    alias pacupg="sudo pacman -Syu"
    alias cleanup="sudo pacman -Rns $(pacman -Qtdq)"
    alias unlock="sudo rm /var/lib/pacman/db.lck"

    # Helpers (Yay/Paru)
    if is_installed yay; then
        alias yas="yay -Syu --noconfirm"
        alias yain="yay -S"
        alias yarem="yay -Rns"
    elif is_installed paru; then
        alias update="paru -Syu --nocombinedupgrade"
    fi

    # Maintenance
    alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"
    alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
    alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
fi

# Python / Node
alias npm-up="sudo npm install npm@latest -g"
alias pip-up="sudo pip3 list --outdated | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U"


# ........................[  7. Git Configuration  ]........................ #

if is_installed git; then
    alias g="git"

    # Basics
    alias gst="git status"
    alias gss="git status -s"
    alias ga="git add"
    alias gaa="git add --all"
    alias gc="git commit -v"
    alias gcm="git commit -m"
    alias gca="git commit -v -a"

    # Branching & Checkout
    alias gb="git branch"
    alias gba="git branch -a"
    alias gco="git checkout"
    alias gcb="git checkout -b"
    alias gsw="git switch"

    # Remote Interaction
    alias gl="git pull"
    alias gp="git push"
    alias gf="git fetch"
    alias gcl="git clone --quiet"

    # History & Diff
    alias gd="git diff"
    alias glg="git log --stat"
    alias glo="git log --oneline --decorate"
    alias glog="git log --oneline --decorate --graph"
    alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"

    # Advanced
    alias grh="git reset"
    alias grhh="git reset --hard"
    alias gcp="git cherry-pick"
    alias gsta="git stash push"
    alias gstp="git stash pop"
    alias gstd="git stash drop"
    alias gstl="git stash list"
    alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'
fi


# ........................[  8. Global Output Modifiers  ]........................ #

# Global aliases allow you to put them anywhere in the command
# Example: cat file.txt G pattern  ->  cat file.txt | grep pattern

alias -g '|G'="| grep"
alias -g '|L'="| less"
alias -g '|H'="| head"
alias -g '|T'="| tail"
alias -g '|S'="| sed"
alias -g NE="2> /dev/null"
alias -g NUL="> /dev/null 2>&1"
alias -g LL="2>&1 | less"


# ........................[  9. Miscellaneous  ]........................ #

alias cls="clear"
alias h="history"
alias x="chmod +x"
alias weather='curl -s wttr.in'
alias myip="curl ipinfo.io/ip"
alias ':q'='[ -n "$TMUX" ] && tmux kill-session -t $(tmux display-message -p "#S") || exit'
alias pass-gen='openssl rand -base64'

# Time & Date
alias dday='date +"%Y.%m.%d - " | xclip -select clipboard ; date +"%Y.%m.%d"'
alias week='date +%V'

# Fun
is_installed cbonsai && alias ccbonsai="cbonsai -ilt 0.02 -c '  ,  ,  ,  ,  ' -L 5"

# vim:filetype=zsh
