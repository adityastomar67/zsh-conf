#!/usr/bin/env zsh

# Define colors and formatting
CRE=$(tput setaf 1)
CYE=$(tput setaf 3)
CGR=$(tput setaf 2)
CBL=$(tput setaf 4)
BLD=$(tput bold)
CNC=$(tput sgr0)

# Configuration variables
ZSH_PATH="$HOME/.config/zsh-conf"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
ZENV="${ZDOTDIR:-$HOME}/.zshenv"
DEPENDENCIES=("tmux" "ranger" "fd" "ripgrep" "lazygit" "zoxide" "fzf" "lsd" "npm" "ffmpegthumbnailer" "navi" "eza" "bat" "git-delta" "ripgrep" "fd" "starship" "zoxide" "atuin" "shellcheck")

# Detect OS and package manager
if [[ "$OSTYPE" == "darwin"* ]]; then
    PKG_MANAGER="brew"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
else
    printf "%s%s[ERROR] Unsupported OS or Package Manager not found!%s" "${CRE}" "${BLD}" "${CNC}"
    exit 1
fi

# Function to check if a package is installed
is_installed() {
    local pkg="$1"
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        pacman -Qi "$pkg" &>/dev/null
    elif [[ "$PKG_MANAGER" == "brew" ]]; then
        brew list "$pkg" &>/dev/null
    fi
    return $?
}

# Function to install packages
install_packages() {
    printf "\n%s%sInstalling Packages...%s\n" "${BLD}${CBL}" "${CNC}"
    sleep 1

    for package in "${DEPENDENCIES[@]}"; do
        clear
        if ! is_installed "$package"; then
            read -rp "Would you like to install $package? [y/N] " res
            if [[ $res == "y" ]]; then
                if [[ "$PKG_MANAGER" == "pacman" ]]; then
                    sudo pacman -S "$package" --noconfirm
                elif [[ "$PKG_MANAGER" == "brew" ]]; then
                    brew install "$package"
                fi
                printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
            fi
        else
            printf '%s✓ %s is already installed on your system!%s\n' "${CGR}" "$package" "${CNC}"
            sleep 1
        fi
    done

    printf '%s[ ✓ DONE ] All packages successfully installed as per your choice!%s\n' "${CGR}" "${CNC}"
    sleep 2
}

# Function to set shell configuration options
set_shell_config() {
    local options=(
        "Tmux"
        "Alias"
        "Custom Functions"
        "Themer"
        "Multiple Neovim Setup"
        "Custom Wallpapers"
        "Temporary Sourcing File"
    )

    local config_var=(
        "USE_TMUX"
        "USE_ALIAS"
        "USE_FUNCTION"
        "OPT_THEME"
        "MULTI_NEOVIM"
        "CUSTOM_WALL"
        "TEMP_OFFLINE_ALIAS"
    )

    local total=${#options[@]}
    if [[ -f "$ZSH_PATH/.zshenv" ]]; then
        for ((i=0; i<total; i++)); do
            clear
            read -rp "[$((i+1))/$total] Enable ${options[$i]}? [y/N] " res

            if [[ $res =~ ^[Yy]$ ]]; then
                sed -i "s/${config_var[$i]}=\"No\"/${config_var[$i]}=\"Yes\"/g" "$ZSH_PATH/.zshenv"
                printf '✓ Enabled: %s\n' "${options[$i]}"
                
            else
                printf 'Skipped: %s\n' "${options[$i]}"
            fi

            sleep 0.6
        done
    else
        printf '%s%s[ERROR] %s not found.%s\n' "${CRE}" "${BLD}" "$ZSH_PATH/.zshenv" "${CNC}"
    fi
}


check_and_install_zsh() {
    if ! command -v zsh &>/dev/null; then
        read -rp "Zsh is not installed. Would you like to install it? [y/N] " res
        if [[ $res == "y" ]]; then
            if [[ "$PKG_MANAGER" == "pacman" ]]; then
                sudo pacman -S zsh --noconfirm
            elif [[ "$PKG_MANAGER" == "brew" ]]; then
                brew install zsh
            fi
            echo "Zsh has been installed successfully!"
        else
            echo "Installation of Zsh was skipped."
        fi
    else
        echo "Zsh is already installed."
    fi
}

# Main function
main() {
    local DATE=$(date +%Y-%m-%d)
    local ID=$(date +%s)

    check_and_install_zsh

    # Check if the current .zshrc and .zshenv config files exist and move them if they do
    [ -f "$ZSHRC" ] && mv "$ZSHRC" "$HOME/.zshrc_${DATE}_${ID}" && printf "    Moved .zshrc to $HOME/.zshrc_${DATE}_${ID}\n"
    [ -f "$ZENV" ] && mv "$ZENV" "$HOME/.zshenv_${DATE}_${ID}" && printf "    Moved .zshenv to $HOME/.zshenv_${DATE}_${ID}\n"

    # Clone the Git repository containing Zsh configuration files
    [ -d "$ZSH_PATH" ] && mv "$ZSH_PATH" "${ZSH_PATH}_${DATE}_${ID}"  # Backup existing config if it exists
    git clone --quiet "https://github.com/adityastomar67/zsh-conf.git" "$ZSH_PATH"

    # Create symbolic links to the configuration files in the user's home directory
    ln -sf "$ZSH_PATH/.zshrc" "$ZSHRC"
    ln -sf "$ZSH_PATH/.zshenv" "$ZENV"

    # Changing shell to Zsh
	printf "%s%s[NOTE] Setting up Z-Shell!%s\n\n" "${BLD}" "${CYE}" "${CNC}"
    sleep 5

    # Change the user's shell to Zsh if it's not already
    if [[ $SHELL != "/usr/bin/zsh" ]]; then
    	printf "%s%sChanging shell to Zsh.\nYour root password is needed to make the change.\n\nAfter that, it is important for you to reboot.\n %s\n" "${BLD}" "${CYE}" "${CNC}"
        chsh -s /usr/bin/zsh
        sleep 2
        printf '%s%s[DONE] Shell changed to ZSH!%s\n' "${BLD}" "${CGR}" "${CNC}"
        sleep 5
    else
        printf "%s%sYour shell is already ZSH%s\n" "${BLD}" "${CGR}" "${CNC}"
        sleep 5
    fi

    # Install necessary packages
    install_packages

    # Set shell configuration options
    set_shell_config

    if command -v zsh &> /dev/null; then
        echo "Compiling Zsh configuration files..."
        zsh -c "autoload -U zrecompile && zrecompile -p \"$ZSH_PATH/.zshrc\"" 2>/dev/null || true
    fi

    [ -e "$ZSH_PATH/install.zsh" ] && rm -rf "$ZSH_PATH/install.zsh"
    return 0
}

# Clear the terminal and run the main function
clear
main "$@"

[[ $? -eq 0 ]] && SHOW_CONFIG_WARNING=1 exec zsh || return
