#    ░█▀█░█▀▄░█▀█░█▄█░█▀█░▀█▀░░░░▀▀█░█▀▀░█░█
#    ░█▀▀░█▀▄░█░█░█░█░█▀▀░░█░░░░░▄▀░░▀▀█░█▀█
#    ░▀░░░▀░▀░▀▀▀░▀░▀░▀░░░░▀░░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This file controls the visual appearance of the command line prompt (PS1/RPROMPT).
#   It allows switching between different themes ("Z", "10k", "Gh0st") via the
#   PROMPT_THEME environment variable.
#
# Problems Solved
#   - Provides contextual information (Git branch, status, errors).
#   - Visualizes execution time for long-running commands.
#   - Updates terminal window titles dynamically.
#   - specific logic for different "vibes" (Minimal vs. Info-rich).
#
# Features / Responsibilities
#   - Dynamic Prompt Expansion (PROMPT_SUBST).
#   - Git/Hg Integration (via vcs_info or raw commands).
#   - Execution Timer.
#   - Auto-ls functionality.
#   - Window Title Management.
#
# Usage Notes
#   Set `export PROMPT_THEME="gh0st"` in .zshenv to switch themes.
#
# Project: Zsh-conf
# ------------------------------------------------------------------------------


# 1. Shared Utilities
# ─────────────────────────────────────────────────────────────
## Helper functions used across multiple themes to avoid code duplication.

# Enable dynamic expansion within the prompt string.
# Without this, variables like ${vcs_info_msg_0_} won't update.
setopt PROMPT_SUBST
autoload -Uz vcs_info

# Function: get_random_prompt_symbol
# Description:
#   Returns a random "ignition" symbol from a curated list.
#   Adds visual variety to every new line.
function get_random_prompt_symbol() {
    local -a symbols=(" " "" "-->" "➤" "󰮯 " "")

    # Select random index based on array length
    echo "${symbols[1 + $RANDOM % ${#symbols[@]}]}"
}

# Function: check_git_untracked_status
# Description:
#   Checks if the current Git repository has untracked files (??).
#   Returns 0 (true) if untracked files exist, 1 (false) otherwise.
function check_git_untracked_status() {
    # Guard: Git must be installed
    is_installed git || return 1

    # Check if inside work tree to avoid errors
    if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]]; then
        # Grep for '??' in porcelain output (fastest check)
        git status --porcelain | grep '??' &>/dev/null
    else
        return 1
    fi
}


# 2. Theme: 'Z'
# ─────────────────────────────────────────────────────────────
## A minimalist theme heavily reliant on Zsh's built-in `vcs_info` module.
## Focuses on speed and low visual noise.

function theme_z_setup() {

    # ── vcs_info configuration ─────────────────────────────────────────────

    # Enable only Git for performance
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' check-for-changes true

    # Format String:
    # %m = Misc info, %u = Unstaged, %c = Staged, %b = Branch
    # We use ${COLOR[...]} variables assuming they are loaded from lib/_ui.color.zsh
    zstyle ':vcs_info:git:*' formats \
        " %{${COLOR[BLUE]}%}(%{${COLOR[RED]}%}%m%u%c%{${COLOR[YELLOW]}%}${icons[VCS_BRANCH_ICON]:-}%{${COLOR[MAGENTA]}%} %b%{${COLOR[BLUE]}%}) ${icons[VCS_GIT_GITHUB_ICON]:-}"

    # Hook: Register custom function to handle untracked files
    zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

    # Hook Implementation:
    # Appends a bang (!) to the staged string if untracked files exist.
    function +vi-git-untracked() {
        if check_git_untracked_status; then
            hook_com[staged]+='!'
        fi
    }

    # ── prompt hooks ───────────────────────────────────────────────────────

    # Ensure vcs_info runs before every prompt display
    add-zsh-hook precmd vcs_info

    # ── final assembly ─────────────────────────────────────────────────────

    local prompt_symbol=$(get_random_prompt_symbol)

    # Left Prompt: Time | Symbol | Path
    PROMPT="%T %{${COLOR[YELLOW]}%}${prompt_symbol}%{${COLOR[RESET]}%} %{${COLOR[BLUE]}%}%1~%{${COLOR[RESET]}%} "

    # Right Prompt: Git Info
    RPROMPT=\$vcs_info_msg_0_
}


