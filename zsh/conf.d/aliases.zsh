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
#   To disable this entire file, set `LOAD_CUSTOM_ALIASES="No"` in $ZDOTDIR/user.conf.
#   $EDITOR is defined in '$ZSH_CONFIG_ROOT/conf.d/env.zsh'
# ------------------------------------------------------------------------------


# Initialization
# ───────────────────────────────────────────────────────────────────────
## Preparation steps: Feature flags, clean slate, and OS detection.

# Feature Guard
# Exit immediately if the user has disabled aliases in the main config.
[[ "${LOAD_CUSTOM_ALIASES:l}" != "yes" ]] && return

# Reset: Remove all existing aliases to prevent conflicts or stale definitions.
unalias -a

# Environment Detection
# Capture the kernel name to handle OS-specific flags (Darwin vs Linux).
local detected_os
detected_os=$(uname -s)


# System & Privileges
# ───────────────────────────────────────────────────────────────────────
## Wrappers for administrative commands and safety features.
# Admin Helpers
alias _="sudo"        # Quick sudo shorthand

# ------------------------------------------------------------------------------
# Auto-Sudo (Linux Only)
# On Linux, system commands almost always require root. This wrapper adds
# 'sudo' automatically to specific commands to save typing.
if [[ "$detected_os" == "Linux" ]]; then
    for sys_cmd in mount umount sv updatedb su shutdown poweroff reboot; do
        alias "$sys_cmd"="_ $sys_cmd"
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
(( $+commands[fzf] )) && alias man="fzf-man"

# ------------------------------------------------------------------------------
# Safety Nets
# Force interactive mode (-i) to prompt before destructive actions.
alias mv="mv -i"
alias cp="cp -i"
alias ln="ln -i"
alias rm="rm -i"      # "Are you sure?" prompt for deletions

# ------------------------------------------------------------------------------
# "The Magic Fixer"
# Re-runs the last command in history ($(fc ...)) prepended with sudo.
alias please='_ $(fc -ln -1)'

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
# Create aliases .1 through .100 to jump back in the directory stack.
alias .1="cd -"
for n in {2..100}; do
    alias ".$n"="cd -$n"  # Example: .5 = cd -5, .10 = cd -10
done

# ------------------------------------------------------------------------------
# Dynamic Bookmarks
## Define the Shortcuts [Abbr]="Path"
## Only create these aliases if the target directory actually exists.
local -A _dir_abbreviations=(
    # Note: DOTFILES_ROOT is defined in '$ZDOTDIR/.zshenv'
    dt  "${DOTFILES_ROOT}"

    pj  "$HOME/Projects"
    dc  "$HOME/Documents"
    dl  "$HOME/Downloads"
    dv  "$HOME/Developer"
    wk  "$HOME/Workspace"
    cf  "$HOME/.config"
)

# Dynamic Alias Creation
#    Loop through keys (abbr) and values (dir), check existence, and create alias.
for abbr dir in "${(@kv)_dir_abbreviations}"; do
    if [[ -d "$dir" ]]; then
        alias -- "-$abbr"="cd $dir" # Example: -dv = cd ~/Developer

        # Optional: Register as a Named Directory (allows nvim ~pj and prompt shortening)
        hash -d "$abbr"="$dir"
    fi
done

# Editors & Configurations
# ───────────────────────────────────────────────────────────────────────
## Shortcuts for editing configuration files and selecting editors.
# Shell Configuration Editors
# Only define aliases if the configuration files exist.
[[ -f $ZDOTDIR/.zshrc ]]            && alias zedit='_safe_edit $ZDOTDIR/.zshrc'
[[ -f ~/.bashrc ]]                  && alias bedit='_safe_edit ~/.bashrc'
[[ -f ~/.config/fish/config.fish ]] && alias fedit='_safe_edit ~/.config/fish/config.fish'
[[ -f $XDG_NVIM/init.lua ]]         && alias nvedit='_safe_edit $XDG_NVIM/init.lua'

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
(( $+commands[nvim] ))  && alias vim="nvim" \
                   && alias vimdiff="nvim -d" \
                   && alias v="nvim"

# If Emacs is installed, try to use the client for speed.
(( $+commands[emacs] )) && alias em="/usr/bin/emacs -nw" \
                   && alias emacs="emacsclient -c -a 'emacs'"

# VS Code Wrapper (forces specific extension usage)
# (( $+commands[code] ))  && alias code="code --extensions-dir '$HOME/.config/Code/User/extensions'"


