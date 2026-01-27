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

#

# 1. Shared Utilities
# ─────────────────────────────────────────────────────────────
## Helper functions used across multiple themes to avoid code duplication.

# Enable dynamic expansion within the prompt string.
# Without this, variables like ${vcs_info_msg_0_} won't update.
setopt PROMPT_SUBST
autoload -Uz vcs_info

# Load zstat for microsecond file timestamp checking
zmodload zsh/stat

# Global variables to persist cache between prompt draws
typeset -g _GH0ST_CACHE_KEY=""     # Stores "PWD + Last Modified Time"
typeset -g _GH0ST_CACHE_VAL=""     # Stores the visual string
typeset -g _GH0ST_GIT_INDEX=""     # Stores location of .git/index

# Function: get_random_prompt_symbol
# Description:
#   Returns a random "ignition" symbol from a curated list.
#   Adds visual variety to every new line.
function get_random_prompt_symbol() {
    local -a symbols=(
        # --- Standard ASCII (Safe) ---
        ">"
        ">>"
        "-->"
        "==>"
        "::"
        "~>"
        "|>"

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
        ""   # Powerline hard right
        ""   # Powerline soft right
        "❯"   # Heavy angle quote (Classic Pure/Spaceship theme)
        "❱"   # Heavy double angle quote
        ""   # FontAwesome chevron
        ""  # Double chevron
        ""   # Octicons arrow right
        ""   # Small triangle right
        ""   # FontAwesome long arrow
        ""   # Circle outline
        ""   # Simple angle right
    )

    # Select random index based on array length
    print "${symbols[1 + $RANDOM % ${#symbols[@]}]}"
}

# Function: check_git_untracked_status
# Description:
#   Checks if the current Git repository has untracked files (??).
#   Returns 0 (true) if untracked files exist, 1 (false) otherwise.
function check_git_untracked_status() {
    # Guard: Git must be installed
    if (( ! $+commands[git] )); then
        return 1
    fi

    # Check if inside work tree to avoid errors
    if [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]]; then
        # Grep for '??' in porcelain output (fastest check)
        git status --porcelain | grep '??' &>/dev/null
    else
        return 1
    fi
}


# 2. Theme: 'Neon'
# ─────────────────────────────────────────────────────────────
## A high-contrast, cyberpunk-inspired theme.

function theme_neon_setup() {
    # ── vcs_info setup ─────────────────────────────────────────────────────
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' check-for-changes true
    # %b: Branch, %u: Unstaged, %c: Staged
    zstyle ':vcs_info:git:*' formats " %F{201} %b%f %F{red}%u%c%f"
    zstyle ':vcs_info:git:*' actionformats " %F{201} %b|%a%f %F{red}%u%c%f"

    # Hook to auto-update git info
    add-zsh-hook precmd vcs_info

    # ── construction ───────────────────────────────────────────────────────

    # 1. Directory: Cyan text on Black background
    #    %1~ shows only the current folder name, %~ shows full path.
    local p_dir="%K{black}%F{51}  %1~ %f%k"

    # 2. Arrow separator
    local p_arrow="%F{51}%f"

    # 3. User info: Pink
    local p_user="%F{213}%n%f"

    # 4. Prompt Symbol: Neon Green lightning
    local p_symbol="%B%F{154}⚡%f%b"

    # ── assembly ───────────────────────────────────────────────────────────

    # Left: [ DIR > ] User [Git] Symbol
    PS1="${p_dir}${p_arrow} ${p_user}\${vcs_info_msg_0_} ${p_symbol} "

    # Right: Time in dim purple
    RPROMPT="%F{240} %*%f"
}


# 3. Theme: 'Bubble'
# ─────────────────────────────────────────────────────────────
## A rounded, "pill" style theme using Zsh's 256-color support.