# 3. Theme: '10k' (Custom Power User)
# ─────────────────────────────────────────────────────────────
## A complex, feature-rich theme designed to mimic Powerlevel10k features
## manually. Handles window titles, execution timers, and auto-ls.

function theme_10k_setup() {

    # ── p10k integration toggles ───────────────────────────────────────────
    # If the actual Powerlevel10k plugin is installed, these helpers toggle segments.

    function _10k_toggle_segment() {
        if (( $+functions[p10k] )); then
            p10k display "*/$1"=hide,show
        fi
    }
    function _toggle-right-prompt() { _10k_toggle_segment right; }
    function _toggle-left-prompt()  { _10k_toggle_segment left; }


    # ── vcs_info configuration ─────────────────────────────────────────────

    zstyle ':vcs_info:*' enable git hg
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' use-simple true
    zstyle ':vcs_info:*' stagedstr "%F{green}●%f"
    zstyle ':vcs_info:*' unstagedstr "%F{red}●%f"

    # Git Formats
    zstyle ':vcs_info:git+set-message:*' hooks git-untracked
    zstyle ':vcs_info:git*:*' formats '[%b%m%c%u] '
    zstyle ':vcs_info:git*:*' actionformats '[%b|%a%m%c%u] '

    # Mercurial (Hg) Formats
    zstyle ':vcs_info:hg*:*' formats '[%m%b] '
    zstyle ':vcs_info:hg*:*' actionformats '[%b|%a%m] '
    zstyle ':vcs_info:hg*+gen-hg-bookmark-string:*' hooks hg-bookmarks
    zstyle ':vcs_info:hg*+set-message:*' hooks hg-message


    # ── window title management ────────────────────────────────────────────
    # Dynamically updates the terminal emulator window title (e.g., "vim filename").

    function _10k_set_window_title() {
        emulate -L zsh
        # \e]0;... \a is the standard xterm escape sequence for window titles
        print -Pn "\e]0;${1:gs/$/\\$}:q\a"
    }

    # Local counter to track history depth
    typeset -g HISTCMD_LOCAL=0

    function _10k_update_window_title() {
        emulate -L zsh
        local title_content

        # Logic:
        # 1. precmd: Command finished. Show Current Directory.
        # 2. preexec: Command running. Show "Dir > Command".

        if [[ $1 == "precmd" ]]; then
            if [[ HISTCMD_LOCAL -eq 0 ]]; then
                title_content="$(basename "$PWD")"
            else
                local last_cmd=$(history | tail -1 | awk '{print $2}')
                title_content="$([ -z "$TMUX" ] && echo "$(basename "$PWD") > ")$last_cmd"
            fi
        else
            # Pre-exec (Running)
            setopt EXTENDED_GLOB
            HISTCMD_LOCAL=$((++HISTCMD_LOCAL))

            # Remove command arguments/ssh prefixes for cleaner title
            local trimmed_cmd="${2[(wr)^(*=*|mosh|ssh|sudo)]}"
            title_content="$([ -z "$TMUX" ] && echo "$(basename "$PWD") > ")$trimmed_cmd"
        fi

        _10k_set_window_title "$title_content"
    }

    add-zsh-hook precmd  _10k_update_window_title
    add-zsh-hook preexec _10k_update_window_title


    # ── execution timer ────────────────────────────────────────────────────
    # Calculates how long the last command took and displays it in RPROMPT.

    typeset -F SECONDS

    function _10k_record_start_time() {
        ZSH_START_TIME=${ZSH_START_TIME:-$SECONDS}
    }
    add-zsh-hook preexec _10k_record_start_time

    function _10k_report_duration() {
        if [[ -n "$ZSH_START_TIME" ]]; then
            local delta=$(($SECONDS - $ZSH_START_TIME))
            local elapsed_str=""

            # Calculate Days, Hours, Minutes, Seconds
            local d=$((delta / 86400))
            local h=$(((delta - d * 86400) / 3600))
            local m=$(((delta - d * 86400 - h * 3600) / 60))
            local s=$(($delta - d * 86400 - h * 3600 - m * 60))

            # Build string parts
            [[ "$d" != "0" ]] && elapsed_str="${d}d"
            [[ "$h" != "0" ]] && elapsed_str="${elapsed_str}${h}h"
            [[ "$m" != "0" ]] && elapsed_str="${elapsed_str}${m}m"

            if [[ -z "$elapsed_str" ]]; then
                # If less than a minute, show decimal seconds
                s="$(print -f "%.2f" $s)s"
            else
                # If long duration, round seconds to integer
                s="$((~~$s))s"
            fi
            elapsed_str="${elapsed_str}${s}"

            # Inject into RPROMPT with Cyan color
            # Note: $__Prompt is a global state hash (assumed defined elsewhere or loosely typed)
            export RPROMPT="%F{cyan}%{$__Prompt[ITALIC_ON]%}${elapsed_str}%{$__Prompt[ITALIC_OFF]%}%f $RPROMPT_BASE"
            unset ZSH_START_TIME
        else
            # No command ran (just hit enter), reset RPROMPT
            export RPROMPT="$RPROMPT_BASE"
        fi
    }
    add-zsh-hook precmd _10k_report_duration


    # ── utilities ──────────────────────────────────────────────────────────

    # Auto-LS: Automatically list files when entering a directory
    function _10k_auto_ls() {
        if [[ "$ZSH_EVAL_CONTEXT" == "toplevel:shfunc" ]]; then
            if (( $+commands[eza] )); then
                eza --icons -a
            elif (( $+commands[exa] )); then
                exa --icons -a
            else
                ls -a
            fi
        fi
    }
    add-zsh-hook chpwd _10k_auto_ls

    # VCS Optimization: Only run vcs_info for relevant commands
    function _10k_record_last_command() {
        __Prompt[LAST_COMMAND]="$2"
    }
    add-zsh-hook preexec _10k_record_last_command

    function _10k_conditional_vcs_info() {
        local last_cmd="$__Prompt[LAST_COMMAND]"
        __Prompt[LAST_COMMAND]="<unset>"

        # Check first word of command
        case "$last_cmd[(w)1]" in
            cd|cp|git|rm|touch|mv|hg)
                vcs_info
                ;;
        esac
    }
    add-zsh-hook precmd _10k_conditional_vcs_info

    # Recent Directories (cdr)
    autoload -Uz chpwd_recent_dirs cdr
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*:*:cdr:*:*' menu selection
    zstyle ':chpwd:*' recent-dirs-default true


    # ── hooks implementation ───────────────────────────────────────────────

    function +vi-hg-bookmarks() {
        [[ -n "${hook_com[hg-active-bookmark]}" ]] && hook_com[hg-bookmark-string]="${(Mj:,:)@}" && ret=1
    }
    function +vi-hg-message() {
        [[ -n "${hook_com[misc]}" ]] && hook_com[branch]=''
        return 0
    }
    function +vi-git-untracked() {
        if check_git_untracked_status; then
            hook_com[unstaged]+="%F{blue}●%f"
        fi
    }


    # ── final assembly ─────────────────────────────────────────────────────

    # Base Right Prompt (VCS + Current Directory)
    RPROMPT_BASE="\${vcs_info_msg_0_}%F{blue}%~%f"

    # Main Prompt Construction
    function _10k_build_ps1() {
        local in_tmux=""
        [[ "$TERM" =~ "tmux" && -n "$TMUX" ]] && in_tmux='tmux'

        # Calculate Shell Nesting Level (SHLVL is simple, pstree is precise)
        local nesting_lvl=1
        if (( $+commands[pstree] )); then
            # Count how many 'zsh' processes are in the parent tree
            nesting_lvl="$(($(pstree -s $$ | grep -wo 'zsh' | wc -l)-1))"
        fi
        [[ $USER == "root" ]] && nesting_lvl="$(($nesting_lvl-1))"

        # Generate chevron suffix based on nesting level
        local suffix='%(!.%F{yellow}%n%f.)%(!.%F{yellow}.%F{red})'$(printf '\u276f%.0s' {1..$nesting_lvl})'%f'

        # Construct PS1
        # 1. SSH info (if applicable)
        # 2. Path
        # 3. Jobs/Exit Status
        # 4. Tmux indicator + Suffix
        export PS1="%F{green}${SSH_TTY:+%n@%m}%f%B${SSH_TTY:+:}%b%F{blue}%B%1~%b%F{yellow}%B%(1j.*.)%(?..!)%b%f %B%F{yellow}${in_tmux}%f${suffix}%b "

        # Fix TLE indentation glitch in TMUX
        [[ -n "$in_tmux" ]] && export ZLE_RPROMPT_INDENT=0
    }

    # Run the builder immediately
    _10k_build_ps1

    export RPROMPT=$RPROMPT_BASE

    # Spellcheck Prompt (for "Did you mean..?")
    export SPROMPT="zsh: correct %F{red}'%R'%f to %F{red}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]? "
}


