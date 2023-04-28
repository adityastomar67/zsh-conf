# ▀█▀ █▀▄▀█ █ █ ▀▄▀
#  █  █ ▀ █ █▄█ █ █

if [ $USE_TMUX = "Yes" ]; then
    if command -v tmux >/dev/null; then
    
        ##--> Tmux Launching <--##
        # -2 flag for TMUX to enable 256 colors, use exec in place of command to make terminal close after exiting tmux
        if [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then command tmux -2; fi

        ##--> Interactive Tmux Sessions attaching <--##
        # if [[ -z $TMUX ]]; then
        #
        #    if [[ $(tmux list-sessions | wc -l) -ne 0 ]]; then
        #        command clear
        #        if [[ $(tmux list-sessions -F"#{?session_attached,,x}" | grep "x" | wc -l) -eq 1 ]]; then
        #            tmux attach-session -t $(tmux list-sessions -F"#{?session_attached,,#S}"  )
        #            return
        #        else
        #            printf '\033[32;1mCurrent \033[33;1mtmux \033[32;1msessions\033[0m:\n'
        #            tmux list-sessions -F"#S - (#{?session_attached,Attached,Not Attached})"
        #            printf '\033[34;1mAttach session?\033[0;m: [\033[35;1mname\033[0m] \033[37;2m(empty if none)\033[0m: '
        #        fi
        #
        #    else
        #        command clear
        #        printf '\033[34;1mNo \033[33;1mtmux \033[34;1msessions active\n'
        #        printf '\033[34;1mCreate new session?\033[0;m: [\033[35;1mname\033[0m] \033[37;2m(empty if none)\033[0m: '
        #    fi
        #
        #    read session
        #    if [[ -n $session ]]; then
        #        if tmux list-sessions -F"#S" | grep -q "$session"; then
        #            tmux attach-session -t $session
        #            return
        #        elif [[ $session == new ]]; then
        #            tmux new-session
        #            return
        #        else
        #            tmux new-session -s $session
        #            return
        #        fi
        #    fi
        #
        #    return
        # fi
    fi
fi

# vim:filetype=zsh