function theme_bubble_setup() {
    # ── vcs_info setup ─────────────────────────────────────────────────────
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' check-for-changes true
    # Formats: Branch name in bold
    zstyle ':vcs_info:git:*' formats "%B%F{black} %b%f%b"
    # Action formats (rebase/merge)
    zstyle ':vcs_info:git:*' actionformats "%B%F{black} %b|%a%f%b"

    add-zsh-hook precmd vcs_info

    # ── construction ───────────────────────────────────────────────────────

    # Module 1: Directory (Blue Pill)
    #  (Blue FG) + (Blue BG / White Text) +  (Blue FG)
    local m_dir="%F{75}%K{75}%F{0} %~ %f%k%F{75}%f"

    # Module 2: Git (Green Pill) - Only shows if git exists
    # We use a trick: Inject the Pill coloring logic INTO vcs_info.
    # If not in a git repo, vcs_info returns empty, so no empty green pill appears.
    zstyle ':vcs_info:git:*' formats "%F{78}%K{78}%F{0} %b%f%k%F{78}%f"

    # Module 3: Prompt Character (Conditional Arrow)
    # %(?.Success.Failure)
    local m_char="%(?.%F{green}❯%f.%F{red}❯%f)"

    # ── assembly ───────────────────────────────────────────────────────────

    PS1="${m_dir} \${vcs_info_msg_0_} ${m_char} "
    RPROMPT="%F{240}%n@%m%f"
}


# 4. Theme: 'Orbit'
# ─────────────────────────────────────────────────────────────
## A two-line prompt with connecting lines, resembling a spaceship HUD.

function theme_orbit_setup() {
    # ── vcs_info setup ─────────────────────────────────────────────────────
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:git:*' formats " on %F{magenta} %b%f %c%u"

    add-zsh-hook precmd vcs_info

    # ── construction ───────────────────────────────────────────────────────

    # Top Left Corner
    local c_top="%F{blue}╭─%f"
    # Bottom Left Corner
    local c_bot="%F{blue}╰─%f"
    # Connecting Dash
    local c_dash="%F{blue}─%f"

    # Info Segments
    local s_os="%F{white} %f"
    local s_dir="%B%F{blue}%~%f%b"
    local s_arrow="%B%(?.%F{green}›%f.%F{red}›%f)%b"

    # ── assembly ───────────────────────────────────────────────────────────

    # Line 1: ╭─   ~/path/to/dir on  main
    # Line 2: ╰─ ›
    PS1=$'\n'"${c_top}${c_dash} ${s_os}${s_dir}\${vcs_info_msg_0_}"$'\n'"${c_bot} ${s_arrow} "

    # RPROMPT: Execution time or timestamp
    RPROMPT="%F{238}[%T]%f"
}


# 5. Theme: 'Z'
# ─────────────────────────────────────────────────────────────
## A minimalist theme heavily reliant on Zsh's built-in `vcs_info` module.
## Focuses on speed and low visual noise.

