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
            if is_installed PrettyAlias; then
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
    if ! is_installed lazygit; then
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


# ........................[  5. Utilities  ]........................ #

# ------------------------------------------------------------------------------
# Function: weather
# Description: Fetches weather report using wttr.in.
# ------------------------------------------------------------------------------
function weather() {
    # 1. Dependency Check
    if is_installed curl; then
        print "❌ Error: curl is required."
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

