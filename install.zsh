#!/usr/bin/env zsh

# Check if zsh is installed
# check if current shell is zsh

CRE=$(tput setaf 1)
CYE=$(tput setaf 3)
CGR=$(tput setaf 2)
CBL=$(tput setaf 4)
BLD=$(tput bold)
CNC=$(tput sgr0)

options() {
    clear
    read -q "res?Would you like to use Tmux? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i "s/USE_TMUX=\"No\"/USE_TMUX=\"Yes\"/g" $HOME/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -q "res?Would you like to use Alias? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i "s/USE_ALIAS=\"No\"/USE_ALIAS=\"Yes\"/g" $HOME/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -q "res?Would you like to use Custom Functions? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i "s/USE_FUNCTION=\"No\"/USE_FUNCTION=\"Yes\"/g" $HOME/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -q "res?Would you like to use Themer? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i "s/OPT_THEME=\"No\"/OPT_THEME=\"Yes\"/g" $HOME/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -q "res?Would you like to use Oh-my-zsh? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
       sed -i "s/OMZ=\"No\"/OMZ=\"Yes\"/g" $HOME/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -q "res?Would you like to use Multiple Neovim Setup? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
       sed -i "s/MULTI_NEOVIM=\"No\"/MULTI_NEOVIM=\"Yes\"/g" $HOME/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -q "res?Would you like to have Custom Wallpapers? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        echo "It will take some time to download wallpapers..."
        echo "Wallpapers will be stored at $HOME/.config/wall"
        export CUSTOM_WALL="Yes"
        source $HOME/zsh-conf/zsh/conf/theme.zsh
        sed -i "s/CUSTOM_WALL=\"No\"/CUSTOM_WALL=\"Yes\"/g" $HOME/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }

    clear
    read -q "res?Would you like to have a temporary sourcing file? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        echo "Creating temporary file at $HOME/.temp_zsh..."
        sed -i "s/TEMP_OFFLINE_ALIAS=\"No\"/TEMP_OFFLINE_ALIAS=\"Yes\"/g" $HOME/.zshrc
        printf '%s✓ Done%s\n' "${CGR}" "${CNC}"
        sleep 1
    }
}

main() {

    local DATE=$(date +%Y-%m-%d)
    local ID=$(date +%s)
    local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

    # Changing shell to Zsh
	printf "%s%sChanging default shell to zsh!%s\n" "${BLD}" "${CRE}" "${CNC}"
	printf "%s%sIf your shell is not zsh, it will be changed now.\nYour root password is needed to make the change.\n\nAfter that is important for you to reboot.\n %s\n" "${BLD}" "${CYE}" "${CNC}"
	sleep 5
	if [[ $SHELL != "/usr/bin/zsh" ]]; then
		echo "Changing shell to zsh, your root pass is needed."
		chsh -s /usr/bin/zsh
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
        mv "$ZSHRC" "$HOME/.zshrc_${DATE}_${ID}"
        echo "Moved .zshrc to $HOME/.zshrc_${DATE}_${ID}"
    fi
    if [ -d "$HOME/.config/zsh" ]; then
        # Move the current zsh conf file to the new filename
        mv "$HOME/.config/zsh" "$HOME/.config/zsh_${DATE}_${ID}"
        echo "Moved $HOME/.config/zsh to $HOME/.config/zsh_${DATE}_${ID}"
    fi

    cd $HOME 
    git clone --quiet "https://github.com/adityastomar67/zsh-conf.git"

    command mv $HOME/zsh-conf/zsh $HOME/.config/
    command mv $HOME/zsh-conf/.zshrc $HOME/

    options

    rm -rf $HOME/zsh-conf

    return 0
}

clear
main $@

[[ $? -eq 0 ]] && exec zsh || return

# vim: ft=zsh ts=4 et