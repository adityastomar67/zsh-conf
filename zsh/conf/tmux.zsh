# ------------------------[  TMUX CONFIGURATION  ]------------------------ #
# Manages Tmux aliases, options, and interactive session launching.


# ........................[  1. Initialization & Guard  ]........................ #

# Exit immediately if disabled in config
[[ "$USE_TMUX" != "Yes" ]] && return

# Exit with a warning if enabled but tmux binary is missing
if ! command -v tmux &>/dev/null; then
    printf "\n\033[0;33m[WARN] USE_TMUX='Yes' but 'tmux' is not installed.\033[0m\n"
    return
fi


# ........................[  2. Aliases  ]........................ #

alias tn='tmux new -s'                 # Create new named session
alias ta='tmux a -t'                   # Attach to specific session
alias tk='tmux kill-session -t'        # Kill specific session
alias tK='tmux kill-server'            # Kill entire server
alias tl='tmux ls'                     # List sessions
alias tpl='tmuxp load'                 # Load tmuxp profile
alias tkill='tmux kill-session -t'


# ........................[  3. Interactive Launcher  ]........................ #

function _tmux_launch() {
    # Guard: Don't run if already inside tmux
    [[ -n "$TMUX" ]] && return

    # Guard: Don't run in non-interactive shells (e.g. scripts/scp)
    [[ ! -t 0 ]] && return

    # Guard: Don't run in IDE terminals (optional, remove if you want tmux in VSCode)
    [[ -n "$VSCODE_INJECTION" || -n "$TERMINAL_EMULATOR" ]] && return


    # --- Logic: Check Sessions ---

    if tmux has-session 2>/dev/null; then

        # Count detached vs total sessions
        local detached_count=$(tmux list-sessions -F "#{session_attached}" | grep "^0$" | wc -l)
        local total_count=$(tmux list-sessions | wc -l)

        # Scenario A: Exactly 1 session exists and it is DETACHED.
        # Action: Auto-attach immediately without prompt.
        if [[ "$detached_count" -eq 1 ]] && [[ "$total_count" -eq 1 ]]; then
            exec tmux attach-session
            return
        fi

        # Scenario B: Multiple sessions or attached sessions exist.
        # Action: Show menu.
        clear
        print -P "%F{green}== Existing Tmux Sessions ==%f"
        echo ""

        # Pretty print sessions
        tmux list-sessions -F "#{?session_attached,#[fg=green],#[fg=red]}● #[fg=default] #S #[fg=grey](Created: #{session_created_string})#{?session_attached, #[fg=yellow][Attached],}"
        echo ""

        print -P -n "%F{blue}Select session %F{grey}(or type new name)%f: "
        read session_choice

        if [[ -z "$session_choice" ]]; then
            return 0 # Enter = Skip Tmux
        elif tmux has-session -t "$session_choice" 2>/dev/null; then
            exec tmux attach-session -t "$session_choice"
        else
            exec tmux new-session -s "$session_choice"
        fi

    else
        # Scenario C: No sessions exist.
        # Action: Ask to create one.
        clear
        print -P "%F{yellow}== No active Tmux sessions ==%f"
        echo ""
        print -P -n "%F{blue}Create new session? %F{grey}[Name / Enter to skip]%f: "
        read new_session

        if [[ -n "$new_session" ]]; then
            exec tmux new-session -s "$new_session"
        fi
    fi
}

# Run the launcher
_tmux_launch

# vim:filetype=zsh
