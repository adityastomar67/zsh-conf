#    ░█▀▀░█░█░█▀█░█▀▀░▀█▀░█▀▀░█▀█░█▀▀
#    ░█▀▀░█░█░█░█░█░░░░█░░█░█░█░█░▀▀█
#    ░▀░░░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------------------------------------------------------------
# File Purpose
#   This file defines custom shell functions and utilities.
#   It acts as a standard library for interactive shell usage.
#
# Problems Solved
#   - Wrapper for Neovim to handle Sudo and Config switching automatically.
#   - Wrapper for Lazygit to allow changing directories on exit.
#   - Debugging tools for Zsh startup profiling.
#   - Safety guard for Kubernetes production contexts.
#
# Features / Responsibilities
#   - `v`: Smart Editor wrapper.
#   - `lg`: Smart Git wrapper.
#   - `alias`: Pretty printing for aliases.
#   - `kubectl`: Production guardrail.
#
# Usage Notes
#   - Set LOAD_CUSTOM_FUNCTIONS="No" in ~/user.conf to disable.
# ------------------------------------------------------------------------------


# ........................[  1. Initialization  ]........................ #

# Exit if functions are disabled in config
[[ "${LOAD_CUSTOM_FUNCTIONS:l}" != "yes" ]] && return

# Annex Loading: Dynamically adds 'annexes' to the fpath (function path).
# (N:t) modifier:
#   N: null_glob (don't error if empty)
#   t: tail (basename only)
fpath=("$ZSH_CONFIG_ROOT/conf.d/annexes" $fpath)
autoload -Uz "$ZSH_CONFIG_ROOT/conf.d/annexes/"*(N:t)


# ........................[  2. Debugging Tools  ]........................ #

# ------------------------------------------------------------------------------
# Function: _zsh_debug_startup
# Description:
#   A troubleshooting utility that restarts the shell in debug mode.
#   It enables 'xtrace' (-x) to print commands as they execute and 'verbose' (-v)
#   to print input lines. It also captures 'zprof' profiling data if enabled.
#
#   All output is redirected to log files in ~/.config/zsh-conf/logs/ to avoid
#   flooding the terminal.
# ------------------------------------------------------------------------------
function _zsh_debug_startup() {
    # 1. Define Log Locations
    local log_dir="$HOME/zsh-logs"
    local debug_log="$log_dir/zsh-debug.log"
    local prof_log="$log_dir/zsh-prof.log"

    # 2. Safety: Ensure directory exists
    [[ -d "$log_dir" ]] || mkdir -p "$log_dir"

    # 3. Optional Profiling (Zprof)
    if [[ "${ZSH_BENCHMARK:l}" == "yes" ]]; then
        zprof > "$prof_log"
    fi

    # 4. User Feedback
    clear
    print "${COLOR[YELLOW]}🚧 Starting Zsh Debugger...${COLOR[RESET]}"
    print "   • Debug Log:   ${COLOR[UNDERLINE]}$debug_log${COLOR[RESET]}"

    if [[ "${ZSH_BENCHMARK:l}" == "yes" ]]; then
        print "   • Profile Log: ${COLOR[UNDERLINE]}$prof_log${COLOR[RESET]}"
    fi

    print "   • Shell:       Restarting with ${COLOR[BLUE]}xtrace (-x)${COLOR[RESET]} and ${COLOR[BLUE]}verbose (-v)${COLOR[RESET]}..."
    print "                  Press \`exit\` to stop tracing and end Debug Shell."

    # 5. Launch Debug Shell
    #    -x: xtrace (print commands as they are executed)
    #    -v: verbose (print shell input lines as they are read)
    ZSH_BENCHMARK="No" zsh -l -i -x -v 2>> "$debug_log"
}


# ........................[  3. Core Overrides  ]........................ #

