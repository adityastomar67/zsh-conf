#    ░█░█░█▀█░█▀█░█░█░█▀▀░░░░▀▀█░█▀▀░█░█
#    ░█▀█░█░█░█░█░█▀▄░▀▀█░░░░▄▀░░▀▀█░█▀█
#    ░▀░▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This module defines custom Zsh Line Editor (ZLE) widgets and lifecycle hooks.
#   It prepares advanced functionality (like smart history searching and terminal
#   mode synchronization) without assigning specific keybindings.
#
# Problems Solved
#   - Defines the logic for "Smart Sudo" (toggling sudo on the current/last command).
#   - Prepares the "Edit in Editor" functionality.
#   - Fixes input issues in programs like Vim/Nano by managing terminal modes.
#
# Features / Responsibilities
#   - Widget Registration (`zle -N`).
#   - Autoloading of Zsh contrib functions.
#   - Terminal Application Mode hooks (`smkx`/`rmkx`).
#
# Usage Notes
#   - This file creates the widgets. You must bind keys to them in `keybinds.zsh`.
# ------------------------------------------------------------------------------


# Smart History Search Setup
# ───────────────────────────────────────────────────────────────────────
## Prepares the "Up/Down" arrow logic to filter history based on current input
## rather than just cycling through every command.

# Load the function definitions from Zsh's function path
autoload -Uz up-line-or-beginning-search \
    down-line-or-beginning-search add-zsh-hook edit-command-line

# Register them as ZLE widgets so they can be bound to keys
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search


# Custom Editor Widgets
# ───────────────────────────────────────────────────────────────────────
## Advanced macros to speed up command line editing.
# ------------------------------------------------------------------------------
# Widget: Pop-Command
# Description:
#   Opens the new tmux session in a floating window.
#   Useful for complex running commands separated from the main terminal.
# ------------------------------------------------------------------------------
zle -N pop-command


# ------------------------------------------------------------------------------
# Widget: Edit Command Line
# Description:
#   Opens the current buffer in your external $EDITOR (Vim, Nano, VS Code).
#   Useful for complex multi-line commands or scripting on the fly.
# ------------------------------------------------------------------------------
zle -N edit-command-line


# ------------------------------------------------------------------------------
# Widget: Smart Sudo Toggle
# Description:
#   Toggles 'sudo' at the start of the line. Smartly handles empty buffers
#   by targeting the previous command in history via 'fc'.
# ------------------------------------------------------------------------------
toggle_sudo_prefix() {
    if [[ -z $BUFFER ]]; then
        # Retrieve last command from history and prepend sudo
        LBUFFER="sudo $(fc -ln -1)"
    elif [[ $BUFFER == sudo\ * ]]; then
        # Remove sudo if already present
        LBUFFER="${LBUFFER#sudo }"
    else
        # Prepend sudo to current buffer
        LBUFFER="sudo $LBUFFER"
    fi
}
zle -N toggle_sudo_prefix


# ------------------------------------------------------------------------------
# Widget: Magic Dot Expansion
# Description: Typing '...' becomes '../..', '....' becomes '../../..'
# ------------------------------------------------------------------------------
magic_dot_expansion() {
    if [[ $LBUFFER = *.. ]]; then
        LBUFFER+="/.."
    else
        LBUFFER+="."
    fi
}
zle -N magic_dot_expansion


# Interactive User Assistance
# ───────────────────────────────────────────────────────────────────────
## Widgets that provide context-aware information when the line is empty.
# ------------------------------------------------------------------------------
# Widget: Abbreviation Expansion (Fish-like behavior)
# Description: When you type an alias and press space, it expands to the full command.
# ------------------------------------------------------------------------------
# This widget checks if the word you just typed is an alias.
# If it is, it expands it immediately when you press SPACE.

# function expand-alias-on-space() {
#     # Get the last word typed
#     local word="${LBUFFER##* }"

#     # Check if it is a defined alias
#     if alias "$word" >/dev/null 2>&1; then
#         # Expand it (native Zsh widget)
#         zle _expand_alias
#     fi

#     # Insert the actual space
#     zle self-insert
# }

# # Register the widget and bind it to the Spacebar
# zle -N expand-alias-on-space

