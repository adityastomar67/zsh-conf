# This file was created by the 'adityastomar67/zsh-conf'.
# Do not edit main config file directly. Instead, add any settings overrides in this file.

##--> Some options for user <--##
export OPT_THEME="No"          # Change it to "Yes", if you wants to use theme.sh script.
export PLUG_MANAGER="zap"      # zinit, omz, zap. Choose Wisely
export USE_TMUX="No"           # Change it to "Yes", to automatically load tmux on every new instance of the terminal.
export USE_ALIAS="No"          # Pretty self explainotory.
export USE_FUNCTION="No"       # Pretty self explainotory as well.
export MULTI_NEOVIM="No"       # To use multiple neovim configurations. By by @elijahmanor. Only works with nvim>= 0.9.0
export CUSTOM_WALL="No"        # For my personal wallpapers, source zsh after changing
export PROMPT_THEME="z"        # And many more like gh0st, z, 10k.
export TEMP_OFFLINE_ALIAS="No" # For temporary, offline alias files, to store personal configs that are not meant to be published.
export OPENAI_API_KEY=""       # API Key for chatgpt options for commandline.

##--> Sourcing main config file <--##
[ -r "$HOME/.config/zsh/zshrc" ] && source "$HOME/.config/zsh/zshrc"

##--> Terminal Decorations <--##
if [ -x $HOME/.local/bin/colorscript ]; then
    $HOME/.local/bin/colorscript -r # Random Asciiart for bling terminal. Stored in ~/.local/share/asciiart
elif [ -x motivate ]; then
    motivate; echo                  # Random Motivational Quotes
fi

# TIP: Install binaries like fzf, tmux, zoxide, bat, motivate, lazygit to make this config work like charm.
