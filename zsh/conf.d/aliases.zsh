#    ░█▀█░█░░░▀█▀░█▀█░█▀▀░█▀▀░█▀▀░░░░▀▀█░█▀▀░█░█
#    ░█▀█░█░░░░█░░█▀█░▀▀█░█▀▀░▀▀█░░░░▄▀░░▀▀█░█▀█
#    ░▀░▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This file acts as the primary registry for shell aliases (shortcuts).
#   It maps short commands to longer, complex sequences to improve productivity
#   and safety.
#
# Problems Solved
#   - Reduces keystrokes for common commands (e.g., `git status` -> `gst`).
#   - Adds safety nets to destructive commands (e.g., `rm` -> `rm -i`).
#   - Standardizes behavior across different operating systems (macOS vs Linux).
#   - Integrates modern tools (bat, eza, nvim) transparently.
#
# Features / Responsibilities
#   - System Privilege Aliases (sudo wrappers).
#   - Navigation Shortcuts (.., ..., ~).
#   - Modern Tool Replacements (ls -> eza).
#   - Extensive Git Shortcuts.
#   - Global Aliases (Pipe expansions).
#
# Usage Notes
#   To disable this entire file, set `LOAD_CUSTOM_ALIASES="No"` in $ZDOTDIR/.zshenv.
# ------------------------------------------------------------------------------


# Initialization
# ───────────────────────────────────────────────────────────────────────
## Preparation steps: Feature flags, clean slate, and OS detection.

# 1. Feature Guard
# Exit immediately if the user has disabled aliases in the main config.
# Note: ${LOAD_CUSTOM_ALIASES} was renamed in 'user.conf'
if [[ "${LOAD_CUSTOM_ALIASES:l}" != "yes" ]]; then
    return
fi

# 2. Reset: Remove all existing aliases to prevent conflicts or stale definitions.
unalias -a

# 3. Environment Detection
# Capture the kernel name to handle OS-specific flags (Darwin vs Linux).
local detected_os
detected_os=$(uname -s)


# System & Privileges
# ───────────────────────────────────────────────────────────────────────
## Wrappers for administrative commands and safety features.

# ------------------------------------------------------------------------------
# Auto-Sudo (Linux Only)
# On Linux, system commands almost always require root. This wrapper adds
# 'sudo' automatically to specific commands to save typing.
if [[ "$detected_os" == "Linux" ]]; then
    for sys_cmd in mount umount sv updatedb su shutdown poweroff reboot; do
        alias "$sys_cmd"="sudo $sys_cmd"
    done
    unset sys_cmd
fi

# ------------------------------------------------------------------------------
# Map 'history' to the underlying 'fc' command with a custom format
# -l: list
# -t: time format (takes the string arguments)
alias history="fc -l -t '%Y/%m/%d %H:%M:%S:   '"

# ----------------------------------------------------------------------------
# Man Page Fuzzy Finder
# Uses fzf to search and preview man pages interactively.
# Requires 'fzf' to be installed.
is_installed fzf && alias man="fzf-man"

# ------------------------------------------------------------------------------
# Safety Nets
# Force interactive mode (-i) to prompt before destructive actions.
alias mv="mv -i"
alias cp="cp -i"
alias ln="ln -i"
alias rm="rm -i"      # "Are you sure?" prompt for deletions

# ------------------------------------------------------------------------------
# Admin Helpers
alias md="mkdir -p"   # Create parent directories automatically
alias _="sudo"        # Quick sudo shorthand

# "The Magic Fixer"
# Re-runs the last command in history ($(fc ...)) prepended with sudo.
alias please='sudo $(fc -ln -1)'

# ------------------------------------------------------------------------------
# GNU/BSD Compatibility
# Linux specific flags that don't exist on macOS/BSD.
if [[ "$detected_os" == "Linux" ]]; then
    alias chown="chown --preserve-root"
    alias chmod="chmod --preserve-root"
    alias chgrp="chgrp --preserve-root"
fi

# ------------------------------------------------------------------------------
# Shell Management
# 'exec zsh' replaces the current process, reloading the config cleanly.
alias zsh="exec zsh"
alias which='type -a' # 'type -a' is more robust in Zsh than 'which'