# ------------------------------------------------------------------------------
# Widget: Magic Enter
# Description: Executes command if buffer has text; otherwise shows status.
# ------------------------------------------------------------------------------
magic_enter() {
    if [[ -n "$BUFFER" ]]; then
        zle accept-line
        return 0
    fi

    # Tell ZLE we are outputting text to prevent prompt overlap
    zle -I
    printf '\033[2J\033[H'
    print ""

    # ::: Background Jobs Detector :::
    if [[ $(jobs | wc -l) -gt 0 ]]; then
        print "${COLOR[CYAN]}::: Background Jobs :::${COLOR[RESET]}"
        jobs
        print ""
    fi

    # ::: Python VirtualEnv Detector :::
    if [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
        if [[ -z "$VIRTUAL_ENV" ]]; then
             print "${COLOR[RED]}::: ⚠️  PYTHON PROJECT DETECTED (No VirtualEnv Active) ⚠️  :::${COLOR[RESET]}"
             print ""
        fi
    fi

    # ::: Smart Git Status :::
    # Optimization: Use porcelain status to check for ANY change (staged, modified, untracked)
    # This is much faster than ls-files + diff-index.
    # We ignore submodules for speed unless they are dirty.
    if [[ -d .git ]] || git rev-parse --is-inside-work-tree &>/dev/null; then

        # Check if dirty (Exit code 0 = clean, but here we capture output)
        # We capture the first line. If it's not empty, it's dirty.
        if [[ -n $(command git status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n 1) ]]; then
             # Dirty State
            print "${COLOR[YELLOW]}::: Git Status (Dirty) :::${COLOR[RESET]}"
            git status -sb
        else
            # Clean State
            print "${COLOR[GREEN]}::: Git Status (Clean) :::${COLOR[RESET]}\n"
            git log -n 3 --oneline --color=always
        fi
        print "\n"
    fi

    zle redisplay
}
zle -N magic_enter


# ------------------------------------------------------------------------------
# Hook: Auto LS on CD
# Description: Automatically lists files when changing directories.
# ------------------------------------------------------------------------------
# PRE-CALCULATE: Decide the command ONCE at startup.
#    We store the command and args in an array for safe execution.
typeset -a _chpwd_ls_cmd

if (( $+commands[eza] )); then
    _chpwd_ls_cmd=(eza -al --color=always --icons --group-directories-first)
elif (( $+commands[lsd] )); then
    _chpwd_ls_cmd=(lsd -a --group-directories-first)
else
    _chpwd_ls_cmd=(ls -la)
fi

# 2. EXECUTE: The function is now extremely dumb and fast.
function chpwd_auto_ls() {
    emulate -L zsh

    # Return immediately if in HOME to reduce clutter
    [[ "$PWD" == "$HOME" ]] && return

    # 1. Network Guard: Skip on /Volumes or /Network to avoid hangs
    if [[ "$PWD" == /Volumes* || "$PWD" == /Network* ]]; then
        return
    fi
    # 2. Size Guard: Check file count quickly
    #    ls -1A = one column, all files
    #    wc -l  = count lines
    local count=$(command ls -1A | wc -l)
    count=${count// /}

    if (( count > 100 )); then
        print "${COLOR[DIM]}::: Directory contains $count files. Auto-LS skipped. :::${COLOR[RESET]}"
        return
    fi

    # 3. Safe Execution
    print
    "${_chpwd_ls_cmd[@]}"
}
add-zsh-hook chpwd chpwd_auto_ls


# Terminal State Synchronization
# ───────────────────────────────────────────────────────────────────────
## Lifecycle hooks to manage Terminal Application Mode (smkx/rmkx).

if [[ "$TERM" != "dumb" ]] && (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget

    function _enable_app_mode() {
        print -n "${terminfo[smkx]}"
    }

    function _disable_app_mode() {
        print -n "${terminfo[rmkx]}"
    }

    add-zle-hook-widget zle-line-init   _enable_app_mode
    add-zle-hook-widget zle-line-finish _disable_app_mode
fi


# Productivity & UI Enhancements
# ───────────────────────────────────────────────────────────────────────
# ------------------------------------------------------------------------------
# Widget: Fancy Ctrl-Z
# Description: Toggles between backgrounding and foregrounding jobs.
# ------------------------------------------------------------------------------
fancy_ctrl_z() {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="fg"
        zle accept-line
    else
        zle push-input
        zle clear-screen
    fi
}
zle -N fancy_ctrl_z


# ------------------------------------------------------------------------------
# Widget: Copy Buffer to Clipboard
# Description: Cross-platform command line copying.
# ------------------------------------------------------------------------------
# EXECUTE: The widget simply uses the pre-found command.
copy_buffer_to_clipboard() {
    emulate -L zsh

    # Execution: The "Pro" Word-Split Expansion
    #   The '=' sign inside the curly braces tells Zsh to safely split the
    #   string by spaces so flags are passed correctly to the binary.
    #   The ':-cat' ensures a safe fallback even if _clip was accidentally unset.
    print -rn -- "$BUFFER" | ${=_clip:-cat}

    zle -M "✓ Copied buffer to clipboard."
}
zle -N copy_buffer_to_clipboard


# ------------------------------------------------------------------------------
# Widget: Transient Prompt
# Description: Shrinks the prompt to a minimal symbol after execution.
# ------------------------------------------------------------------------------
# 1. Define Variables
typeset -g _TRANS_PROMPT="%{${COLOR[YELLOW]}%}::%{${COLOR[RESET]}%} "
typeset -g _OLD_PROMPT=""

# 2. Restore Hook (Runs before drawing a NEW prompt)
_transient_restore() {
    if [[ -n "$_OLD_PROMPT" ]]; then
        PROMPT="$_OLD_PROMPT"
    fi
}
add-zsh-hook precmd _transient_restore

# 3. Finish Hook (Runs when you hit Enter)
_transient_finish() {
    # Explicitly clear the autosuggestion ghost text
    if (( $+functions[_zsh_autosuggest_clear] )); then
        _zsh_autosuggest_clear
    fi
    # Force clear the display variable to ensure no artifacts remain
    POSTDISPLAY=""

    # Standard Transient Logic
    if [[ "$PROMPT" != "$_TRANS_PROMPT" ]]; then
        _OLD_PROMPT="$PROMPT"
    fi

    PROMPT="$_TRANS_PROMPT"
    zle reset-prompt
}
add-zle-hook-widget line-finish _transient_finish


# Integration Widgets (External Tools)
# ───────────────────────────────────────────────────────────────────────
# ------------------------------------------------------------------------------
# Widget: Git FZF Fixup
# Description: Interactively select a commit to fixup via FZF.
# ------------------------------------------------------------------------------
git_fzf_fixup() {
    if ! is_in_git_repo; then
        zle -M "Not in a git repository."
        return 1
    fi

    local output
    output=$(command git log -n 50 --oneline --color=always | \
        fzf --ansi --no-sort \
            --height=80% \
            --layout=reverse \
            --border \
            --border-label="   Commit Fixup Target " \
            --prompt="Commit > " \
            --info=inline \
            --preview="command git show --color=always {1} | less -R" \
            --preview-window="right:65%:border-left" \
            --expect=ctrl-s,ctrl-e \
            --header=$'\033[1;33m• Enter:\033[0m Fixup (Skip Msg)   \033[1;33m• Ctrl-S:\033[0m Squash (Add Msg)   \033[1;33m• Ctrl-E:\033[0m Amend (Rewrite Msg)\n'
    )

    # 1. Abort if user pressed Escape
    if [[ -z "$output" ]]; then
        zle redisplay
        return 0
    fi

    # 2. Parse FZF's multi-line output natively into a Zsh array
    local -a lines=( "${(@f)output}" )
    local key="${lines[1]}"
    local selected="${lines[2]}"

    # Abort if no commit was highlighted
    if [[ -z "$selected" ]]; then
        zle redisplay
        return 0
    fi

    local hash="${selected[(w)1]}"

    # 3. Execution Router based on the key you pressed
    case "$key" in
        ctrl-s)
            # SQUASH: Opens the editor. When you rebase, Git will COMBINE
            # this new message with the original target's message.
            LBUFFER="git commit --no-verify --squash=$hash"
            ;;
        ctrl-e)
            # AMEND: Opens the editor pre-filled with the target's message.
            # When you rebase, this will COMPLETELY REWRITE the target's message.
            # (Requires Git 2.32+)
            LBUFFER="git commit --no-verify --fixup=amend:$hash"
            ;;
        *)
            # ENTER: Standard Fixup. Skips the editor entirely.
            # The message is discarded during rebase.
            LBUFFER="git commit --no-verify --fixup=$hash"
            ;;
    esac

    # Execute instantly (which will pop open your Vim/Nano editor for Ctrl-S and Ctrl-E)
    zle accept-line
}
zle -N git_fzf_fixup


