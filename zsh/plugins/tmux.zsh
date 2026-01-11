#!/usr/bin/env zsh
#    ░▀█▀░█▄█░█░█░█░█░░░░▀▀█░█▀▀░█░█
#    ░░█░░█░█░█░█░▄▀▄░░░░▄▀░░▀▀█░█▀█
#    ░░▀░░▀░▀░▀▀▀░▀░▀░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This module manages the integration with Tmux (Terminal Multiplexer).
#   It handles command aliases and provides a smart, interactive launcher
#   function that runs when the shell initializes.
#
# Problems Solved
#   - Prevents recursive Tmux sessions (Tmux inside Tmux).
#   - Auto-attaches to existing sessions (stops orphaned session buildup).
#   - Provides a menu to select sessions visually instead of memorizing names.
#   - Reduces typing for common commands (`tn`, `ta`, `tk`).
#
# Features / Responsibilities
#   - Feature Guard (Enable/Disable via config).
#   - Interactive Session Manager (Menu system).
#   - Smart Auto-Attach Logic.
#   - IDE/Script Detection (prevents launching in VSCode/scripts).
#
# Usage Notes
#   - Enable by setting `ENABLE_AUTO_TMUX="Yes"` in .zshenv.
#   - Requires `tmux` binary to be installed.
#
# Project: Zsh-conf
# ------------------------------------------------------------------------------


# Initialization & Feature Guard
# ─────────────────────────────────────────────────────────────
## Check if the user wants this feature and if the binary exists

# Dependency Check
# is_installed checks if the key exists in the command hash table.
if ! is_installed tmux; then
    echo "\n${COLOR[YELLOW]}[WARN] Auto-Tmux enabled but 'tmux' binary not found.${COLOR[RESET]}"
    return
fi


# Aliases
# ─────────────────────────────────────────────────────────────
## Shortcuts for session management.

alias tn='tmux new -s'              # Create new named session
alias ta='tmux a -t'                # Attach to specific session
alias tk='tmux kill-session -t'     # Kill specific session
alias tK='tmux kill-server'         # Kill entire server (Force quit all)
alias tl='tmux ls'                  # List sessions
alias tpl='tmuxp load'              # Load tmuxp profile (if installed)
alias tkill='tmux kill-session -t'  # Verbose alias for tk


# Interactive Launcher
# ─────────────────────────────────────────────────────────────
## The core logic for handling startup behavior.

function launch_tmux_interactive_session() {

    # ── guards ─────────────────────────────────────────────────────────────

    # 1. Interactivity Guard: Don't run in scripts, pipes, or scp connections.
    #    -t 0 checks if File Descriptor 0 (Stdin) is a terminal.
    [[ ! -t 0 ]] && return

    # 2. Emulator Guard: Don't run inside IDE terminals (VSCode, IntelliJ).
    #    These often handle their own scrolling/multiplexing.
    if [[ -n "$VSCODE_INJECTION" || -n "$TERMINAL_EMULATOR" ]]; then
        return
    fi

    # ── session logic ──────────────────────────────────────────────────────

    # Check if ANY sessions exist
    if tmux has-session 2>/dev/null; then

        # Calculate session states
        # grep "^0$" counts lines where 'attached' is 0 (false)
        local count_detached_sessions=$(tmux list-sessions -F "#{session_attached}" | grep "^0$" | wc -l)
        local count_total_sessions=$(tmux list-sessions | wc -l)

        # ----------------------------------------------------------------------
        # Scenario A: Single Detached Session
        # Action: Auto-attach immediately. No user interaction required.
        if [[ "$count_detached_sessions" -eq 1 ]] && [[ "$count_total_sessions" -eq 1 ]]; then
            exec tmux attach-session
            return
        fi

        # ----------------------------------------------------------------------
        # Scenario B: Multiple Sessions (or currently attached ones)
        # Action: Show a menu to let the user choose.

        clear
        echo "${COLOR[GREEN]}== Existing Tmux Sessions ==${COLOR[RESET]}"

        # Tmux Formatting:
        # #{?cond,true,false} : Conditional logic
        # #S                  : Session Name
        # #{session_created}  : Creation time
        tmux list-sessions -F "#{?session_attached,#[fg=green],#[fg=red]}● #[fg=default] #S #[fg=grey](Created: #{session_created_string})#{?session_attached, #[fg=yellow][Attached],}"
        echo ""

        echo -en "${COLOR[BLUE]}Select session ${COLOR[GREY]}(or type new name)${COLOR[RESET]}: "
        read user_session_input

        # Handle User Input
        if [[ -z "$user_session_input" ]]; then
            # Enter Key = Skip Tmux, drop to normal shell
            return 0
        elif tmux has-session -t "$user_session_input" 2>/dev/null; then
            # Attach to existing
            exec tmux attach-session -t "$user_session_input"
        else
            # Create new
            exec tmux new-session -s "$user_session_input"
        fi

    else
        # ----------------------------------------------------------------------
        # Scenario C: No Sessions Exist
        # Action: Prompt to create the first one.

        clear
        echo "${COLOR[YELLOW]}== No active Tmux sessions ==${COLOR[RESET]}"
        echo -en "${COLOR[BLUE]}Create new session? ${COLOR[GREY]}[Name / Enter to skip]${COLOR[RESET]}: "
        read user_new_session_name

        if [[ -n "$user_new_session_name" ]]; then
            exec tmux new-session -s "$user_new_session_name"
        fi
    fi
}

# Execute the launcher
launch_tmux_interactive_session
