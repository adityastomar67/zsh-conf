#    ░█▀▀░█▀█░█░█░░░░▀▀█░█▀▀░█░█
#    ░█▀▀░█░█░▀▄▀░░░░▄▀░░▀▀█░█▀█
#    ░▀▀▀░▀░▀░░▀░░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This file sets up global environment variables related to localization,
#   standard directory paths (XDG), and default application preferences.
#
# Problems Solved
#   - Fixes encoding issues (UTF-8).
#   - Enables True Color (256 colors) in capable terminals.
#   - Centralizes file storage locations to ~/.config and ~/.cache.
#   - Configures a rich "Manpager" (using Neovim/Bat to read man pages).
#
# Features / Responsibilities
#   - Locale Configuration.
#   - XDG Base Directory definition.
#   - Default Editor/Visual selection.
#   - Smart Manpager selection (Nvim > Bat > Vim > Less).
#   - SSH session overrides.
#
# Usage Notes
#   - Sourced during startup.
#   - Relies on 'is_installed' helper function defined in 'lib/_core.utils'.
# ------------------------------------------------------------------------------


# Localization & Terminal
# ───────────────────────────────────────────────────────────────────────
## Ensure the shell handles UTF-8 characters correctly and identifies
## the terminal capabilities.

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# GPG Signing TTY
# Set the TTY for GPG agent to the current tty.
# Optimization: ${TTY} is faster than subshell $(tty) if already set.
export GPG_TTY="${TTY:-$(tty)}"

# ── true color support ─────────────────────────────────────────────────
# If the terminal supports truecolor (16 million colors), force the
# TERM variable to xterm-256color for compatibility with tools like Bat/Vim.

if [[ "$COLORTERM" == "truecolor" || "$TERM" == *256* ]]; then
    export TERM="xterm-256color"
    export BAT_THEME="TwoDark"
fi

export LS_COLORS="di=38;5;111:ln=38;5;210:or=48;5;210;38;5;16:mi=48;5;210;38;5;16:pi=48;5;111;38;5;16:so=48;5;210;38;5;16:bd=48;5;210;38;5;16:cd=48;5;150;38;5;16:ex=01;38;5;210:*.tar=04;38;5;150:*.tgz=04;38;5;150:*.arc=04;38;5;150:*.zip=04;38;5;150:*.z=04;38;5;150:*.7z=04;38;5;150:*.jpg=38;5;210:*.jpeg=38;5;210:*.png=38;5;210:*.gif=38;5;210:*.mp4=38;5;210:*.mp3=38;5;210:*.c=38;5;114:*.cpp=38;5;114:*.py=38;5;114:*.js=38;5;114:*.rs=38;5;114:*.go=38;5;114:*.yml=38;5;216:*.yaml=38;5;216:*.toml=38;5;216:*.conf=38;5;216:*.md=38;5;216:*.txt=38;5;246:*.doc=38;5;210:*.docx=38;5;210:*.pdf=38;5;210:"


# XDG Base Directory Standards
# ───────────────────────────────────────────────────────────────────────
## Defines standard locations for config, cache, and data files.
## This prevents dotfile clutter in the $HOME directory.

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Disable the "hint" messages you are seeing in HOMEBREW
export HOMEBREW_NO_ENV_HINTS=1


# Default Applications
# ───────────────────────────────────────────────────────────────────────
## Sets the preferred programs for editing text and viewing system manuals.

# ------------------------------------------------------------------------------
# Sudo Prompt
# Custom prompt when asking for root password (displays username).
export SUDO_PROMPT="${COLOR[RED]}[NOTE]${COLOR[RESET]} Deploying root access for ${COLOR[YELLOW]}${COLOR[BOLD]}%u${COLOR[RESET]}, Password please: "

# ------------------------------------------------------------------------------
# Manpager (Manual Page Viewer)
# Priority: Neovim (Syntax Highlight + Nav) > Bat (Colors) > Vim > Less

if (( $+commands[nvim] )); then
    export EDITOR="nvim"
    export VISUAL="nvim"

    # Use Neovim as a pager:
    #   --clean      : No plugins (fast startup)
    #   -c ...       : Run Vim commands to optimize for reading (no line nums, etc)
    #   +Man!        : Trigger the Man plugin
    export MANPAGER="nvim --clean \
        -c 'runtime ftplugin/man.vim' \
        -c 'set laststatus=0' \
        -c 'set showtabline=0' \
        -c 'set nonumber norelativenumber' \
        -c 'set nocul noshowcmd noruler noshowmode' \
        +Man!"

elif (( $+commands[bat] )); then
    # Use Bat (cat clone with wings):
    # Renders man pages with syntax highlighting
    export MANPAGER="sh -c 'col -bx | bat \
        --language=man \
        --style=plain \
        --theme=TwoDark \
        --paging=always'"

elif (( $+commands[vim] )); then
    # Use Standard Vim:
    # Configures buffer to be scratch (nofile) and maps 'q' to quit.
    export MANPAGER='/bin/bash -c "vim -MRn -c \"set buftype=nofile showtabline=0 ft=man ts=8 nomod nolist norelativenumber nonu noma\" -c \"normal L\" -c \"nmap q :qa<CR>\"</dev/tty <(col -b)"'

else
    # Fallback: Less
    #   -s : Squeeze blank lines
    #   +M : Long prompt
    #   +Gg: Visual bells
    export MANPAGER="less -s +M +Gg"
fi


# Application Specific
# ───────────────────────────────────────────────────────────────────────
## Shortcuts and environment variables for specific tools.

# Link to the main dotfiles repo location
# Note: $DOTFILES_ROOT is defined in the main env.zsh file
export XDG_DOTS="${DOTFILES_ROOT:-$HOME/.config/.dotfiles}"

# Neovim configuration location
export XDG_NVIM="$HOME/.config/nvim"


# SSH & Remote Settings
# ───────────────────────────────────────────────────────────────────────
## Configuration applied only when connected via SSH.

if [[ -n "$SSH_CONNECTION" ]]; then
    # Revert to standard Vim on remote servers (safer than assuming Nvim config exists)
    export EDITOR='vim'

    # Display System Info
    # If neofetch exists, run it. If lolcat exists, colorize it.
    if (( $+commands[neofetch] )); then
        if (( $+commands[lolcat] )); then
            # -S 10: Spread rainbow
            # -F 0.05: Frequency
            neofetch | lolcat -S 10 -F 0.05
        else
            neofetch
        fi
    fi
fi