# ------------------------------------------------------------------------------
# Function: alias
# Description:
#   Wraps the builtin 'alias' command to provide syntax highlighting.
#   If no arguments are passed, it pipes the output to 'PrettyAlias'.
# ------------------------------------------------------------------------------
if [[ "${LOAD_CUSTOM_ALIASES:l}" == "yes" ]]; then
    function alias() {
        if [[ $# -gt 0 ]]; then
            builtin alias "$@"
        else
            if (( $+commands[PrettyAlias] )); then
                builtin alias | PrettyAlias
            else
                builtin alias
            fi
        fi
    }
fi


# ........................[  4. Developer Tools  ]........................ #

# ------------------------------------------------------------------------------
# Function: lg
# Description:
#   Wraps 'lazygit' to enable directory changing upon exit.
#   Emulates the behavior of yazi/ranger file managers.
# ------------------------------------------------------------------------------
function lg() {
    if ! (( $+commands[lazygit] )); then
        print "${COLOR[RED]}Error:${COLOR[RESET]} 'lazygit' is not installed." >&2
        return 1
    fi

    local lg_config_file="${TMPDIR:-/tmp}/lazygit-chdir"
    LAZYGIT_NEW_DIR_FILE="$lg_config_file" command lazygit "$@"

    if [[ -f "$lg_config_file" ]]; then
        local target_dir=$(cat "$lg_config_file")
        if [[ -d "$target_dir" && "$target_dir" != "$PWD" ]]; then
            cd "$target_dir"
            print "${COLOR[GREEN]}:: Switched to:${COLOR[RESET]} $target_dir"
        fi
        rm -f "$lg_config_file"
    fi
}


# ------------------------------------------------------------------------------
# Function: pj (Project Jumper)
# Description:
#   Fuzzy find directories in Code/Work/Projects and jump to them.
#   Integrates with zoxide if available.
# ------------------------------------------------------------------------------
pj() {
    emulate -L zsh # Reset zsh options for this function (prevents bugs)

    # 1. Dependency Check
    if ! (( $+commands[fzf] )); then
        print "${COLOR[RED]}Error: fzf is required.$COLOR[RESET]"
        return 1
    fi

    # 2. Configuration  # TODO: Move this to a user-editable config file or environment variable
    # Define your search roots here
    # Search paths defined in user.conf, fallback to defaults if missing
    local -a raw_paths
    if (( ${#DIRECTORY_SHORTCUTS} > 0 )); then
        raw_paths=("${(@v)DIRECTORY_SHORTCUTS}")
    else
        raw_paths=(
            "$HOME/Code"
            "$HOME/Projects"
            "$HOME/Work"
            "$HOME/workspace"
            "${DOTFILES_ROOT}"
        )
    fi

    # 3. Fast Validation (Zsh Magic)
    # (N/) filters the list to only existing directories.
    # $^ expands the array to apply the check to each element.
    local search_paths=($^raw_paths(N/))

    if (( ${#search_paths} == 0 )); then
        print "${COLOR[YELLOW]}No valid project directories found.$COLOR[RESET]"
        return 1
    fi

    # 4. Preview Strategy (Smart Fallback)
    local preview_cmd="ls -A --color=always {}"
    (( $+commands[eza] )) && preview_cmd="eza -1 --color=always --icons --group-directories-first --git {}"

    # 5. Search Execution
    local proj
    local fzf_opts=(
        --query "$*"       # Use function args as search query
        --select-1         # Auto-select if only 1 match found
        --exit-0           # Exit if query yields no results
        --prompt="🚀 Jump > "
        --preview "$preview_cmd"
        --height=50%
        --layout=reverse
        --border
    )

    # Use 'fd' if available (faster, respects .gitignore), else 'find'
    if (( $+commands[fd] )); then
        # --absolute-path ensures cd works from anywhere
        proj=$(fd . "${search_paths[@]}" --min-depth 1 --max-depth 2 --type d --absolute-path 2>/dev/null | fzf "${fzf_opts[@]}")
    else
        proj=$(find "${search_paths[@]}" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | fzf "${fzf_opts[@]}")
    fi

    # 6. Result Handling
    if [[ -n "$proj" ]]; then
        # Zoxide / Autojump integration
        (( $+commands[zoxide] )) && zoxide add "$proj"

        cd "$proj"

        # Optional: Print where we landed
        print "${COLOR[GREEN]}➜ Switched to: ${COLOR[BOLD]}$proj${COLOR[RESET]}"
    fi
}


# ........................[  5. Utilities  ]........................ #

# ------------------------------------------------------------------------------
# Function: weather
# Description: Fetches weather report using wttr.in.
# ------------------------------------------------------------------------------
function weather() {
    # 1. Dependency Check
    if (( $+commands[curl] )); then
        print "${COLOR[RED]}Error: curl is required.$COLOR[RESET]"
        return 1
    fi

    # 2. Configuration
    local default_location="${WEATHER_DEFAULT_LOC:-Gwalior}"
    local location="${1:-$default_location}"

    # Handle spaces (New York -> New+York)
    location="${location// /+}"

    # 3. Smart Layout Logic
    # We build the URL parameters dynamically.
    # m = metric, Q = quiet (no message header)
    local -a args=("m" "Q")

    # Use native Zsh $COLUMNS variable (faster/safer than tput)
    local width="${COLUMNS:-$(tput cols)}"

    if [[ "$width" -lt 80 ]]; then
        # Tiny screen? Show ONLY current weather (no forecast tables)
        args+=("0")
    elif [[ "$width" -lt 140 ]]; then
        # Medium screen? Force narrow version (vertical stack)
        args+=("n")
    fi
    # > 140 cols will use the standard wide view

    # 4. Construct URL
    # Join args with '&' to ensure wttr.in parses them correctly
    # (zsh array joining magic: ${(j:&:)args})
    local url_params="${(j:&:)args}"

    curl -s "wttr.in/${location}?${url_params}"
}


# ........................[  6. Kubernetes Production Guard  ]........................ #

# ------------------------------------------------------------------------------
# Function: kubectl Overload
# Description:
#   A safety interceptor for kubectl. It prompts for confirmation if the current
#   context is a production environment and the command is destructive.
# ------------------------------------------------------------------------------
function kubectl() {
    local cmd_args="$*"

    # 1. Check for destructive/modifying commands
    if [[ "$cmd_args" =~ "delete|scale|apply|edit" ]]; then

        # 2. Retrieve current context
        local current_ctx
        current_ctx=$(command kubectl config current-context 2>/dev/null)

        # 3. Guard PRODUCTION keywords
        if [[ "$current_ctx" =~ "prod|production|live|main" ]]; then
            print "\n${COLOR[BOLD]}${COLOR[RED]}[K8S GUARD] 🛑 WARNING: Targeting PRODUCTION ($current_ctx)${COLOR[RESET]}"
            print "Command: ${COLOR[YELLOW]}kubectl $cmd_args${COLOR[RESET]}"
            print -n "Are you sure? [y/N] "

            # read -q: read one character and compare it to 'y'
            if ! read -q; then
                print # Newline
                print "${COLOR[RED]}Aborted.${COLOR[RESET]}"
                return 1
            fi
            print # Newline
        fi
    fi

    # 4. Standard passthrough
    command kubectl "$@"
}



# ........................[  7. Lazy Loading Wrappers  ]........................ #

# ------------------------------------------------------------------------------
# Function: nvm (Lazy Load)
# Description:
#   Loads NVM (Node Version Manager) only when a node-related command is run.
#   Usage: nvm, node, npm, npx, pnpm, yarn
# ------------------------------------------------------------------------------
# 1. Define the commands that trigger loading
local nvm_triggers=(nvm node npm npx pnpm yarn)

# 2. Check if NVM exists before setting up triggers
if [[ -d "$HOME/.nvm" ]]; then

    # The "Worker" function
    _nvm_lazy_load() {
        # Cleanup: Unset the dummy functions
        unset -f _nvm_lazy_load $nvm_triggers

        # Setup: Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Optional: Load bash completion (makes nvm usable immediately)
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

        # Execution: Run the command that triggered this function
        # "$0" is the command name (e.g., 'npm'), "$@" are the args
        exec "$0" "$@"
    }

    # 3. Create the dummy triggers
    for cmd in $nvm_triggers; do
        eval "function $cmd() { _nvm_lazy_load \"\$@\"; }"
    done
fi

# ------------------------------------------------------------------------------
# Function: pyenv (Lazy Load)
# Description:
#   Loads Pyenv only when a python-related command is run.
#   Usage: pyenv, python, pip, poetry
# ------------------------------------------------------------------------------
# Check if pyenv is in path OR installed in home
# 1. Define the trigger command list
# Add any other pyenv-managed commands here (e.g., pytest, jupyter)
local _pyenv_triggers=(pyenv python pip poetry)

# 2. The single "Worker" function
_pyenv_lazy_load() {
    # Cleanup: Remove the dummy functions/aliases so they don't loop
    unset -f _pyenv_lazy_load
    for cmd in $_pyenv_triggers; do unset -f $cmd; done

    # Setup: Add pyenv to PATH if it's not there (Standard Install)
    [[ -d "$HOME/.pyenv/bin" ]] && export PATH="$HOME/.pyenv/bin:$PATH"

    # Activate: Initialize pyenv (this updates PATH and shims)
    if (( $+commands[pyenv] )); then
        eval "$(pyenv init -)"

        # Optional: Load pyenv-virtualenv if you use it
        # eval "$(pyenv virtualenv-init -)"
    else
        echo "Error: pyenv not found." >&2
        return 1
    fi

    # Re-run: Execute the command the user actually typed
    # "$0" is the function name (e.g., python), "$@" are the args
    exec "$0" "$@"
}

# 3. Create the triggers
# We check if pyenv exists roughly (directory or binary) before setting traps
if [[ -d "$HOME/.pyenv" ]] || (( $+commands[pyenv] )); then
    for cmd in $_pyenv_triggers; do
        # Define a function for each trigger that calls the loader
        eval "function $cmd() { _pyenv_lazy_load \"\$@\"; }"
    done
fi


