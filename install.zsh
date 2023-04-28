#!/usr/bin/env zsh

# Check if zsh is installed
# check if current shell is zsh

options() {

    read -q "res?Would you like to use Tmux? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/USE_TMUX=\"No\"/USE_TMUX=\"Yes\"/g' $HOME/.zshrc
    }

    read -q "res?Would you like to use Alias? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/USE_ALIAS=\"No\"/USE_ALIAS=\"Yes\"/g' $HOME/.zshrc
    }

    read -q "res?Would you like to use Custom Functions? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/USE_FUNCTION=\"No\"/USE_FUNCTION=\"Yes\"/g' $HOME/.zshrc
    }

    read -q "res?Would you like to use Themer? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/OPT_THEME=\"No\"/OPT_THEME=\"Yes\"/g' $HOME/.zshrc
    }

    read -q "res?Would you like to use Oh-my-zsh? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/OMZ=\"No\"/OMZ=\"Yes\"/g' $HOME/.zshrc
    }

    read -q "res?Would you like to use Multiple Neovim Setup? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/MULTI_NEOVIM=\"No\"/MULTI_NEOVIM=\"Yes\"/g' $HOME/.zshrc
    }

    read -q "res?Would you like to have Custom Wallpapers? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/CUSTOM_WALL=\"No\"/CUSTOM_WALL=\"Yes\"/g' $HOME/.zshrc
    }

    read -q "res?Would you like to have a temporary sourcing file? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/TEMP_OFFLINE_ALIAS=\"No\"/TEMP_OFFLINE_ALIAS=\"Yes\"/g' $HOME/.zshrc
    }
}

main() {

    local DATE=$(date +%Y-%m-%d)
    local ID=$(date +%s)
    local ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

    # Check if the current .zshrc file exists
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

main $@

[[ $? -eq 0 ]] && exec zsh || return

# vim: ft=zsh ts=4 et