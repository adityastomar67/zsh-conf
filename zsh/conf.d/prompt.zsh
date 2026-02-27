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
#
# Usage Notes
#   Set `export PROMPT_THEME="gh0st"` in $ZDOTDIR/user.conf to switch themes.
# ------------------------------------------------------------------------------


# Shared Utilities
# ────────────────────────────────────────────────────────────────────────
## Helper functions used across multiple themes to avoid code duplication.

# Enable dynamic expansion within the prompt string.
# Without this, variables like ${vcs_info_msg_0_} won't update.
setopt PROMPT_SUBST

# Load zstat for microsecond file timestamp checking
zmodload zsh/stat

# Spellcheck prompt
SPROMPT="zsh: correct %F{red}'%R'%f to %F{red}'%r'%f? "


# ── Shared State Variables ─────────────────────────────────────────────
typeset -g PROMPT_SYMBOL="➜"
typeset -g GIT_BRANCH=""
typeset -g GIT_IS_REPO=0
typeset -g GIT_HAS_MODIFIED=0
typeset -g GIT_HAS_UNTRACKED=0
typeset -g GIT_HAS_STAGED=0
typeset -g _10K_START_TIME=""

# Async State
typeset -g _GIT_ASYNC_FD=0
typeset -g _GIT_ASYNC_PID=0
typeset -g _GIT_ASYNC_LOCK=0
typeset -gA _GIT_REPO_CACHE