function theme_z_setup() {

    # ── 1. Fast Git Status Function ────────────────────────────────────────
    # Replaces vcs_info. Runs ONE git call to get Branch + Status + Untracked.
    function _fast_git_status() {
        # Fast Guard: Check if we are in a git repo
        # 'command git' avoids aliases. '2>/dev/null' silences errors.
        local ref
        ref=$(command git symbolic-ref --quiet HEAD 2> /dev/null) || \
        ref=$(command git rev-parse --short HEAD 2> /dev/null) || return

        # Get the branch name (strip refs/heads/)
        local branch="${ref#refs/heads/}"

        # Performance: Truncate branch name if too long (>20 chars)
        if (( ${#branch} > 20 )); then
            branch="${branch:0:20}..."
        fi

        # ── Status Indicators ──────────────────────────────────────────────
        local misc=""      # %m
        local unstaged=""  # %u
        local staged=""    # %c

        # Run git status ONCE.
        # --porcelain: stable parsing format
        # -b: include branch info
        # -unormal: standard untracked file checking
        local git_output
        git_output=$(command git status --porcelain -b -unormal 2>/dev/null)

        # Parse the output using Zsh string manipulation (Fast)
        if [[ $git_output == *'?'* ]]; then
            staged+='!' # Matching your hook for untracked files
        fi

        # Check for modified (unstaged) files (Lines starting with space-M, space-D, etc)
        if [[ $git_output =~ $'(^|\n) .+' ]]; then
            unstaged="●" # Or your preferred symbol for %u
        fi

        # Check for staged files (Lines starting with M, A, D, etc)
        if [[ $git_output =~ $'(^|\n)[MADRC] .+' ]]; then
            staged+="+" # Or your preferred symbol for %c
        fi

        # ── Construct the Visual String ────────────────────────────────────
        # Format matches your old vcs_info string:
        # Blue ( Red Misc Unstaged Staged Yellow Icon Magenta Branch Blue ) Icon

        local branch_icon="${icons[VCS_BRANCH_ICON]:-}"
        local github_icon="${icons[VCS_GIT_GITHUB_ICON]:-}"

        # We construct the variable GIT_RPROMPT directly
        GIT_RPROMPT=" %{${COLOR[BLUE]}%}(%{${COLOR[RED]}%}${misc}${unstaged}${staged}%{${COLOR[YELLOW]}%}${branch_icon}%{${COLOR[MAGENTA]}%} ${branch}%{${COLOR[BLUE]}%}) ${github_icon}"
    }

    # ── 2. Prompt Hook ─────────────────────────────────────────────────────
    # Runs before every prompt draw
    function _update_prompt_data() {
        # Reset git info
        GIT_RPROMPT=""
        # Run the fast status check
        _fast_git_status
    }

    add-zsh-hook precmd _update_prompt_data

    # ── 3. Final Assembly ──────────────────────────────────────────────────

    # Move this TO precmd if you want the symbol to change every time.
    # Kept here for static loading speed as per your snippet.
    local prompt_symbol=$(get_random_prompt_symbol)

    # Left Prompt
    PROMPT="%T %{${COLOR[YELLOW]}%}${prompt_symbol}%{${COLOR[RESET]}%} %{${COLOR[BLUE]}%}%1~%{${COLOR[RESET]}%} "

    # Right Prompt: Uses the raw variable we built
    RPROMPT='${GIT_RPROMPT}'
}


# 6. Theme: '10k' (Custom Power User)
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
                title_content="$([ -z "$TMUX" ] && print "$(basename "$PWD") > ")$last_cmd"
            fi
        else
            # Pre-exec (Running)
            setopt EXTENDED_GLOB
            HISTCMD_LOCAL=$((++HISTCMD_LOCAL))

            # Remove command arguments/ssh prefixes for cleaner title
            local trimmed_cmd="${2[(wr)^(*=*|mosh|ssh|sudo)]}"
            title_content="$([ -z "$TMUX" ] && print "$(basename "$PWD") > ")$trimmed_cmd"
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
        local suffix='%(!.%F{yellow}%n%f.)%(!.%F{yellow}.%F{red})'$(print -f '\u276f%.0s' {1..$nesting_lvl})'%f'

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


# 7. Theme: 'Gh0st'
# ─────────────────────────────────────────────────────────────
## A sleek, modern prompt using manual Git status checking (no vcs_info).
## Features custom icons and a clean path view.

function theme_gh0st_setup() {
    # ── Git Status (Cached & Optimized) ───────────────────────────────────
    function _gh0st_git_status() {

        # 1. ⚡ FAST PATH: Cache Hit Check
        # If we are in the same directory context as the last run...
        if [[ -n "$_GH0ST_GIT_INDEX" && "${_GH0ST_CACHE_KEY%%::*}" == "$PWD" ]]; then
            local current_mtime
            # Check modification time of .git/index directly (No git command)
            current_mtime=$(zstat +mtime "$_GH0ST_GIT_INDEX" 2>/dev/null)

            # If timestamps match, reuse the string immediately
            if [[ "${_GH0ST_CACHE_KEY##*::}" == "$current_mtime" ]]; then
                GH0ST_GIT_INFO="$_GH0ST_CACHE_VAL"
                return
            fi
        fi

        # 2. 🐢 SLOW PATH: Cache Miss (Recalculate)

        # Fast guard: Are we in a repo?
        if ! command git rev-parse --is-inside-work-tree &>/dev/null; then
            GH0ST_GIT_INFO=""
            _GH0ST_GIT_INDEX="" # Reset index so we don't false-hit later
            return
        fi

        # Find .git/index path for future caching
        local git_dir
        git_dir=$(command git rev-parse --git-dir 2>/dev/null)
        local index_path="${git_dir}/index"

        # Get current timestamp for the new cache key
        local index_time=""
        if [[ -f "$index_path" ]]; then
            index_time=$(zstat +mtime "$index_path" 2>/dev/null)
        fi

        # Get Branch
        local ref
        ref=$(command git symbolic-ref --short HEAD 2>/dev/null) || \
        ref=$(command git rev-parse --short HEAD 2>/dev/null) || return

        # Truncate Branch
        local display_branch="${ref[1,20]}"
        [[ ${#ref} -gt 20 ]] && display_branch="${display_branch}..."

        # Dirty Check
        # We use --no-optional-locks to prevent hanging on background gc
        local status_symbol="%{${COLOR[GREEN]}%}✓"

        # Check if dirty or untracked
        # We assume if 'git status' returns ANY output, it's dirty.
        # This is faster than running diff-index AND ls-files separately.
        if [[ -n $(command git --no-optional-locks status --porcelain -b -unormal 2>/dev/null | head -n 1) ]]; then
             # Check specifically for changes (not just branch info)
             if [[ -n $(command git --no-optional-locks status --porcelain -unormal 2>/dev/null) ]]; then
                status_symbol="%{${COLOR[RED]}%}✗"
             fi
        fi

        # 3. Save to Cache
        _GH0ST_CACHE_VAL="  %{${COLOR[MAGENTA]}%}${display_branch} ${status_symbol}%{${COLOR[RESET]}%}"
        _GH0ST_CACHE_KEY="${PWD}::${index_time}"
        _GH0ST_GIT_INDEX="$index_path"

        GH0ST_GIT_INFO="$_GH0ST_CACHE_VAL"
    }

    # ── Directory Icon ────────────────────────────────────────────────────
    # No changes needed, this ternary logic is already optimal
    local dir_icon="%(~.%{${COLOR[BOLD]}${COLOR[BLACK]}%}.%{${COLOR[BOLD]}${COLOR[CYAN]}%})%{${COLOR[RESET]}%}"

    function _gh0st_precmd() {
        _gh0st_git_status
    }
    add-zsh-hook precmd _gh0st_precmd

    # ── Prompt Assembly ───────────────────────────────────────────────────
    local p_user="%{${COLOR[BOLD]}${COLOR[BLUE]}%}%n"
    local p_sep="%{${COLOR[RED]}%}/"
    local p_host="%{${COLOR[YELLOW]}%}%m"
    local p_dir="%{${COLOR[ITALIC]}${COLOR[GREY]}%}[%~]%{${COLOR[RESET]}%}"
    local prompt_symbol=$(get_random_prompt_symbol)

    # Conditional coloring for prompt char (Green if 0, Red if error)
    local p_status="%(?.%{${COLOR[GREEN]}%}.%{${COLOR[RED]}%})${prompt_symbol}%{${COLOR[RESET]}%}"

    setopt PROMPT_SUBST
    PS1="${dir_icon} ${p_user} ${p_sep} ${p_host} ${p_dir}\${GH0ST_GIT_INFO} ${p_status} "
}


# 8. Initialization Logic
# ─────────────────────────────────────────────────────────────
## Selects the theme based on the environment variable.

case "$PROMPT_THEME" in
    "gh0st")  theme_gh0st_setup  ;;
    "z")      theme_z_setup      ;;
    "10k")    theme_10k_setup    ;;
    "neon")   theme_neon_setup   ;;
    "bubble") theme_bubble_setup ;;
    "orbit")  theme_orbit_setup  ;;
    *)        return             ;;
esac
