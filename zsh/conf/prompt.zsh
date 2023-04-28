# ▀█ ▄▄ █▀█ █▀█ █▀█ █▀▄▀█ █▀█ ▀█▀
# █▄    █▀▀ █▀▄ █▄█ █ ▀ █ █▀▀  █

##--> Prompt Definitions <--##
z_prompt() {
  # Styles for Prompt
  declare -a PROMPTS
  PROMPTS=(
      " "
      ""
      ">>>"
      "-->"
      "➤"
      "󰮯 "
    )

  # Autoload vcs and colors
  autoload -Uz vcs_info
  autoload -U colors && colors

  # Enable only git
  zstyle ':vcs_info:*' enable git

  # Setup a hook that runs before every prompt.
  precmd_vcs_info() { 
    vcs_info 
  }
  precmd_functions+=( precmd_vcs_info )
  setopt prompt_subst

  # Add a function to check for untracked files in the directory. from https://github.com/zsh-users/zsh/blob/master/Misc/vcs_info-examples
  zstyle ':vcs_info:git*+set-message:*' hooks git-untracked

  +vi-git-untracked(){
      if [[ $(git rev-parse --is-inside-work-tree 2> /dev/null) == 'true' ]] && \
          git status --porcelain | grep '??' &> /dev/null ; then
          # This will show the marker if there are any untracked files in repo. If instead you want to show the marker only if there are untracked files in $PWD, use:
          #[[ -n $(git ls-files --others --exclude-standard) ]] ; then
          hook_com[staged]+='!' # signify new files with a bang
      fi
  }

  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:git:*' formats " %{$fg[blue]%}(%{$fg[red]%}%m%u%c%{$fg[yellow]%}%{$fg[magenta]%} %b%{$fg[blue]%}) "
  # zstyle ':vcs_info:git:*' formats " %r/%S %b %m%u%c "

  ##--> Actual Prompt Definition <--##
  ignition=${PROMPTS[1 + $RANDOM%6]}
  PROMPT='%T %F{yellow}$ignition%f %F{blue}%1~%f '
  RPROMPT=\$vcs_info_msg_0_
}