# ── The Engine (Async Controller) ──────────────────────────────────────
# Replaces the synchronous logic with a non-blocking background fetch.
function _git_engine() {
    # 1. Callback Short-Circuit
    if (( _GIT_ASYNC_LOCK )) || (( _GIT_ASYNC_FD )); then
        return
    fi

    local current_pwd="$PWD"

    # 2. Cache Check (The Optimization)
    # If we know this PWD is NOT a repo, abort immediately (0ms latency).
    if [[ "${_GIT_REPO_CACHE[$current_pwd]}" == "0" ]]; then
        GIT_IS_REPO=0
        return
    fi

    # 3. Kill Stale Workers
    # If a job is running for a different directory or taking too long, kill it.
    if (( _GIT_ASYNC_PID > 0 )); then
        # Check if process exists
        if kill -0 "$_GIT_ASYNC_PID" 2>/dev/null; then
            kill -15 "$_GIT_ASYNC_PID" 2>/dev/null
        fi
    fi

    # 4. Spawn Background Worker using process substitution
    # This avoids TRAPUSR1 segfaults by using standard shell FDs integrated with ZLE.
    exec {fd}< <(
        # A. Worker Logic (Heavy Lift)
        local branch=""
        local modified=0
        local untracked=0
        local staged=0
        local is_repo=0
        local status_out

        # We try to run git status. If it fails, we are not in a repo.
        # --branch gives us branch info, --porcelain=v2 gives parseable status.
        if status_out=$(command git status --porcelain=v2 --branch 2>/dev/null); then
            is_repo=1

            if [[ -n "$status_out" ]]; then
                # 1. Parse Branch (Look for header: # branch.head master)
                # We use Zsh flag (f) to split by lines
                local -a lines
                lines=("${(@f)status_out}")

                local line
                for line in "${lines[@]}"; do
                    if [[ "$line" == "# branch.head "* ]]; then
                        branch="${line#\# branch.head }"
                        # Handle detached head which shows as "(detached)" or hash
                        if [[ "$branch" == "(detached)" ]]; then
                            branch=$(command git rev-parse --short HEAD 2>/dev/null)
                        fi
                        continue
                    fi

                    # 2. Parse Status
                    # Porcelain v2 Format:
                    # 1 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
                    # 2 <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>
                    # u <XY> <sub> <mH> <mI> <mW> <hH> <hI> <path>  (Unmerged)
                    # ? <path>                                      (Untracked)

                    if [[ "$line" == \?* ]]; then
                        untracked=1
                    else
                        # Capture the XY column (status codes)
                        # line format: 1 XY ... or 2 XY ...
                        local xy_code=""
                        if [[ "$line" == 1\ * || "$line" == 2\ * ]]; then
                             local parts=("${(@s/ /)line}")
                             xy_code="${parts[2]}"
                        fi

                        # Check Staged (X is not dot)
                        if [[ "$xy_code" == [MADRC]* ]]; then
                            staged=1
                        fi

                        # Check Modified (Y is not dot)
                        if [[ "$xy_code" == ?[MD]* ]]; then
                            modified=1
                        fi
                    fi
                done
            fi

            # Truncate branch name
            [[ ${#branch} -gt 20 ]] && branch="${branch[1,20]}..."
        fi

        # B. Write Result directly to stdout, which parent reads via FD
        # formatting: PWD|IS_REPO|BRANCH|MODIFIED|UNTRACKED|STAGED
        # We assume pipe | is safe enough for PWD usually
        print -r "$current_pwd|$is_repo|$branch|$modified|$untracked|$staged"
    )

    _GIT_ASYNC_PID=$!
    _GIT_ASYNC_FD=$fd

    # Register the callback with ZLE
    zle -F "$fd" _git_async_callback
}

# ── FD Handler ─────────────────────────────────────────────────────────
# Triggered when the background worker has finished data
function _git_async_callback() {
    local fd=$1
    local content

    # Keep a lock to prevent recursive triggering via updater hooks
    _GIT_ASYNC_LOCK=1

    # 1. Read Result
    if ! read -r content <&"$fd"; then
        # If read fails, cleanup safely
        zle -F "$fd"
        { exec {fd}<&- ; } 2>/dev/null
        _GIT_ASYNC_FD=0
        _GIT_ASYNC_LOCK=0
        return
    fi

    # Clean up FD immediately
    zle -F "$fd"
    { exec {fd}<&- ; } 2>/dev/null
    _GIT_ASYNC_FD=0
    _GIT_ASYNC_PID=0

    # Parse: PWD|IS_REPO|BRANCH|MODIFIED|UNTRACKED|STAGED
    local -a parts
    parts=("${(@s/|/)content}")

    if (( ${#parts} >= 6 )); then
        local worker_pwd="${parts[1]}"
        local is_repo="${parts[2]}"

        # Update Cache
        _GIT_REPO_CACHE["$worker_pwd"]="$is_repo"

        # Only update global display vars if we are still in the same dir
        if [[ "$worker_pwd" == "$PWD" ]]; then
            GIT_IS_REPO="$is_repo"
            GIT_BRANCH="${parts[3]}"
            GIT_HAS_MODIFIED="${parts[4]}"
            GIT_HAS_UNTRACKED="${parts[5]}"
            GIT_HAS_STAGED="${parts[6]}"

            # 2. Trigger Re-render and Redraw Prompt
            # Only update and redraw if ZLE is active
            if zle 2>/dev/null; then
                if [[ -n "$_CURRENT_PROMPT_HOOK" ]]; then
                    "$_CURRENT_PROMPT_HOOK" 2>/dev/null
                fi
                zle reset-prompt 2>/dev/null
            fi
        fi
    fi

    _GIT_ASYNC_LOCK=0
}

# ── Hook Manager ───────────────────────────────────────────────────────
typeset -g _CURRENT_PROMPT_HOOK=""

# Prevents duplicate hooks when switching themes
function _register_prompt_hook() {
    local hook_name="$1"

    # Remove all potential theme hooks first
    add-zsh-hook -d precmd _gh0st_updater
    add-zsh-hook -d precmd _orbit_updater
    add-zsh-hook -d precmd _z_updater
    add-zsh-hook -d precmd _10k_updater
    add-zsh-hook -d preexec _10k_record_start

    # Add the new one
    add-zsh-hook precmd "$hook_name"
    _CURRENT_PROMPT_HOOK="$hook_name"
}

# ── Random Symbol ──────────────────────────────────────────────────────
# Returns a random "ignition" symbol from a curated list.
function get_random_prompt_symbol() {
    local -a symbols=(
        # --- Standard ASCII (Safe) ---
        ">"   # Greater than
        ">>"  # Double greater than
        "-->" # Arrowhead
        "==>" # Heavy arrowhead
        "::"  # Colon
        "~>"  # Tilde
        "|>"  # Vertical bar

        # --- Geometric & Triangles (Clean) ---
        "▶"   # Black right-pointing triangle
        "▷"   # White right-pointing triangle
        "▸"   # Small black right-pointing triangle
        "►"   # Heavy black right-pointing pointer
        "◆"   # Diamond
        "●"   # Circle
        "■"   # Square

        # --- Standard Unicode Arrows (Bold) ---
        "➤"   # Heavy black arrowhead
        "➜"   # Heavy round-tipped arrow
        "➔"   # Heavy wide-headed arrow
        "➝"   # Triangle-headed arrow
        "➞"   # Heavy triangle-headed arrow
        "⇒"   # Double right arrow
        "»"   # Right angle quotes

        # --- Nerd Fonts / Powerline (Requires patched font) ---
        ""   # FontAwesome chevron
        ""  # Double chevron
        ""   # Octicons arrow right
        ""   # Small triangle right
        ""   # FontAwesome long arrow
        ""   # Circle outline
        ""   # Simple angle right
    )

    # Select random index based on array length
    # Use 'print --' to prevent symbols like '-->' being parsed as flags
    print -- "${symbols[1 + $RANDOM % ${#symbols[@]}]}"
}


# ── THEMES ─────────────────────────────────────────────────────────────

# Theme: 'Z'
# ───────────────────────────────────────────────────────────────────────
## A minimalist theme optimized for speed.
## Uses the shared _git_engine to reduce code duplication.
function theme_z() {

    # The View Logic (Updater)
    function _z_updater() {
        # Run the shared engine (Calculates raw state)
        _git_engine

        # Reset global output
        GIT_RPROMPT=""

        # Check if we are in a repo (Using shared engine flag)
        if (( GIT_IS_REPO )); then
            local unstaged=""
            local staged=""
            local untracked=""
            local is_dirty=0

            # ── Icon Setup (FIXED) ─────────────────────────────────────────
            # Set defaults FIRST, then override if 'icons' array exists.
            local branch_icon=""
            local github_icon=""

            if (( ${+icons} )); then
                branch_icon="${icons[VCS_BRANCH_ICON]:-$branch_icon}"
                github_icon="${icons[VCS_GIT_GITHUB_ICON]:-$github_icon}"
            fi

            # ── Logic ──────────────────────────────────────────────────────
            if (( GIT_HAS_MODIFIED )); then
                unstaged="%F{red}●"
                is_dirty=1
            fi

            if (( GIT_HAS_STAGED )); then
                staged="%F{green}●"
                is_dirty=1
            fi

            if (( GIT_HAS_UNTRACKED )); then
                untracked="%F{cyan}●"
                is_dirty=1
            fi

            # Branch Color Logic
            local branch_color="%F{magenta}"
            [[ $is_dirty -eq 1 ]] && branch_color="%F{yellow}"

            # ── Assembly ───────────────────────────────────────────────────
            GIT_RPROMPT=" %F{blue}(${branch_color}${branch_icon} ${GIT_BRANCH}%F{blue})%F{reset} ${unstaged}${staged}${untracked}%F{blue} ${github_icon}%f"
        fi

        # ── FORCE UPDATE RPROMPT (CRITICAL) ────────────────────────────────
        # Assigning it here ensures it updates every single time.
        RPROMPT="${GIT_RPROMPT}"
    }

    # 3. Register Hook
    #    Uses the shared helper to ensure clean switching
    _register_prompt_hook _z_updater

    # 4. Final Left Prompt Assembly
    local prompt_symbol="➜"
    (( $+functions[get_random_prompt_symbol] )) && prompt_symbol=$(get_random_prompt_symbol)

    PROMPT="%T %F{yellow}${prompt_symbol}%f %F{blue}%1~%f "
}


# Theme: 'Gh0st'
# ───────────────────────────────────────────────────────────────────────
## A sleek, modern prompt using purely native Zsh features.
## No dependencies. Ultra-fast Git plumbing. Self-contained.
function theme_gh0st() {
    typeset -g _GH0ST_GIT_MSG=""

    function _gh0st_updater() {
        # 1. Run Engine
        _git_engine

        # 2. Build Output based on Engine State
        _GH0ST_GIT_MSG=""

        if (( GIT_IS_REPO )); then
            local icon="%F{green}"

            # Logic: If Modified OR Untracked -> Red Dot
            if (( GIT_HAS_MODIFIED || GIT_HAS_UNTRACKED )); then
                icon="%F{red}"
            fi

            _GH0ST_GIT_MSG="  %F{magenta}${GIT_BRANCH} ${icon}%{${COLOR[RESET]}%}"
        fi
    }

    # Use the shared hook manager
    _register_prompt_hook _gh0st_updater

    # ── Visual Assets ──────────────────────────────────────────────────
    local icon_dir="%(~.%B%F{black}.%B%F{cyan})%f%b"
    local p_user="%B%F{blue}%n"
    local p_sep="%F{red}/"
    local p_host="%F{yellow}%m"
    local p_path=$'%{\e[3m%}%F{242}[%~]%f%{\e[23m%}'

    PROMPT_SYMBOL=$(get_random_prompt_symbol)

    local p_status="%(?.%F{green}.%F{red})${PROMPT_SYMBOL}%f"

    PS1="${icon_dir} ${p_user} ${p_sep} ${p_host} ${p_path}\${_GH0ST_GIT_MSG} ${p_status} "
}


# Theme: 'Orbit'
# ───────────────────────────────────────────────────────────────────────
## A two-line prompt with connecting lines, resembling a spaceship HUD.
function theme_orbit() {
    typeset -g _ORBIT_GIT_MSG=""

    function _orbit_updater() {
        _git_engine

        _ORBIT_GIT_MSG=""

        if (( GIT_IS_REPO )); then
            local indicators=""

            # Detailed Logic: Check specific flags from engine
            (( GIT_HAS_MODIFIED ))  && indicators+="%F{red}●"
            (( GIT_HAS_UNTRACKED )) && indicators+="%F{cyan}●"
            (( GIT_HAS_STAGED ))    && indicators+="%F{green}●"

            _ORBIT_GIT_MSG=" on %F{magenta} ${GIT_BRANCH}%f ${indicators}"
        fi

        # Enforce RPROMPT inside the loop to prevent overwrites
        RPROMPT="%F{238}[%D{%T}]%f"
    }

    _register_prompt_hook _orbit_updater

    # ── Construction ───────────────────────────────────────────────────
    local c_top="%F{blue}╭─%f"
    local c_mid="%F{blue}─%f"
    local c_bot="%F{blue}╰─%f"
    local s_os="%F{white} %f"
    local s_dir="%B%F{blue}%~%f%b"
    local s_arrow="%B%(?.%F{green}›%f.%F{red}›%f)%b"

    PS1=$'\n'"${c_top}${c_mid} ${s_os}${s_dir}\${_ORBIT_GIT_MSG}"$'\n'"${c_bot} ${s_arrow} "
}


# Theme: '10k'
# ───────────────────────────────────────────────────────────────────────
## A prompt with a timer, git status, and window title.
## No dependencies. Ultra-fast Git plumbing. Self-contained.
function theme_10k() {
    # 1. Execution Timer Hook
    function _10k_record_start() {
        _10K_START_TIME=$SECONDS
    }

    # 2. Main Updater (Git + Timer + Title + RPROMPT)
    function _10k_updater() {
        # ── A. Run Git Engine ──────────────────────────────────────────
        _git_engine

        local git_part=""
        if (( GIT_IS_REPO )); then
            local indicators=""
            (( GIT_HAS_MODIFIED ))  && indicators+="%F{red}●"
            (( GIT_HAS_UNTRACKED )) && indicators+="%F{cyan}●"
            (( GIT_HAS_STAGED ))    && indicators+="%F{green}●"

            # Format: [  main ●? ]
            git_part="[ %F{magenta} ${GIT_BRANCH}%f ${indicators}%f ] "
        fi

        # ── B. Execution Time ──────────────────────────────────────────
        local exec_part=""
        if [[ -n "$_10K_START_TIME" ]]; then
            local delta=$(($SECONDS - _10K_START_TIME))
            if (( delta > 2 )); then
                exec_part="%F{cyan}${delta}s%f "
            fi
            unset _10K_START_TIME
        fi

        # ── D. FORCE SET RIGHT PROMPT ──────────────────────────────────
        # We construct RPROMPT right here to ensure it shows up.
        # Structure: [ExecTime] [GitStatus] Path
        RPROMPT="${exec_part}${git_part}%F{blue}%~%f"
    }

    # 3. Auto-LS on Directory Change
    function _10k_chpwd() {
        if (( $+commands[eza] )); then eza --icons -a
        else ls -a; fi
    }

    # 4. Hook Registration
    _register_prompt_hook _10k_updater
    add-zsh-hook preexec _10k_record_start
    add-zsh-hook chpwd _10k_chpwd

    # ── Visual Assembly (Left Prompt) ──────────────────────────────────

    # Check TMUX
    local in_tmux=""; [[ -n "$TMUX" ]] && in_tmux="tmux "

    # Suffix: Yellow/Green Arrow based on previous exit code
    # %(!...): Check if Root
    PROMPT_SYMBOL=$(get_random_prompt_symbol)
    local suffix="%(!.%F{yellow}%n%f .)%(!.%F{yellow}${PROMPT_SYMBOL}%f.%F{green}${PROMPT_SYMBOL}%f)%f"

    # Left Prompt Construction:
    # 1. SSH User/Host (Green)
    # 2. Directory Name Only (Blue, Bold) -> %1~
    # 3. Jobs indicator (Yellow) -> %1j
    # 4. Error code (Yellow !) -> %?
    PS1="%F{green}${SSH_TTY:+%n@%m}%f%F{yellow}%B%(1j.*.)%(?..!)%b%f %B%F{yellow}${in_tmux}%f${suffix} "
}


# ── Initialization Logic ──────────────────────────────────────────────
## Selects the theme based on the environment variable.

case "$PROMPT_THEME" in
    "gh0st")  theme_gh0st  ;;
    "z")      theme_z      ;;
    "10k")    theme_10k    ;;
    "orbit")  theme_orbit  ;;
    *)        return       ;;
esac
