# ------------------------[  ZSH PROMPT CONFIGURATION  ]------------------------ #
# This file defines the visual appearance of the command prompt.
# Themes: "z", "10k" (Custom), "gh0st"


# ........................[  1. Shared Utilities  ]........................ #

# Enable dynamic prompt expansion
setopt PROMPT_SUBST

# Helper: Get a random "Ignition" symbol
# Used by 'z_prompt' and 'gh0st_prompt'
get_ignition_symbol() {
    local symbols=(" " "" "-->" "➤" "󰮯 " "")
    echo "${symbols[1 + $RANDOM % ${#symbols[@]}]}"
}

# Helper: Git Untracked Check (Shared Logic)
# Returns true (0) if there are untracked files, false (1) otherwise.
has_untracked_files() {
    is_installed git || return 1
    [[ $(git rev-parse --is-inside-work-tree 2>/dev/null) == 'true' ]] && \
    git status --porcelain | grep '??' &>/dev/null
}


# ........................[  2. Theme: 'Z'  ]........................ #
# A minimal, Git-focused prompt.

z_prompt() {
    # --[ VCS Configuration ]--
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' check-for-changes true

    # Format: (branch) in magenta/blue
    zstyle ':vcs_info:git:*' formats " %{$fg[blue]%}(%{$fg[red]%}%m%u%c%{$fg[yellow]%}%{$fg[magenta]%} %b%{$fg[blue]%}) "

    # Hook: Check for untracked files
    zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

    +vi-git-untracked() {
        if has_untracked_files; then
            hook_com[staged]+='!' # Signify new files with a bang
        fi
    }

    # --[ Pre-cmd Hooks ]--
    precmd_vcs_info() { vcs_info; }
    add-zsh-hook precmd precmd_vcs_info

    # --[ Final Output ]--
    local ignition=$(get_ignition_symbol)
    PROMPT='%T %F{yellow}'"$ignition"'%f %F{blue}%1~%f '
    RPROMPT=\$vcs_info_msg_0_
}


# ........................[  3. Theme: '10k' (Custom)  ]........................ #
# A complex, feature-rich prompt handling window titles, timing, and Git/Hg.

