# ------------------------[  THEME & VISUALS  ]------------------------ #
# Manages terminal color schemes (theme.sh) and wallpaper downloading.
#
# STRUCTURE:
# 1. setup_theme_sh                -> Manages 'theme.sh' installation and bindings.
# 2. $ZSH_PATH/zsh/bin/RandomWall  -> Manages custom wallpaper repository cloning.


# ........................[  1. Theme Logic  ]........................ #

setup_theme_sh() {

    local bin_dir="$HOME/.local/bin"
    local theme_bin="$bin_dir/theme.sh"

    # Ensure local bin is in PATH
    [[ ":$PATH:" != *":$bin_dir:"* ]] && export PATH="$bin_dir:$PATH"

    # Guard: Install if missing (Requires curl)
    if ! is_installed theme.sh; then
        if is_installed curl; then
            echo "Installing theme.sh..."
            mkdir -p "$bin_dir"
            curl -fsSL 'https://raw.githubusercontent.com/adityastomar67/theme.sh/master/bin/theme.sh' -o "$theme_bin"
            chmod +x "$theme_bin"
        else
            echo "Error: 'curl' is required to install theme.sh" >&2
            return 1
        fi
    fi

    # Guard: Abort if installation failed
    is_installed theme.sh || return 1

    # Load history
    if [[ -r "$HOME/.theme_history" ]]; then
        theme.sh "$(tail -n1 "$HOME/.theme_history")"
    fi

    # Aliases
    alias th='theme.sh -i'
    alias thl='theme.sh --light -i'
    alias thd='theme.sh --dark -i'

    # Widget: Cycle to previous theme
    function _last_theme() {
        local prev_theme
        prev_theme=$(tail -n2 "$HOME/.theme_history" | head -n1)
        [[ -n "$prev_theme" ]] && theme.sh "$prev_theme"
    }
    zle -N _last_theme
    bindkey '^O' _last_theme
}


# ........................[  3. Execution  ]........................ #

# Run the setup function
[[ "$OPT_THEME" == "Yes" ]] && setup_theme_sh

# Cleanup functions from global namespace
unfunction setup_theme_sh

# Guard: Only execute if 'RandomWall' is found in PATH or defined as a function
if [[ "$CUSTOM_WALL" == "Yes" ]] && is_installed RandomWall; then
    RandomWall
fi