# Navigation & Directories
# ───────────────────────────────────────────────────────────────────────
## Shortcuts for moving around the file system.

# ------------------------------------------------------------------------------
# Quick Jumps
alias ~="cd ~"        # Go Home
alias "-"="cd -"      # Go to Previous Directory

# Numbered Shortcuts (Zsh Directory Stack)
alias .1="cd -"
alias .2="cd -2"
alias .3="cd -3"
alias .4="cd -4"
alias .5="cd -5"

# ------------------------------------------------------------------------------
# Dynamic Bookmarks
# Only create these aliases if the target directory actually exists.

# Note: DOTFILES_ROOT is defined in '$ZDOTDIR/.zshenv' (formerly DOT_PATH)
[[ -d "${DOTFILES_ROOT}" ]] && alias dt="cd ${DOTFILES_ROOT}"

[[ -d ~/Projects ]]   && alias pj="cd ~/Projects"
[[ -d ~/Documents ]]  && alias dc="cd ~/Documents"
[[ -d ~/Downloads ]]  && alias dl="cd ~/Downloads"
[[ -d ~/Developer ]]  && alias dv="cd ~/Developer"
[[ -d ~/Workspace ]]  && alias wk="cd ~/Workspace"


# Editors & Configurations
# ───────────────────────────────────────────────────────────────────────
## Shortcuts for editing configuration files and selecting editors.

# Pass the target file to the helper function
alias zedit='_safe_edit ~/.zshrc'
alias bedit='_safe_edit ~/.bashrc'
alias fedit='_safe_edit ~/.config/fish/config.fish'

# SAFETY FIX:
# 1. We map 'visudo' to use sudo (since regular users can't read /etc/sudoers)
# 2. We trigger the check function to ensure the file is there first.
alias visudo='_safe_edit /etc/sudoers true'

# Neovim Config Jump
if [[ -n "$XDG_NVIM" ]]; then
    alias nvedit="cd $XDG_NVIM && $EDITOR init.lua"
fi

# Modern Editor Replacements
# If Neovim is installed, make 'vim' use it.
is_installed nvim  && alias vim="nvim" \
                   && alias vimdiff="nvim -d" \
                   && alias v="nvim"

# If Emacs is installed, try to use the client for speed.
is_installed emacs && alias em="/usr/bin/emacs -nw" \
                   && alias emacs="emacsclient -c -a 'emacs'"

# VS Code Wrapper (forces specific extension usage)
# is_installed code  && alias code="code --extensions-dir '$HOME/.config/Code/User/extensions'"


# Utilities & Tools
# ───────────────────────────────────────────────────────────────────────
## Replacing legacy unix tools with modern Rust/Go alternatives.

# ------------------------------------------------------------------------------
# Modern Replacements

# 'cat' -> 'bat' (Syntax highlighting)
is_installed bat     && alias cat='bat'

# 'df' -> 'duf' (Disk Usage / Free utility)
is_installed duf     && alias df="duf" || alias df="df -h"

# 'rm' -> 'trash' (Moves to trash instead of permanent delete)
is_installed trash   && alias del="trash"

# 'grep' -> 'ripgrep' (Much faster search)
is_installed ripgrep && alias grep="ripgrep"

# ------------------------------------------------------------------------------
# Listing (The 'ls' Hierarchy)
# Logic: Try 'eza' (best), then 'lsd' (good), then native 'ls' (fallback).

if is_installed eza; then
    # General Options used in all aliases
    #   --group-directories-first : Folders on top
    #   --icons : Requires Nerd Font
    #   --color=always : formatting
    local _eza_opts="--group-directories-first --icons --color=always"

    alias l.="eza -d .* $_eza_opts"                   # Dotfiles only (relies on shell globbing)
    alias la="eza -a $_eza_opts"                      # List All (Inc Hidden)
    alias ll="eza -l $_eza_opts"                      # Long List
    alias lt="eza -aT --level=2 $_eza_opts"           # Tree View (Level 2)
    alias l="eza -l --git $_eza_opts"                 # Long + Git Status
    alias ls="eza -al --git $_eza_opts"               # Default 'ls' override

elif is_installed lsd; then
    # Lsd: Good alternative if eza is missing
    alias ls="lsd -a --group-directories-first"
    alias ll="lsd -la --group-directories-first"