# Utilities & Tools
# ───────────────────────────────────────────────────────────────────────
## Replacing legacy unix tools with modern Rust/Go alternatives.

# ------------------------------------------------------------------------------
# Modern Replacements

# 'cat' -> 'bat' (Syntax highlighting)
(( $+commands[bat] ))     && alias cat='bat'

# 'df' -> 'duf' (Disk Usage / Free utility)
(( $+commands[duf] ))     && alias df="duf" || alias df="df -h"

# 'rm' -> 'trash' (Moves to trash instead of permanent delete)
(( $+commands[trash] ))   && alias del="trash"

# 'grep' -> 'ripgrep' (Much faster search)
(( $+commands[ripgrep] )) && alias grep="ripgrep"

# Fun: Terminal Bonsai Tree
(( $+commands[cbonsai] )) && alias bonsai="cbonsai -ilt 0.02 -c '  ,  ,  ,  ,  ' -L 5"

# ------------------------------------------------------------------------------
# Listing (The 'ls' Hierarchy)
# Logic: Try 'eza' (best), then 'lsd' (good), then native 'ls' (fallback).

if (( $+commands[eza] )); then
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

elif (( $+commands[lsd] )); then
    # Lsd: Good alternative if eza is missing
    alias ls="lsd -a --group-directories-first"
    alias ll="lsd -la --group-directories-first"

else
    # Native Fallback
    if [[ "$detected_os" == "Darwin" ]]; then
        alias ls="ls -G"           # macOS color flag
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
    if (( $+commands[xsel] )); then
        alias copy='xsel --clipboard --input'
        alias paste='xsel --clipboard --output'
    elif (( $+commands[xclip] )); then
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

if (( $+commands[pacman] )); then
    local _pac="_ pacman"  # WARN: Might break due to local keyword

    # Native Pacman Wrappers
    alias pacin="$_pac -S --needed"                    # Install (skip if up-to-date)
    alias pacrem="$_pac -Rns"                          # Remove (+ dependencies & configs)
    alias pacupd="$_pac -Sy"                           # Update local database
    alias pacupg="$_pac -Syu"                          # Full system upgrade
    alias cleanup="pacman -Qtdq | xargs -r $_pac -Rns" # Remove orphan packages
    alias unlock="_ rm /var/lib/pacman/db.lck"         # Remove stale lock file

    # AUR Helpers (Yay / Paru)
    if (( $+commands[yay] )); then
        alias yas="yay -Syu --noconfirm"
        alias yain="yay -S"
        alias yarem="yay -Rns"

    elif (( $+commands[paru] )); then
        alias update="paru -Syu --nocombinedupgrade"
    fi

    # Mirrorlist Maintenance (Reflector)
    if (( $+commands[reflector] )); then
        for s in age delay score; do
            alias "mirror${s[1]}"="_ reflector --latest 50 --number 20 --sort $s --save /etc/pacman.d/mirrorlist"
        done
    fi
fi

# Language Managers
(( $+commands[npm] )) && alias npm-up="_ npm install npm@latest -g"
(( $+commands[pip3] )) && alias pip-up="_ pip3 list --outdated | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U"


# Git Configuration
# ───────────────────────────────────────────────────────────────────────
## Extensive shortcuts for Git operations.

if (( $+commands[git] )); then
    alias g="git"

    # Status & Add
    alias gst="git status -sb"                 # Short status with branch info
    alias ga="git add"                         # Add files to staging
    alias gaa="git add --all"                  # Add all files to staging
    alias gapa="git add --patch"               # Interactively stage hunks

    # Commit
    alias gc="git commit -v"                   # Commit with verbose output
    alias gcm="git commit -m"                  # Commit with message
    alias gca="git commit -v -a"               # Commit all changed files with verbose output
    alias 'gca!'="git commit -v -a --amend"    # PRO: Quick fix last commit

    # Branching & Switching (Modern Git)
    alias gb="git branch"                      # List branches
    alias gba="git branch -a"                  # List all branches
    alias gsw="git switch"                     # Switch branches
    alias gsc="git switch -c"                  # Create and switch branches
    alias gco="git checkout"                   # Checkout branches

    # Remotes & Sync
    alias gl="git pull"                        # Pull changes from remote
    alias gp="git push"                        # Push changes to remote
    alias 'gpf!'="git push --force-with-lease" # PRO: Safe force push
    alias gf="git fetch"                       # Fetch changes from remote
    alias gcl="git clone --recurse-submodules" # Clone with submodules

    # History & Logs
    alias gd="git diff"                        # Diff changes
    alias gds="git diff --staged"              # See what is about to be committed
    alias glo="git log --oneline --decorate"   # Log in one line
    alias glol="git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'"

    # Stash & Reset
    alias gsta="git stash push"                # Push changes to stash
    alias gstp="git stash pop"                 # Pop changes from stash
    alias grh="git reset"                      # Reset changes
    alias grhh="git reset --hard"              # Hard reset changes
    alias gcp="git cherry-pick"                # Cherry-pick changes

    # Work in Progress (WIP)
    # PRO: Simplified WIP that handles removals automatically and skips hooks
    alias gwip='git add -A; git commit -m "--wip-- [skip ci]" --no-verify'
    alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