# ------------------------------------------------------------------------------
# Widget: Docker Smart Connect
# Description: Select a running container and attach to its shell via FZF.
# ------------------------------------------------------------------------------
docker_connect_widget() {
    if ! command -v docker >/dev/null; then
        zle -M "Docker not installed."
        return
    fi

    local cid
    cid=$(docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}" | \
          fzf --header-lines=1 \
              --prompt="🐳 Shell > " \
              --height=40% \
              --layout=reverse \
              --preview='docker logs --tail 20 {1}' \
              --preview-window='right:50%:wrap' | \
          awk '{print $1}')

    if [[ -n "$cid" ]]; then
        LBUFFER="docker exec -it $cid /bin/sh -c '(bash || sh)'"
        zle accept-line
    fi
    zle redisplay
}
zle -N docker_connect_widget


# ------------------------------------------------------------------------------
# Widget: Play sound on wrong command
# Description: Just a fancy way of telling the command is wrong.
# ------------------------------------------------------------------------------
play_error_sound() {
    local exit_code=$?
    local sound_file="$ZSH_CONFIG_ROOT/bin/faaah.mp3"

    # Guard: Proceed if command failed (-ne 0), AND was NOT:
    #   130: SIGINT  (Ctrl+C)
    #   129: SIGHUP  (Window/Tab Closed)
    #   143: SIGTERM (App Quit / Cmd+Q)
    if [[ $exit_code -ne 0 && $exit_code -ne 130 && $exit_code -ne 129 && $exit_code -ne 143 && -f "$sound_file" ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS: Volume is a float where 1.0 is 100%
            afplay -v 0.4 "$sound_file" >/dev/null 2>&1 &!
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Native Linux (Tries paplay, then ffplay, then play)
            # paplay volume is 0-65536 (19660 is ~30%)
            # ffplay volume is 0-100
            # play volume is a float multiplier
            {
                paplay --volume=19660 "$sound_file" || \
                ffplay -volume 40 -nodisp -autoexit "$sound_file" || \
                play -v 0.4 -q "$sound_file"
            } >/dev/null 2>&1 &!
        fi
    fi
}

if [[ ${ENABLE_FANCY_STARTUP:l} == "yes" ]]; then
    add-zsh-hook precmd play_error_sound
fi
