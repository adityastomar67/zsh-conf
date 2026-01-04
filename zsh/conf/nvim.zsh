# ------------------------[  MULTI-NEOVIM SWITCHER  ]------------------------ #
# Utility function for easy Nvim config switching by @elijahmanor.
# Requires NVIM_APPNAME support (Neovim >= 0.9.0).


# ........................[  1. Initialization & Guard  ]........................ #

# Exit if disabled or if git is missing (Git is strictly required for installation)
[[ "$MULTI_NEOVIM" != "Yes" ]] && return

if ! is_installed git; then
    printf "\n\033[0;33m[WARN] MULTI_NEOVIM='Yes' but 'git' is not installed.\033[0m\n"
    return
fi

# Cleanup: If explicitly set to "No", remove the config directories
if [ "$MULTI_NEOVIM" = "No" ]; then
    [ -d ~/.config/LazyVim ]   && rm -rf ~/.config/LazyVim
    [ -d ~/.config/NvChad ]    && rm -rf ~/.config/NvChad
    [ -d ~/.config/LazyNV ]    && rm -rf ~/.config/LazyNV
    [ -d ~/.config/AstroNvim ] && rm -rf ~/.config/AstroNvim
fi


# ........................[  2. Auto-Install Configs  ]........................ #

# LazyVim
[ ! -d ~/.config/LazyVim ] && \
    git clone --quiet https://github.com/LazyVim/starter ~/.config/LazyVim && \
    echo "Cloning LazyVim configs..."

# NvChad
[ ! -d ~/.config/NvChad ] && \
    git clone --quiet --depth 1 https://github.com/adityastomar67/NvChad ~/.config/NvChad && \
    echo "Cloning NvChad configs..."

# LazyNV
[ ! -d ~/.config/LazyNV ] && \
    git clone --quiet --depth 1 https://github.com/adityastomar67/LazyNV ~/.config/LazyNV && \
    echo "Cloning LazyNV configs..."

# AstroNvim
[ ! -d ~/.config/AstroNvim ] && \
    git clone --quiet --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/AstroNvim && \
    echo "Cloning AstroNvim configs..."


# ........................[  3. Switcher Function  ]........................ #

function nvims() {
    # Check for Neovim >= 0.9.0 (Regex matches version string)
    local nvim_version=$(nvim --version | grep -oP '(?<=^NVIM v)[0-9|.][0-9|.][0-9|.]')

    if [[ "$nvim_version" == "0.9"* ]] || [[ "$nvim_version" > "0.9" ]]; then

        # Direct Launch via Arguments
        if [ $# -gt 0 ] && [ ! -f "$1" ] && [ ! -d "$1" ]; then
            case "$1" in
                -a | --astro) NVIM_APPNAME=AstroNvim nvim "$2" ;;
                -l | --lazy)  NVIM_APPNAME=LazyVim   nvim "$2" ;;
                -c | --chad)  NVIM_APPNAME=NvChad    nvim "$2" ;;
                -n | --nv)    NVIM_APPNAME=LazyNV    nvim "$2" ;;
                *)            echo "No config found for the choice!" >&2 ;;
            esac

        # Interactive Menu via FZF
        else
            # We check for fzf here, only when it's actually needed
            if ! is_installed fzf; then
                echo "Error: fzf is required for the interactive menu."
                echo "Use 'nvims -h' or install fzf."
                return 1
            fi

            local items=("default" "LazyNV" "LazyVim" "NvChad" "AstroNvim")
            local config=$(printf "%s\n" "${items[@]}" | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)

            if [[ -z $config ]]; then
                echo "Nothing selected"
                return 0
            elif [[ $config == "default" ]]; then
                config=""
            fi

            NVIM_APPNAME=$config nvim "$@"
        fi
    else
        echo "Required NVIM >= 0.9 for multi-configuration setup!"
    fi
}

# Shortcut: Ctrl+a
bindkey -s ^a "nvims\n"

