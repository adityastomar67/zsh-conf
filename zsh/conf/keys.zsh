# █▄▀ █▀▀ █▄█ █▀▄▀█ ▄▀█ █▀█ █▀
# █ █ ██▄  █  █ ▀ █ █▀█ █▀▀ ▄█

##--> Basic Keymaps <--##
bindkey "^k" up-line-or-beginning-search   # Up
bindkey "^j" down-line-or-beginning-search # Down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey -s '^K' 'ls^M'
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
# bindkey -s '^o' 'fzf-find-files^M'

##--> Prepend sudo on the current commmand <--##
# bindkey -M emacs '' _sudo_command_line
# bindkey -M vicmd '' _sudo_command_line
# bindkey -M viins '' _sudo_command_line

##--> Fix backspace and other stuff in vi-mode <--##
bindkey -M viins '\e/' _vi_search_fix
bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char
bindkey "^U" backward-kill-line
# bindkey '^P' _toggle-right-prompt
# bindkey '^Y' _toggle-left-prompt

##--> VI/Emacs mode <--##
bindkey -v  # -e will be for emacs

##--> Use vim keys in tab complete menu <--##
bindkey -M menuselect '^h' vi-backward-char
bindkey -M menuselect '^k' vi-up-line-or-history
bindkey -M menuselect '^l' vi-forward-char
bindkey -M menuselect '^j' vi-down-line-or-history
bindkey -M menuselect '^[[Z' vi-up-line-or-history
bindkey -v '^?' backward-delete-char

# vim:filetype=zsh
