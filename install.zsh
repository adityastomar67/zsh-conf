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
DEPENDENCIES=("tmux" "ranger" "fd" "ripgrep" "lazygit" "zoxide" "fzf" "lsd" "npm" "ffmpegthumbnailer" "navi")

# Function to check if a package is installed
is_installed() {
    pacman -Qi "$1" &>/dev/null
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
            [[ $res == "y" ]] && {
                sudo pacman -S "$package" --noconfirm
                printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
            }
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
    local options=("Tmux" "Alias" "Custom Functions" "Themer" "Multiple Neovim Setup" "Custom Wallpapers" "Temporary Sourcing File")
    local config_var=("USE_TMUX" "USE_ALIAS" "USE_FUNCTION" "OPT_THEME" "MULTI_NEOVIM" "CUSTOM_WALL" "TEMP_OFFLINE_ALIAS")

    for i in {1..7}; do
        clear
        read -rp "[$i/7] Would you like to use ${options[$i-1]}? [y/N] " res
        [[ $res == "y" ]] && {
            sed -i "s/${config_var[$i-1]}=\"No\"/${config_var[$i-1]}=\"Yes\"/g" "$ZSH_PATH/.zshenv"
            printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
            sleep 1
        }
    done
}

# Main function
main() {
    local DATE=$(date +%Y-%m-%d)
    local ID=$(date +%s)

    # Check if the current .zshrc and .zshenv config files exist and move them if they do
    [ -f "$ZSHRC" ] && mv "$ZSHRC" "$HOME/.zshrc_${DATE}_${ID}" && echo "Moved .zshrc to $HOME/.zshrc_${DATE}_${ID}"
    [ -f "$ZENV" ] && mv "$ZENV" "$HOME/.zshenv_${DATE}_${ID}" && echo "Moved .zshenv to $HOME/.zshenv_${DATE}_${ID}"

    # Clone the Git repository containing Zsh configuration files
    rm -rf "$ZSH_PATH" # Remove existing config if it exists
    git clone --quiet "https://github.com/adityastomar67/zsh-conf.git" "$ZSH_PATH"

    # Create symbolic links to the configuration files in the user's home directory
    ln -s "$ZSH_PATH/.zshrc" "$ZSHRC"
    ln -s "$ZSH_PATH/.zshenv" "$ZENV"

    # Changing shell to Zsh
	printf "%s%sSetting up Z-Shell!%s\n\n" "${BLD}" "${CRE}" "${CNC}"
    sleep 5

    # Change the user's shell to Zsh if it's not already
    if [[ $SHELL != "/usr/bin/zsh" ]]; then
    	printf "%s%sChanging shell to Zsh.\nYour root password is needed to make the change.\n\nAfter that, it is important for you to reboot.\n %s\n" "${BLD}" "${CYE}" "${CNC}"
        chsh -s /usr/bin/zsh
        sleep 2
        printf '%s✓ Shell changed to ZSH!%s\n' "${CGR}" "${CNC}"
        sleep 5
    else
        printf "%s%sYour shell is already ZSH%s\n" "${BLD}" "${CGR}" "${CNC}"
        sleep 5
    fi

    # Install necessary packages
    install_packages

    # Set shell configuration options
    set_shell_config

    [ -e "$ZSH_PATH/install.zsh" ] && rm -rf "$ZSH_PATH/install.zsh"
    return 0
}

# Clear the terminal and run the main function
clear
main "$@"

# Start a new Zsh shell if the script executed successfully
[[ $? -eq 0 ]] && exec zsh || return