10k_prompt() {
    # --[ P10K Toggles ]--
    function _toggle-prompt() {
        if is_installed p10k; then
            p10k display "*/$1"=hide,show
        fi
    }
    function _toggle-right-prompt() { _toggle-prompt right; }
    function _toggle-left-prompt()  { _toggle-prompt left; }

    # --[ VCS Configuration ]--
    zstyle ':vcs_info:*' enable git hg
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' use-simple true
    zstyle ':vcs_info:*' stagedstr "%F{green}●%f"
    zstyle ':vcs_info:*' unstagedstr "%F{red}●%f"

    # Git & Hg Formats
    zstyle ':vcs_info:git+set-message:*' hooks git-untracked
    zstyle ':vcs_info:git*:*' formats '[%b%m%c%u] '
    zstyle ':vcs_info:git*:*' actionformats '[%b|%a%m%c%u] '

    zstyle ':vcs_info:hg*:*' formats '[%m%b] '
    zstyle ':vcs_info:hg*:*' actionformats '[%b|%a%m] '
    zstyle ':vcs_info:hg*+gen-hg-bookmark-string:*' hooks hg-bookmarks
    zstyle ':vcs_info:hg*+set-message:*' hooks hg-message

    # --[ Window Titles ]--
    function -set-window-title() {
        emulate -L zsh
        print -Pn "\e]0;${1:gs/$/\\$}:q\a"
    }

    HISTCMD_LOCAL=0

    function -update-window-title() {
        emulate -L zsh
        local title_content

        # Determine content based on context (tmux vs normal)
        if [[ $1 == "precmd" ]]; then
            if [[ HISTCMD_LOCAL -eq 0 ]]; then
                title_content="$(basename "$PWD")"
            else
                local last_cmd=$(history | tail -1 | awk '{print $2}')
                title_content="$([ -z "$TMUX" ] && echo "$(basename "$PWD") > ")$last_cmd"
            fi
        else # preexec
            setopt EXTENDED_GLOB
            HISTCMD_LOCAL=$((++HISTCMD_LOCAL))
            local trimmed_cmd="${2[(wr)^(*=*|mosh|ssh|sudo)]}"
            title_content="$([ -z "$TMUX" ] && echo "$(basename "$PWD") > ")$trimmed_cmd"
        fi

        -set-window-title "$title_content"
    }

    add-zsh-hook precmd  -update-window-title
    add-zsh-hook preexec -update-window-title

    # --[ Execution Timer ]--
    typeset -F SECONDS
    function -record-start-time() { ZSH_START_TIME=${ZSH_START_TIME:-$SECONDS}; }
    add-zsh-hook preexec -record-start-time

    function -report-start-time() {
        if [ $ZSH_START_TIME ]; then
            local delta=$(($SECONDS - $ZSH_START_TIME))
            local elapsed=""

            # Calc time
            local d=$((delta / 86400))
            local h=$(((delta - d * 86400) / 3600))
            local m=$(((delta - d * 86400 - h * 3600) / 60))
            local s=$(($delta - d * 86400 - h * 3600 - m * 60))

            [ "$d" != "0" ] && elapsed="${d}d"
            [ "$h" != "0" ] && elapsed="${elapsed}${h}h"
            [ "$m" != "0" ] && elapsed="${elapsed}${m}m"

            if [ -z "$elapsed" ]; then
                s="$(print -f "%.2f" $s)s"
            else
                s="$((~~$s))s"
            fi
            elapsed="${elapsed}${s}"

            export RPROMPT="%F{cyan}%{$__Prompt[ITALIC_ON]%}${elapsed}%{$__Prompt[ITALIC_OFF]%}%f $RPROMPT_BASE"
            unset ZSH_START_TIME
        else
            export RPROMPT="$RPROMPT_BASE"
        fi
    }
    add-zsh-hook precmd -report-start-time

    # --[ Utilities ]--
    function -auto-ls-after-cd() {
        if [ "$ZSH_EVAL_CONTEXT" = "toplevel:shfunc" ]; then
            if is_installed eza; then eza --icons -a
            elif is_installed exa; then exa --icons -a
            else ls -a; fi
        fi
    }
    add-zsh-hook chpwd -auto-ls-after-cd

    # Update VCS info selectively (Performance)
    function -record-command() { __Prompt[LAST_COMMAND]="$2"; }
    add-zsh-hook preexec -record-command

    function -maybe-show-vcs-info() {
        local last_cmd="$__Prompt[LAST_COMMAND]"
        __Prompt[LAST_COMMAND]="<unset>"
        case "$last_cmd[(w)1]" in
            cd|cp|git|rm|touch|mv|hg) vcs_info ;;
        esac
    }
    add-zsh-hook precmd -maybe-show-vcs-info

    # Recent Dirs (cdr)
    autoload -Uz chpwd_recent_dirs cdr
    add-zsh-hook chpwd chpwd_recent_dirs
    zstyle ':completion:*:*:cdr:*:*' menu selection
    zstyle ':chpwd:*' recent-dirs-default true

    # --[ Hooks Implementation ]--
    function +vi-hg-bookmarks() {
        [[ -n "${hook_com[hg-active-bookmark]}" ]] && hook_com[hg-bookmark-string]="${(Mj:,:)@}" && ret=1
    }
    function +vi-hg-message() {
        [[ -n "${hook_com[misc]}" ]] && hook_com[branch]=''
        return 0
    }
    function +vi-git-untracked() {
        if has_untracked_files; then
            hook_com[unstaged]+="%F{blue}●%f"
        fi
    }

    # --[ Final Construction ]--
    RPROMPT_BASE="\${vcs_info_msg_0_}%F{blue}%~%f"

    # Dynamic Prompt Construction (Nested for variable safety)
    function () {
        local in_tmux=""
        [[ "$TERM" =~ "tmux" ]] && [[ -n "$TMUX" ]] && in_tmux='tmux'

        local lvl=1
        if is_installed pstree; then
            lvl="$(($(pstree -s $$ | grep -wo 'zsh' | wc -l)-1))"
        fi
        [[ $USER == "root" ]] && lvl="$(($lvl-1))"

        local suffix='%(!.%F{yellow}%n%f.)%(!.%F{yellow}.%F{red})'$(printf '\u276f%.0s' {1..$lvl})'%f'
        export PS1="%F{green}${SSH_TTY:+%n@%m}%f%B${SSH_TTY:+:}%b%F{blue}%B%1~%b%F{yellow}%B%(1j.*.)%(?..!)%b%f %B%F{yellow}${in_tmux}%f${suffix}%b "

        # Fix TLE indentation glitch in TMUX
        [[ -n "$in_tmux" ]] && export ZLE_RPROMPT_INDENT=0
    }

    export RPROMPT=$RPROMPT_BASE
    export SPROMPT="zsh: correct %F{red}'%R'%f to %F{red}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]? "
}


# ........................[  4. Theme: 'Gh0st'  ]........................ #
# A sleek, modern prompt with icons and path separators.

gh0st_prompt() {
    # Helper: Git Branch
    git_prompt() {
        is_installed git || return
        local branch="$(git symbolic-ref HEAD 2> /dev/null | cut -d'/' -f3-)"
        [ -z "$branch" ] && return

        # Truncate long branch names
        local branch_truncated="${branch:0:30}"
        (( ${#branch} > ${#branch_truncated} )) && branch="${branch_truncated}..."
        echo "  ${branch}"
    }

    # Helper: Directory Icon
    dir_icon() {
        if [[ "$PWD" == "$HOME" ]]; then
            echo "%B%F{black}%f%b"
        else
            echo "%B%F{cyan}%f%b"
        fi
    }

    local ignition=$(get_ignition_symbol)
    PS1='%B%F{blue}%n %B%F{red}/ %B%F{yellow}%m%f%b %B%F{grey}[%~]%f%b${vcs_info_msg_0_} %(?.%B%F{green}'"$ignition"'.%F{red})%f%b '
}


# ........................[  5. Prompt Initialization  ]........................ #

case "$PROMPT_THEME" in
    "gh0st") gh0st_prompt ;;
    "z")     z_prompt     ;;
    "10k")   10k_prompt   ;;
    *)       return       ;;
esac

# vim:filetype=zsh