fi


# Global Output Modifiers
# ───────────────────────────────────────────────────────────────────────
## Global aliases (-g) are expanded anywhere in the command line,
## not just at the beginning. They act like pipes.

# Usage:  cat file.txt :G pattern
(( $+commands[ripgrep] )) && alias -g ':G'="| ripgrep" || alias -g ':G'="| grep"

# Usage:  long_command :L
alias -g ':L'="| less"

# Usage:  ls -la :H
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

# Define the System Opener
#    macOS uses 'open', Linux uses 'xdg-open'.
if [[ "$detected_os" == "Darwin" ]]; then
    local _sys_open="open"
else
    local _sys_open="xdg-open"
fi

# Text & Config Files -> Open in Editor
#    Extensions usually meant for editing.
alias -s {txt,md,markdown,yml,yaml,toml,conf,ini,json,xml,csv}="$EDITOR"
alias -s {zsh,bash,sh,zshrc,bashrc}="$EDITOR"

# Source Code -> Open in Editor (Safe Default)
#    We default to editing to prevent accidental execution of unfinished code.
alias -s {c,cpp,h,hpp,rs,go,java,ts,css,html}="$EDITOR"

# Script Execution -> Run Immediately
#    Typing 'script.py' will run it through python3.
if (( $+commands[python3] )); then
    alias -s py='python3'
elif (( $+commands[python] )); then
    alias -s py='python'
fi
alias -s js="node"
alias -s rb="ruby"

# Media & Documents -> System Default Viewer
#    Opens PDFs, images, and videos in your default GUI app.
alias -s {pdf,epub,djvu}="$_sys_open"
alias -s {jpg,jpeg,png,gif,svg,webp,bmp}="$_sys_open"
alias -s {mp3,wav,flac,aac,ogg}="$_sys_open"
alias -s {mp4,mkv,avi,mov,webm}="$_sys_open"

# Archives -> List Contents (Safety First)
#    Typing 'data.zip' lists contents rather than auto-extracting (messy).
if (( $+commands[unzip] )); then
    alias -s zip="unzip -l"
fi
if (( $+commands[tar] )); then
    alias -s {tgz,gz}="tar tf"
fi

# Log Files -> Bat (Syntax Highlighting)
#    If 'bat' is installed, use it for logs. Otherwise, use 'tail -f'.
if (( $+commands[bat] )); then
    alias -s {log,md}="bat --paging=always"
else
    alias -s log="tail -f"
fi

# Git Patches -> Apply
#    Typing a .patch file applies it to the repo.
alias -s patch="git apply"


# Miscellaneous
# ───────────────────────────────────────────────────────────────────────

alias cls="clear"                   # Clear screen
alias clean="clear"                 # Clear screen too
alias h="history"                   # History
alias x="chmod +x"                  # Make executable
alias weather='curl -s wttr.in'     # Check weather
alias myip="curl ipinfo.io/ip"      # Check Public IP
alias md="mkdir -p"                 # Create parent directories automatically
alias new="touch"                   # Create new file

# Tmux Smart Exit
#   - If inside Tmux: Kill the specific session.
#   - If in normal shell: Exit.
alias ':q'='[ -n "$TMUX" ] && tmux kill-session -t $(tmux display-message -p "#S") || exit'

# Time & Date
# Copies formatted date to clipboard and prints it.
alias dday='date +"%Y.%m.%d - " | copy ; date +"%Y.%m.%d"'
alias week='date +%V'

# Cleanup
unset detected_os
unset _pac
unset _sys_open

