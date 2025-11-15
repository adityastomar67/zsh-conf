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

print() {
    printf "${BLD}$2[$1] $3${CNC}\n"
}
header() {
    clear
    echo "
▒███████▒  ██████  ██░ ██  ▄████▄   ▒█████   ███▄    █   █████▒
▒ ▒ ▒ ▄▀░▒██    ▒ ▓██░ ██▒▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █ ▓██   ▒ 
░ ▒ ▄▀▒░ ░ ▓██▄   ▒██▀▀██░▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒▒████ ░ 
  ▄▀▒   ░  ▒   ██▒░▓█ ░██ ▒▓▓▄ ▄██▒▒██   ██░▓██▒  ▐▌██▒░▓█▒  ░ 
▒███████▒▒██████▒▒░▓█▒░██▓▒ ▓███▀ ░░ ████▓▒░▒██░   ▓██░░▒█░    
░▒▒ ▓░▒░▒▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒  ▒ ░    
░░▒ ▒ ░ ▒░ ░▒  ░ ░ ▒ ░▒░ ░  ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░ ░      
░ ░ ░ ░ ░░  ░  ░   ░  ░░ ░░        ░ ░ ░ ▒     ░   ░ ░  ░ ░    
  ░ ░          ░   ░  ░  ░░ ░          ░ ░           ░         
░                         ░                                    
"
}

# Detect OS and package manager
if [[ "$OSTYPE" == "darwin"* ]]; then
    PKG_MANAGER="brew"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
else
    print "ERROR" $CRE "Unsupported OS or Package Manager not found!"
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
    print "NOTE" $CBL "INSTALLING PACKAGES..."
    sleep 2

    for package in "${DEPENDENCIES[@]}"; do
        header
        print "NOTE" $CBL "INSTALLING PACKAGES..."
        if ! is_installed "$package"; then
            printf "Would you like to install $package? [y/N]: "
            read res
            if [[ $res == "y" ]]; then
                if [[ "$PKG_MANAGER" == "pacman" ]]; then
                    sudo pacman -S "$package" --noconfirm
                elif [[ "$PKG_MANAGER" == "brew" ]]; then
                    brew install "$package"
                fi
                printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
                echo
                print "DONE" $CGR "$package is installed."
                sleep 2
            fi
        else
            printf '%s✓ %s is already installed on your system!%s\n' "${CGR}" "$package" "${CNC}"
            sleep 1
        fi
    done
    header
    print "DONE" $CGR "All packages successfully installed as per your choice!"
    sleep 2
}

# Function to set shell configuration options
set_shell_config() {
    print "NOTE" $CBL "SETTING SHELL-CONFIG..."
    sleep 2
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
            header
            print "NOTE" $CBL "SETTING SHELL-CONFIG...\n"
            printf "[$((i+1))/$total] Enable ${options[$i]}? [y/N]: "
            read res

            if [[ $res =~ ^[Yy]$ ]]; then
                sed -i "s/${config_var[$i]}=\"No\"/${config_var[$i]}=\"Yes\"/g" "$ZSH_PATH/.zshenv"
                printf "${CGR}✓ Enabled: %s${CNC}" "${options[$i]}"
            else
                printf "${CRE}X Skipped: %s${CNC}" "${options[$i]}"
            fi
            sleep 2
        done
    else
        print "ERROR" $CRE "$ZSH_PATH/.zshenv not found."

    fi
}


check_and_install_zsh() {
    if ! command -v zsh &>/dev/null; then
        print "QUESTION" $CYE "Zsh is not installed. Would you like to install it? [y/N]"
        read res
        if [[ $res == "y" ]]; then
            if [[ "$PKG_MANAGER" == "pacman" ]]; then
                sudo pacman -S zsh --noconfirm
            elif [[ "$PKG_MANAGER" == "brew" ]]; then
                brew install zsh
            fi
            print "DONE" $CGR "Zsh has been installed successfully!"

        else
            print "NOTE" $CYE "Installation of Zsh is skipped."

        fi
    else
        print "NOTE" $CGR "Zsh is already installed."
    fi
    sleep 2
}

# Main function
main() {
    local DATE=$(date +%Y-%m-%d)
    local ID=$(date +%s)

    check_and_install_zsh
    header
    # Check if the current .zshrc and .zshenv config files exist and move them if they do
    print "NOTE" $CYE "Backing up the previous config files, ${CRE}IF FOUND!!"

    [ -f "$ZSHRC" ] && mv "$ZSHRC" "$HOME/.zshrc_${DATE}_${ID}" \
        && printf "${CBL}    Moved .zshrc --> $HOME/.zshrc_${DATE}_${ID}\n${CNC}"
    [ -f "$ZENV" ] && mv "$ZENV" "$HOME/.zshenv_${DATE}_${ID}" \
        && printf "${CBL}    Moved .zshenv --> $HOME/.zshenv_${DATE}_${ID}\n\n${CNC}"

    # Clone the Git repository containing Zsh configuration files
    [ -d "$ZSH_PATH" ] && mv "$ZSH_PATH" "${ZSH_PATH}_${DATE}_${ID}"  # Backup existing config if it exists
    git clone --quiet "https://github.com/adityastomar67/zsh-conf.git" "$ZSH_PATH"
    print "NOTE" $CYE "New ZSH Config downloaded to \"$ZSH_PATH\"!"

    # Create symbolic links to the configuration files in the user's home directory
    ln -sf "$ZSH_PATH/.zshrc" "$ZSHRC" \
        && printf "${CBL}    Linked new .zshrc!\n${CNC}"
    ln -sf "$ZSH_PATH/.zshenv" "$ZENV" \
        && printf "${CBL}    Linked new .zshenv!\n${CNC}"

    sleep 2
    header

    # Changing shell to Zsh
    print "NOTE" $CYE "Setting up Z-Shell!\n"
    sleep 5
    header

    # Change the user's shell to Zsh if it's not already
    if [[ $SHELL != "/usr/bin/zsh" ]]; then
        print "NOTE" $CYE "Changing shell to Zsh.\nYour root password is needed to make the change.\n\nAfter that, it is important for you to reboot.\n\n"
        chsh -s /usr/bin/zsh
        sleep 2
        print "DONE" $CGR "Shell changed to ZSH!"
        sleep 5
    else
        print "NOTE" $CYE "Your shell is already ZSH"
        sleep 5
    fi

    # Install necessary packages
    header
    install_packages

    # Set shell configuration options
    set_shell_config

    if command -v zsh &> /dev/null; then
        header
        print "NOTE" $CYE "Compiling Zsh configuration files..."
        zsh -c "autoload -U zrecompile && zrecompile -p $ZSH_PATH/.zshrc" 2>/dev/null || true
    fi

    header
    print "NOTE" $CYE "REMOVING INSTALLER SCRIPTS..."
    sleep 2
    [ -e "$ZSH_PATH/install.zsh" ] && rm -rf "$ZSH_PATH/install.zsh" \
        && printf "${CBL} REMOVED.${CNC}"
    sleep 2
    return 0
}

# Clear the terminal and run the main function
header
main "$@"
header
print "DONE" $CGR "INSTALLATION FINISHED."

[[ $? -eq 0 ]] && SHOW_CONFIG_WARNING=1 exec zsh || return
