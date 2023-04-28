#!/usr/bin/env zsh

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

    cd $HOME 
    git clone --quiet "https://github.com/adityastomar67/zsh-conf.git"

    command mv $HOME/zsh-conf/zsh $HOME/.config/
    command mv $HOME/zsh-conf/.zshrc $HOME/

    read -q "res?Would you like to use Tmux? [y/N] "
    echo ""
    [[ $res == "y" ]] && {
        sed -i 's/USE_TMUX=\"No\"/USE_TMUX=\"Yes\"/g' $HOME/.zshrc
    }

    return 0
}

main $@

[[ $? -eq 0 ]] && exec zsh || return

# vim: ft=zsh ts=4 et