# This file was created by the 'adityastomar67/zsh-conf'.
# Do not edit main config file directly. Instead, add any settings overrides in this file.

##--> Sourcing main config file <--##
[ -r "$ZSH_PATH/zsh/zshrc" ] && source "$ZSH_PATH/zsh/zshrc"

##--> Terminal Decorations <--##
if [ -x $HOME/.local/bin/colorscript ]; then
    $HOME/.local/bin/colorscript -r # Random Asciiart for bling terminal. Stored in ~/.local/share/asciiart
elif [ -x motivate ]; then
    motivate; echo                  # Random Motivational Quotes
fi

# TIP: Install binaries like fzf, tmux, zoxide, bat, motivate, lazygit to make this config work like charm.
