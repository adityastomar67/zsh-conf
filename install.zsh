#!/usr/bin/env zsh

CRE=$(tput setaf 1)
CYE=$(tput setaf 3)
CGR=$(tput setaf 2)
CBL=$(tput setaf 4)
BLD=$(tput bold)
CNC=$(tput sgr0)
ZSH_PATH="$HOME/.config/zsh-conf"
dependencies=(tmux ranger fd ripgrep lazygit zoxide fzf lsd npm)

##--> Check if the package is already installed or not <--##
is_installed() {
	pacman -Qi "$1" &>/dev/null
	return $?
}

##--> Install necessary pkgs <--##
install_pkg() {
	printf "%s%sInstalling Packages...%s\n" "${BLD}" "${CBL}" "${CNC}"
	printf "%s%sChecking for required packages...%s\n\n" "${BLD}" "${CBL}" "${CNC}"

	for package in "${dependencies[@]}"; do
    read -rp "Would you like to install $package? [y/N] " res
    [[ $res == "y" ]] && {
		if ! is_installed "$package"; then
			sudo pacman -S "$package" --noconfirm
			printf "\n"
            printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
		else
			printf '%s✓ %s is already installed on your system!%s\n' "${CGR}" "$package" "${CNC}"
			sleep 1
		fi
    }
	done
    printf '%s[ ✓ DONE ] All packaegs successfully done as your choice!%s\n' "${CGR}" "${CNC}"
	sleep 2
}

##--> Options for shell configurations <--##
options() {
    clear
    read -rp "[1/7] Would you like to use Tmux? [y/N] " res
    [[ $res == "y" ]] && {
        sed -i "s/USE_TMUX=\"No\"/USE_TMUX=\"Yes\"/g" $ZSH_PATH/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -rp "[2/7] Would you like to use Alias? [y/N] " res
    [[ $res == "y" ]] && {
        sed -i "s/USE_ALIAS=\"No\"/USE_ALIAS=\"Yes\"/g" $ZSH_PATH/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -rp "[3/7] Would you like to use Custom Functions? [y/N] " res
    [[ $res == "y" ]] && {
        sed -i "s/USE_FUNCTION=\"No\"/USE_FUNCTION=\"Yes\"/g" $ZSH_PATH/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -rp "[4/7] Would you like to use Themer? [y/N] " res
    [[ $res == "y" ]] && {
        sed -i "s/OPT_THEME=\"No\"/OPT_THEME=\"Yes\"/g" $ZSH_PATH/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -rp "[5/7] Would you like to use Multiple Neovim Setup? [y/N] " res
    [[ $res == "y" ]] && {
       sed -i "s/MULTI_NEOVIM=\"No\"/MULTI_NEOVIM=\"Yes\"/g" $ZSH_PATH/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -rp "[6/7] Would you like to have Custom Wallpapers? [y/N] " res
    [[ $res == "y" ]] && {
        echo "It will take some time to download wallpapers..."
        echo "Wallpapers will be stored at $HOME/.config/wall"
        export CUSTOM_WALL="Yes"
        source $ZSH_PATH/zsh/conf/theme.zsh
        sed -i "s/CUSTOM_WALL=\"No\"/CUSTOM_WALL=\"Yes\"/g" $ZSH_PATH/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -rp "[7/7] Would you like to have a temporary sourcing file? [y/N] " res
    [[ $res == "y" ]] && {
        echo "Creating temporary file at $HOME/.temp_zsh..."
        sed -i "s/TEMP_OFFLINE_ALIAS=\"No\"/TEMP_OFFLINE_ALIAS=\"Yes\"/g" $ZSH_PATH/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }
}

main() {
    local DATE=$(date +%Y-%m-%d)
    local ID=$(date +%s)
    local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

    # Changing shell to Zsh
	printf "%s%sSetting up Z-Shell!%s\n\n" "${BLD}" "${CRE}" "${CNC}"
	printf "%s%sIf your shell is not zsh, it will be changed now.\nYour root password is needed to make the change.\n\nAfter that, it is important for you to reboot.\n %s\n" "${BLD}" "${CYE}" "${CNC}"
	
    sleep 5
	if [[ $SHELL != "/usr/bin/zsh" ]]; then
		echo "Changing shell to zsh, your root pass is needed."
		chsh -s /usr/bin/zsh
        sleep 2
		printf '%s✓ Shell changed to ZSH!%s\n' "${CGR}" "${CNC}"
		sleep 5
	else
		printf "%s%sYour shell is already ZSH%s\n" "${BLD}" "${CGR}" "${CNC}"
		sleep 5
	fi

    # Check if the current .zshrc config files exists
    [ -d "$HOME/.oh-my-zsh" ]   && rm -rf "$HOME/.oh-my-zsh"
    [ -d "$HOME/.zinit" ]       && rm -rf "$HOME/.zinit"

    if [ -f "$ZSHRC" ]; then
        # Move the current .zshrc file to the new filename
        command mv "$ZSHRC" "$HOME/.zshrc_${DATE}_${ID}"
        echo "Moved .zshrc to $HOME/.zshrc_${DATE}_${ID}"
    elif [ -L "$ZSHRC" ]; then
        command rm "$ZSHRC"
    fi
    
    if [ -d "$HOME/.config/zsh-conf" ]; then
        # Move the current zsh conf file to the new filename
        command mv "$HOME/.config/zsh-conf" "$HOME/.config/zsh-conf_${DATE}_${ID}"
        echo "Moved $HOME/.config/zsh-conf to $HOME/.config/zsh-conf_${DATE}_${ID}"
    fi

    cd $HOME 
    mkdir -p $HOME/.config/zsh-conf

    # Update the ZSH_CONF_PATH variable where you clone the repo
    git clone --quiet "https://github.com/adityastomar67/zsh-conf.git" $HOME/.config/zsh-conf

    ln -s $HOME/.config/zsh-conf/.zshrc $HOME/.zshrc
    install_pkg
    options
    return 0
}

clear
main $@

[[ $? -eq 0 ]] && exec zsh || return

# vim: ft=zsh ts=4 et