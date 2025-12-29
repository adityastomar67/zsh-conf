# ------------------------[  ZSH ENVIRONMENT VARIABLES  ]------------------------ #
# This file sets global variables, paths, and application defaults.


# ........................[  0. Helpers & Path configurations  ]........................ #

# Standard Paths
export PATH="$PATH:$ZSH_PATH/zsh/bin"

# Dynamic Path Loader
## 1. Ensure the system 'path' array does not contain duplicates
typeset -U path

## 2. Iterate through the array defined in .zshenv
for entry in "${USER_PATHS[@]}"; do
    # Resolve the path:
    # If it DOES NOT start with '/', prepend $HOME/
    # If it DOES start with '/', keep it as is
    if [[ "$entry" != /* ]]; then
        entry="$HOME/$entry"
    fi

    ## 3. Check if directory exists (-d)
    if [[ -d "$entry" ]]; then
        # Add to the Zsh 'path' array (which automatically updates $PATH)
        path+=("$entry")
    fi
done

## 4. Clean up the variable
unset entry


# Helper: Check if a program is installed (Arch Linux specific check)
typeset -gA _installed_cache
is_installed() {
    local cmd="$1"
    # Return from cache if set
    [[ -n "${_installed_cache[$cmd]}" ]] && return "${_installed_cache[$cmd]}"

    # Check system
    command -v "$cmd" &>/dev/null
    local ret=$?

    # Update cache and return original status
    _installed_cache[$cmd]=$ret
    return $ret
}


# ........................[  1. System & Locale  ]........................ #

export TERM="xterm-256color"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export KEYTIMEOUT=1
export GPG_TTY="$(tty)"
export ARCHFLAGS="-arch x86_64"
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/.zcompdump-$HOST"

# True Color Support
if [[ $COLORTERM == "truecolor" || $TERM == *256* ]]; then
    export TERM="xterm-256color"
    export BAT_THEME="TwoDark"
fi


# ........................[  2. XDG Base Directory Standards  ]........................ #

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# User Directories
export XDG_DESKTOP_DIR="$HOME/Desktop"
export XDG_DOCUMENTS_DIR="$HOME/Documents"
export XDG_DOWNLOAD_DIR="$HOME/Downloads"
export XDG_MUSIC_DIR="$HOME/Music"
export XDG_PICTURES_DIR="$HOME/Pictures"
export XDG_VIDEOS_DIR="$HOME/Videos"
export XDG_TEMPLATES_DIR="$HOME/Templates"
export XDG_PUBLICSHARE_DIR="$HOME/Public"


# ........................[  3. Default Applications  ]........................ #

export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="google-chrome-stable"
export SUDO_PROMPT="Deploying root access for %u. Password pls: "

# Manpager Selection (Priority: Nvim > Vim > Bat > Less)
if is_installed nvim; then
    export MANPAGER='nvim +Man! +"set nocul" +"set noshowcmd" +"set noruler" +"set noshowmode" +"set laststatus=0" +"set showtabline=0" +"set nonumber"'
elif is_installed vim; then
    export MANPAGER='/bin/bash -c "vim -MRn -c \"set buftype=nofile showtabline=0 ft=man ts=8 nomod nolist norelativenumber nonu noma\" -c \"normal L\" -c \"nmap q :qa<CR>\"</dev/tty <(col -b)"'
elif is_installed bat; then
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
else
    export MANPAGER="less -s +M +Gg"
fi


# ........................[  4. Application Specific  ]........................ #

# Java / AWT
export _JAVA_AWT_WM_NONREPARENTING=1
export AWT_TOOLKIT="MToolkit"
export JDK_JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Djdk.gtk.version=2.2 -Dsun.java2d.opengl=true'

# Qt / KDE
export QT_STYLE_OVERRIDE="kvantum"

# Neovim / Dotfiles
export XDG_DOTS="$HOME/dotfiles"
export XDG_NVIM="$HOME/.config/nvim"

# Ranger
export RANGER_DEVICONS_SEPARATOR=" "

# YTFZF
if is_installed ytfzf; then
    export YTFZF_CONFIG_DIR="$XDG_CONFIG_HOME/ytfzf"
    export YTFZF_CONFIG_FILE="$YTFZF_CONFIG_DIR/conf.sh"
fi

# Zsh History Ignore
export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"


# ........................[  5. SSH & Remote  ]........................ #

if [[ -n $SSH_CONNECTION ]]; then
    export EDITOR='vim'
    # Display system info on login
    if is_installed neofetch; then
        is_installed lolcat && neofetch | lolcat -S 10 -F 0.05 || neofetch
    fi
fi


# ........................[  6. Miscellaneous  ]........................ #

# Temporary Offline Alias File
if [ "$TEMP_OFFLINE_CONFIG" = "Yes" ]; then
    [ ! -f "$HOME/.temp_zsh" ] && touch "$HOME/.temp_zsh"
fi

# vim:filetype=zsh
