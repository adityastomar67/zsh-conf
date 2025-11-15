# This file was created by the 'adityastomar67/zsh-conf'.
# Do not edit the main config file directly. Instead, add any settings overrides in this file.

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

##--> Sourcing main config file <--##
[ -r "$ZSH_PATH/zsh/zshrc" ] && source "$ZSH_PATH/zsh/zshrc"

##--> Terminal Decorations <--##
clear
if [[ -n "$SHOW_CONFIG_WARNING" ]]; then    # Only runs for first time after the Installer.  
    printf "\e[1;31m%s \e[34m%s \e[0m\e[4m%s\e[24m\e[34m\e[0m\n" \
        "[#IMP]" \
        "Do not edit the main config file directly" \
        "{~/.config/zsh-conf/zshrc}," 

    printf "\e[34m       %s \e[0m\e[4m%s\e[24m\e[34m\e[0m\n\n" \
        "Instead, add any setting overrides in this file" \
        "{~/.zshrc}."

    echo "RUN ZSH --help fro help"
elif [ -x $HOME/.local/bin/colorscript ]; then
    $HOME/.local/bin/colorscript -r         # Random Asciiart for bling terminal. Stored in ~/.local/share/asciiart
elif [ -x motivate ]; then
    motivate; echo                          # Random Motivational Quotes
fi

# TIP: Install binaries like fzf, tmux, zoxide, bat, motivate, lazygit, navi to make this config work like charm.