# 4. Theme: 'Gh0st'
# ─────────────────────────────────────────────────────────────
## A sleek, modern prompt using manual Git status checking (no vcs_info).
## Features custom icons and a clean path view.

function theme_gh0st_setup() {

    # ── git status helper ──────────────────────────────────────────────────
    # Manually calculates git branch and dirty status.

    function _gh0st_git_status() {
        # Get the branch name (try symbolic-ref first, fall back to hash)
        local ref
        ref=$(command git symbolic-ref --quiet HEAD 2> /dev/null) || \
        ref=$(command git rev-parse --short HEAD 2> /dev/null) || return

        local branch_name=${ref#refs/heads/}

        # Truncate branch name if it's too long (over 20 chars)
        local display_branch="${branch_name:0:20}"
        if (( ${#branch_name} > ${#display_branch} )); then
            display_branch="${display_branch}..."
        fi

        # Dirty Check (Optimized)
        local status_symbol="${COLOR[GREEN]} ✓${COLOR[RESET]}"

        # --porcelain: machine readable output
        # -unormal: standard untracked file checking
        if [[ -n $(command git status --porcelain --ignore-submodules -unormal 2>/dev/null | head -n1) ]]; then
            status_symbol="${COLOR[RED]} ✗${COLOR[RESET]}"
        fi

        echo "  ${display_branch}${status_symbol}"
    }

    # ── directory helper ───────────────────────────────────────────────────
    # Note: Currently unused in PS1 but kept for future customization.

    function _gh0st_dir_icon() {
        if [[ "$PWD" == "$HOME" ]]; then
            echo "${COLOR[BOLD]}${COLOR[BLACK]}${COLOR[RESET]}"
        else
            echo "${COLOR[BOLD]}${COLOR[CYAN]}${COLOR[RESET]}"
        fi
    }

    # ── final assembly ─────────────────────────────────────────────────────

    local prompt_symbol=$(get_random_prompt_symbol)

    # Structure: <ICON>Home/Folder User(Blue) / Host(Yellow) [Dir](Grey) VCS Status_Symbol

    # 1. User & Host
    #    Note: We group the Bold+Color codes to reduce clutter.
    local p_user="%{${COLOR[BOLD]}${COLOR[BLUE]}%}%n"
    local p_sep="%{${COLOR[RED]}%}/"
    local p_host="%{${COLOR[YELLOW]}%}%m%{${COLOR[RESET]}%}"

    # 2. Directory
    #    Using GREY for the brackets and path.
    local p_dir="%{${COLOR[BOLD]}${COLOR[GREY]}%}[%~]%{${COLOR[RESET]}%}"

    # 3. VCS (Git)
    #    This variable is populated automatically by the vcs_info function.
    local p_vcs='${vcs_info_msg_0_}'

    # 4. Status Symbol (Conditional)
    #    Syntax: %(?.Success.Failure)
    #    - Success: Green $prompt_symbol icon
    #    - Failure: Red Double Arrows ()
    local p_status="%(?.%{${COLOR[BOLD]}${COLOR[GREEN]}%}${prompt_symbol}.%{${COLOR[RED]}%})%{${COLOR[RESET]}%}"


    # ── FINAL EXPORT ───────────────────────────────────────────────────────

    PS1="${_gh0st_dir_icon} ${p_user} ${p_sep} ${p_host} ${p_dir}${p_vcs} ${p_status} "
}


# 5. Initialization Logic
# ─────────────────────────────────────────────────────────────
## Selects the theme based on the environment variable.

case "$PROMPT_THEME" in
    "gh0st") theme_gh0st_setup ;;
    "z")     theme_z_setup     ;;
    "10k")   theme_10k_setup   ;;
    *)       return            ;;
esac
