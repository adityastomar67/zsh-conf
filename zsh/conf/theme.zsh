# ------------------------[  THEME & VISUALS  ]------------------------ #
# Manages terminal color schemes (theme.sh) and wallpaper downloading.
#
# STRUCTURE:
# 1. setup_theme_sh   -> Manages 'theme.sh' installation and bindings.
# 2. setup_wallpapers -> Manages custom wallpaper repository cloning.


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


# ........................[  2. Wallpaper Logic  ]........................ #

setup_wallpapers() {

    local wall_dir="$HOME/.config/wall"

    # Guard: Exit if directory already exists (prevent re-cloning)
    [[ -d "$wall_dir" ]] && return

    # Guard: Exit if git is missing
    if ! is_installed git; then
        echo "Error: 'git' is required to download wallpapers." >&2
        return 1
    fi

    # Notify User
    if is_installed dunstify; then
        dunstify -u low -i ~/.config/bspwm/assets/reload.svg 'Custom Walls' "Downloading wallpapers..."
    else
        echo ":: Downloading wallpapers..."
    fi

    # Clone (Optimized: Shallow clone, no blobs)
    git clone --quiet --depth 1 --filter=blob:none https://github.com/adityastomar67/Wallpapers "$wall_dir" || return 1

    # Post-Processing
    (
        cd "$wall_dir" || exit

        # Flatten directory structure
        [[ -d "Static" ]] && mv Static/* .

        # Rename .png to .jpg (without converting format) using Zsh modifiers
        for file in *.png(N); do
            mv -- "$file" "${file:r}.jpg"
        done

        # Cleanup artifacts
        rm -rf .git README.md Static Live list.txt
    )

    # Success Notification
    if is_installed dunstify; then
        dunstify -u low -i ~/.config/bspwm/assets/reload.svg 'Custom Walls' "Setup complete."
    fi

    # Apply Wallpaper
    if is_installed RandomWall; then
        RandomWall
    fi
}


# ........................[  3. Execution  ]........................ #

# Run the setup functions
[[ "$OPT_THEME" == "Yes" ]] && setup_theme_sh
[[ "$CUSTOM_WALL" == "Yes" ]] && setup_wallpapers

# Cleanup functions from global namespace
unfunction setup_theme_sh
unfunction setup_wallpapers

# vim:filetype=zsh