else
    # Native Fallback
    if [[ "$detected_os" == "Darwin" ]]; then
        alias ls="ls -G"         # macOS color flag
        alias ll="ls -laG"
    else
        alias ls="ls --color=auto" # Linux color flag
        alias ll="ls -la --color=auto"
    fi
fi

# ------------------------------------------------------------------------------
# Clipboard (Cross-Platform)
# Abstracts 'copy' and 'paste' regardless of OS.

if [[ "$detected_os" == "Darwin" ]]; then
    alias copy='pbcopy'
    alias paste='pbpaste'
else
    # Linux: Try xsel first, fallback to xclip
    if is_installed xsel; then
        alias copy='xsel --clipboard --input'
        alias paste='xsel --clipboard --output'
    elif is_installed xclip; then
        alias copy='xclip -selection clipboard'
        alias paste='xclip -selection clipboard -o'
    fi
fi

# ------------------------------------------------------------------------------
# Network & Process

alias ip="curl ipinfo.io/ip"           # Get Public IP
alias ping='ping -c 5'                 # Stop after 5 pings
alias fastping='ping -c 100 -s .2'     # Stress test
alias gping="ping -c 5 google.com"     # Connectivity check

# Process Listing (ps)
alias p="ps -f"
alias paux='ps aux | grep'

# Memory/CPU Sorting (Handles flag differences between macOS/Linux)
if [[ "$detected_os" == "Linux" ]]; then
    alias psmem='ps auxf | sort -nr -k 4'
    alias pscpu='ps auxf | sort -nr -k 3'
else
    alias psmem='ps aux | sort -nr -k 4'  # macOS lacks 'f' forest view in aux
    alias pscpu='ps aux | sort -nr -k 3'
fi

alias killl='killall -q'


# Package Management
# ───────────────────────────────────────────────────────────────────────
## Shortcuts for Arch Linux (Pacman) and derivatives.

if is_installed pacman; then
    # Native Pacman Wrappers
    alias pacin="sudo pacman -S"                     # Install
    alias pacrem="sudo pacman -Rns"                  # Remove (+ dependencies)
    alias pacupd="sudo pacman -Sy"                   # Update Db
    alias pacupg="sudo pacman -Syu"                  # Upgrade System
    alias cleanup="sudo pacman -Rns $(pacman -Qtdq)" # Remove orphans
    alias unlock="sudo rm /var/lib/pacman/db.lck"    # Fix lock file

    # AUR Helpers (Yay / Paru)
    if is_installed yay; then
        alias yas="yay -Syu --noconfirm"
        alias yain="yay -S"
        alias yarem="yay -Rns"
    elif is_installed paru; then
        alias update="paru -Syu --nocombinedupgrade"
    fi

    # Mirrorlist Maintenance (Reflector)
    alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"
    alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
    alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
fi

# Language Managers
is_installed npm && alias npm-up="sudo npm install npm@latest -g"
is_installed pip3 && alias pip-up="sudo pip3 list --outdated | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U"


# Git Configuration
# ───────────────────────────────────────────────────────────────────────
## Extensive shortcuts for Git operations.

if is_installed git; then
    alias g="git"

    # Status & Add
    alias gst="git status"
    alias gss="git status -s"         # Short status
    alias ga="git add"
    alias gaa="git add --all"

    # Commit
    alias gc="git commit -v"
    alias gcm="git commit -m"
    alias gca="git commit -v -a"      # Stage all modified and commit

    # Branching & Switching
    alias gb="git branch"
    alias gba="git branch -a"         # List all (local+remote)
    alias gco="git checkout"
    alias gcb="git checkout -b"       # Create branch
    alias gsw="git switch"

    # Remotes
    alias gl="git pull"
    alias gp="git push"
    alias gf="git fetch"
    alias gcl="git clone --quiet"

    # History & Logs
    alias gd="git diff"
    alias glg="git log --stat"
    alias glo="git log --oneline --decorate"
    # alias glog="git log --oneline --decorate --graph"
    # Pretty Log: Shows hash, refs, message, relative time, and author in colors
    alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"

    # Advanced / Undo
    alias grh="git reset"
    alias grhh="git reset --hard"     # !!! Destructive
    alias gcp="git cherry-pick"

    # Stash
    alias gsta="git stash push"
    alias gstp="git stash pop"
    alias gstd="git stash drop"
    alias gstl="git stash list"

    # Work in Progress (WIP)
    # Commits everything including untracked files with a "wip" message. Skips CI.
    alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'