10k_prompt() {
    ##--> Toggle prompt <--##
    function _toggle-prompt() {
        case "$1" in
            right) p10k display '*/right'=hide,show ;;
            left) p10k display '*/left'=hide,show ;;
        esac
    }

    function _toggle-right-prompt() {
        _toggle-prompt right
    }

    function _toggle-left-prompt() {
        _toggle-prompt left
    }

    autoload -U add-zsh-hook
    autoload -U colors
    colors

    # http://zsh.sourceforge.net/Doc/Release/User-Contributions.html
    autoload -Uz vcs_info
    zstyle ':vcs_info:*' enable git hg
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' use-simple true
    zstyle ':vcs_info:git+set-message:*' hooks git-untracked
    zstyle ':vcs_info:*' stagedstr "%F{green}●%f"            # default 'S'
    zstyle ':vcs_info:*' unstagedstr "%F{red}●%f"            # default 'U'
    zstyle ':vcs_info:git*:*' formats '[%b%m%c%u] '          # default ' (%s)-[%b]%c%u-'
    zstyle ':vcs_info:git*:*' actionformats '[%b|%a%m%c%u] ' # default ' (%s)-[%b|%a]%c%u-'
    zstyle ':vcs_info:hg*:*' formats '[%m%b] '
    zstyle ':vcs_info:hg*:*' actionformats '[%b|%a%m] '
    zstyle ':vcs_info:hg*:*' branchformat '%b'
    zstyle ':vcs_info:hg*:*' get-bookmarks true
    zstyle ':vcs_info:hg*:*' get-revision true
    zstyle ':vcs_info:hg*:*' get-mq false
    zstyle ':vcs_info:hg*+gen-hg-bookmark-string:*' hooks hg-bookmarks
    zstyle ':vcs_info:hg*+set-message:*' hooks hg-message

    function -set-tab-and-window-title() {
      emulate -L zsh
      local CMD="${1:gs/$/\\$}"
      print -Pn "\e]0;$CMD:q\a"
    }

    # $HISTCMD (the current history event number) is shared across all shells
    # (due to SHARE_HISTORY). Maintain this local variable to count the number of
    # commands run in this specific shell.
    HISTCMD_LOCAL=0

    # Executed before displaying prompt.
    function -update-window-title-precmd() {
      emulate -L zsh
      if [[ HISTCMD_LOCAL -eq 0 ]]; then
        # About to display prompt for the first time; nothing interesting to show in
        # the history. Show $PWD.
        -set-tab-and-window-title "$(basename $PWD)"
      else
        local LAST=$(history | tail -1 | awk '{print $2}')
        if [ -n "$TMUX" ]; then
          # Inside tmux, just show the last command: tmux will prefix it with the
          # session name (for context).
          -set-tab-and-window-title "$LAST"
        else
          # Outside tmux, show $PWD (for context) followed by the last command.
          -set-tab-and-window-title "$(basename $PWD) > $LAST"
        fi
      fi
    }
    add-zsh-hook precmd -update-window-title-precmd

    # Executed before executing a command: $2 is one-line (truncated) version of
    # the command.
    function -update-window-title-preexec() {
      emulate -L zsh
      setopt EXTENDED_GLOB
      HISTCMD_LOCAL=$((++HISTCMD_LOCAL))

      # Skip ENV=settings, sudo, ssh; show first distinctive word of command;
      # mostly stolen from:
      #   https://github.com/robbyrussell/oh-my-zsh/blob/master/lib/termsupport.zsh
      local TRIMMED="${2[(wr)^(*=*|mosh|ssh|sudo)]}"
      if [ -n "$TMUX" ]; then
        # Inside tmux, show the running command: tmux will prefix it with the
        # session name (for context).
        -set-tab-and-window-title "$TRIMMED"
      else
        # Outside tmux, show $PWD (for context) followed by the running command.
        -set-tab-and-window-title "$(basename $PWD) > $TRIMMED"
      fi
    }
    add-zsh-hook preexec -update-window-title-preexec

    typeset -F SECONDS
    function -record-start-time() {
      emulate -L zsh
      ZSH_START_TIME=${ZSH_START_TIME:-$SECONDS}
    }
    add-zsh-hook preexec -record-start-time

    function -report-start-time() {
      emulate -L zsh
      if [ $ZSH_START_TIME ]; then
        local DELTA=$(($SECONDS - $ZSH_START_TIME))
        local DAYS=$((~~($DELTA / 86400)))
        local HOURS=$((~~(($DELTA - $DAYS * 86400) / 3600)))
        local MINUTES=$((~~(($DELTA - $DAYS * 86400 - $HOURS * 3600) / 60)))
        local SECS=$(($DELTA - $DAYS * 86400 - $HOURS * 3600 - $MINUTES * 60))
        local ELAPSED=''
        test "$DAYS" != '0' && ELAPSED="${DAYS}d"
        test "$HOURS" != '0' && ELAPSED="${ELAPSED}${HOURS}h"
        test "$MINUTES" != '0' && ELAPSED="${ELAPSED}${MINUTES}m"
        if [ "$ELAPSED" = '' ]; then
          SECS="$(print -f "%.2f" $SECS)s"
        elif [ "$DAYS" != '0' ]; then
          SECS=''
        else
          SECS="$((~~$SECS))s"
        fi
        ELAPSED="${ELAPSED}${SECS}"
        export RPROMPT="%F{cyan}%{$__Prompt[ITALIC_ON]%}${ELAPSED}%{$__Prompt[ITALIC_OFF]%}%f $RPROMPT_BASE"
        unset ZSH_START_TIME
      else
        export RPROMPT="$RPROMPT_BASE"
      fi
    }
    add-zsh-hook precmd -report-start-time

    function -auto-ls-after-cd() {
      emulate -L zsh
      # Only in response to a user-initiated `cd`, not indirectly (eg. via another
      # function).
      if [ "$ZSH_EVAL_CONTEXT" = "toplevel:shfunc" ]; then
        if command -v exa &> /dev/null; then
          exa --icons -a
        else
          ls -a
        fi
      fi
    }
    add-zsh-hook chpwd -auto-ls-after-cd

    # Remember each command we run.
    function -record-command() {
      __Prompt[LAST_COMMAND]="$2"
    }
    add-zsh-hook preexec -record-command

    # Update vcs_info (slow) after any command that probably changed it.
    function -maybe-show-vcs-info() {
      local LAST="$__Prompt[LAST_COMMAND]"

      # In case user just hit enter, overwrite LAST_COMMAND, because preexec
      # won't run and it will otherwise linger.
      __Prompt[LAST_COMMAND]="<unset>"

      # Check first word; via:
      # http://tim.vanwerkhoven.org/post/2012/10/28/ZSH/Bash-string-manipulation
      case "$LAST[(w)1]" in
        cd|cp|git|rm|touch|mv)
          vcs_info
          ;;
        *)
          ;;
      esac
    }
    add-zsh-hook precmd -maybe-show-vcs-info

    # adds `cdr` command for navigating to recent directories
    autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
    add-zsh-hook chpwd chpwd_recent_dirs

    # enable menu-style completion for cdr
    zstyle ':completion:*:*:cdr:*:*' menu selection

    # fall through to cd if cdr is passed a non-recent dir as an argument
    zstyle ':chpwd:*' recent-dirs-default true

    ############
    #  Prompt  #
    ############

    function +vi-hg-bookmarks() {
      emulate -L zsh
      if [[ -n "${hook_com[hg-active-bookmark]}" ]]; then
        hook_com[hg-bookmark-string]="${(Mj:,:)@}"
        ret=1
      fi
    }

    function +vi-hg-message() {
      emulate -L zsh

      # Suppress hg branch display if we can display a bookmark instead.
      if [[ -n "${hook_com[misc]}" ]]; then
        hook_com[branch]=''
      fi
      return 0
    }

    function +vi-git-untracked() {
      emulate -L zsh
      if [[ -n $(git ls-files --exclude-standard --others 2> /dev/null) ]]; then
        hook_com[unstaged]+="%F{blue}●%f"
      fi
    }

    RPROMPT_BASE="\${vcs_info_msg_0_}%F{blue}%~%f"
    setopt PROMPT_SUBST

    # Anonymous function to avoid leaking variables.
    function () {
      # Check for tmux by looking at $TERM, because $TMUX won't be propagated to any
      # nested sudo shells but $TERM will.
      local TMUXING=$([[ "$TERM" =~ "tmux" ]] && echo tmux)
      local INTMUX=""
      if [ -n "$TMUXING" -a -n "$TMUX" ]; then
        # In a tmux session created in a non-root or root shell.
        INTMUX='tmux'
      fi

      # Either in a root shell created inside a non-root tmux session,
      # or not in a tmux session.
      local LVL="$(($(pstree -s $$ | grep -wo 'zsh' | wc -l)-1))"

      if [[ $USER == "root" ]]; then
        LVL="$(($LVL-1))"
        export PS1="%F{green}${SSH_TTY:+%n@%m}%f%B${SSH_TTY:+:}%b%F{blue}%B%1~%b%F{yellow}%B%(1j.*.)%(?..!)%b%f %B%F{yellow}${INTMUX}%f${SUFFIX}%b "
      fi
      local SUFFIX='%(!.%F{yellow}%n%f.)%(!.%F{yellow}.%F{red})'$(printf '\u276f%.0s' {1..$LVL})'%f'

      export PS1="%F{green}${SSH_TTY:+%n@%m}%f%B${SSH_TTY:+:}%b%F{blue}%B%1~%b%F{yellow}%B%(1j.*.)%(?..!)%b%f %B%F{yellow}${INTMUX}%f${SUFFIX}%b "
      if [[ -n "$TMUXING" ]]; then
        # Outside tmux, ZLE_RPROMPT_INDENT ends up eating the space after PS1, and
        # prompt still gets corrupted even if we add an extra space to compensate.
        export ZLE_RPROMPT_INDENT=0
      fi
    }

    export RPROMPT=$RPROMPT_BASE
    export SPROMPT="zsh: correct %F{red}'%R'%f to %F{red}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]? "
}

gh0st_prompt() {
  git_prompt() {
    local branch="$(git symbolic-ref HEAD 2> /dev/null | cut -d'/' -f3-)"
    local branch_truncated="${branch:0:30}"
    if (( ${#branch} > ${#branch_truncated} )); then
        branch="${branch_truncated}..."
    fi

    [ -n "${branch}" ] && echo "  ${branch}"
  }

  setopt PROMPT_SUBST
  PROMPT='%B%F{blue}󰣇%f%b  %B%F{magenta}%n%f%b %B%F{red}%~%f%b%B%F{yellow}$(git_prompt)%f%b %(?.%B%F{green}✓.%F{red}✕)%f%b %B%F{green}%f%b '

}

##--> Calling the Prompt <--##
if [ $PROMPT_THEME = "gh0st" ]; then
  gh0st_prompt
elif [ $PROMPT_THEME = "z" ]; then
  z_prompt
elif [ $PROMPT_THEME = "10k" ]; then
  10k_prompt
else
  return
fi

# vim:filetype=zsh