fi


# Global Output Modifiers
# ───────────────────────────────────────────────────────────────────────
## Global aliases (-g) are expanded anywhere in the command line,
## not just at the beginning. They act like pipes.

# Usage:  cat file.txt |G pattern
alias -g ':G'="| grep"

# Usage:  long_command |L
alias -g ':L'="| less"

# Usage:  ls -la |H
alias -g ':H'="| head"
alias -g ':T'="| tail"
alias -g ':S'="| sed"

# Redirection Shortcuts
alias -g ':NE'="2> /dev/null"        # Silence Errors
alias -g ':NUL'="> /dev/null 2>&1"   # Silence Everything (Output + Errors)
alias -g ':LL'="2>&1 | less"         # Pipe Output+Errors to Less


# Suffix Aliases
# ───────────────────────────────────────────────────────────────────────
## Executing files based on extension (e.g., typing 'main.py' runs python).

# 1. Define the System Opener
#    macOS uses 'open', Linux uses 'xdg-open'.
if [[ "$detected_os" == "Darwin" ]]; then
    local _sys_open="open"
else
    local _sys_open="xdg-open"
fi

# 2. Text & Config Files -> Open in Editor
#    Extensions usually meant for editing.
alias -s {txt,md,markdown,yml,yaml,toml,conf,ini,json,xml,csv}="$EDITOR"
alias -s {zsh,bash,sh,zshrc,bashrc}="$EDITOR"

# 3. Source Code -> Open in Editor (Safe Default)
#    We default to editing to prevent accidental execution of unfinished code.
alias -s {c,cpp,h,hpp,rs,go,java,ts,css,html}="$EDITOR"

# 4. Script Execution -> Run Immediately
#    Typing 'script.py' will run it through python3.
alias -s py="python3"
alias -s js="node"
alias -s rb="ruby"

# 5. Media & Documents -> System Default Viewer
#    Opens PDFs, images, and videos in your default GUI app.
alias -s {pdf,epub,djvu}="$_sys_open"
alias -s {jpg,jpeg,png,gif,svg,webp,bmp}="$_sys_open"
alias -s {mp3,wav,flac,aac,ogg}="$_sys_open"
alias -s {mp4,mkv,avi,mov,webm}="$_sys_open"

# 6. Archives -> List Contents (Safety First)
#    Typing 'data.zip' lists contents rather than auto-extracting (messy).
if is_installed unzip; then
    alias -s zip="unzip -l"
fi
if is_installed tar; then
    alias -s {tgz,gz}="tar tf"
fi

# 7. Log Files -> Bat (Syntax Highlighting)
#    If 'bat' is installed, use it for logs. Otherwise, use 'tail -f'.
if is_installed bat; then
    alias -s {log,md}="bat --paging=always"
else
    alias -s log="tail -f"
fi

# 8. Git Patches -> Apply
#    Typing a .patch file applies it to the repo.
alias -s patch="git apply"

# Cleanup variable
unset _sys_open


# Miscellaneous
# ───────────────────────────────────────────────────────────────────────

alias cls="clear"
alias clean="clear"
alias h="history"
alias x="chmod +x"                  # Make executable
alias weather='curl -s wttr.in'     # Check weather
alias myip="curl ipinfo.io/ip"      # Check Public IP

# Tmux Smart Exit
# If inside Tmux: Kill the specific session.
# If in normal shell: Exit.
alias ':q'='[ -n "$TMUX" ] && tmux kill-session -t $(tmux display-message -p "#S") || exit'

# Time & Date
# Copies formatted date to clipboard and prints it.
alias dday='date +"%Y.%m.%d - " | copy ; date +"%Y.%m.%d"'
alias week='date +%V'

# Fun: Terminal Bonsai Tree
is_installed cbonsai && alias ccbonsai="cbonsai -ilt 0.02 -c '  ,  ,  ,  ,  ' -L 5"
