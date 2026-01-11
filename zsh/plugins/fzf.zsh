#    ░█▀▀░▀▀█░█▀▀░░░░▀▀█░█▀▀░█░█
#    ░█▀▀░▄▀░░█▀▀░░░░▄▀░░▀▀█░█▀█
#    ░▀░░░▀▀▀░▀░░░▀░░▀▀▀░▀▀▀░▀░▀

# ------------------------[  FZF INTEGRATION  ]------------------------ #
# This file provides advanced FZF-powered utilities and functions.
# Works on: Arch Linux (Pacman) & macOS (Homebrew)
# Requires: fzf, bat (optional), fd/rg (optional), delta (optional)


# ........................[  1. Initialization  ]........................ #

# Exit if functions are disabled in config
[[ "$USE_FUNCTION" != "Yes" ]] && return

# ---------------------------------------------------------
#  HELPER: Global Installation Check (Cached)
#  Usage: is_installed <program_name>
#  Coming from env.zsh
# ---------------------------------------------------------

# Exit if FZF is missing (Cached check)
if ! is_installed fzf; then
    printf "\n\033[0;33m[WARN] USE_FUNCTION='Yes' but 'fzf' is not installed.\033[0m\n"
    return
fi

# --- OS & Clipboard Detection (Optimized) ---
IS_MAC=0
CLIP_CMD=""
XARGS_R=""

if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MAC=1
    CLIP_CMD="pbcopy"
    XARGS_R="xargs"
else
    XARGS_R="xargs -r"

    # Cached check for Linux clipboard tools
    if is_installed wl-copy; then
        CLIP_CMD="wl-copy"
    elif is_installed xclip; then
        CLIP_CMD="xclip -selection clipboard"
    elif is_installed xsel; then
        CLIP_CMD="xsel --clipboard --input"
    fi
fi

# Define Colors
RED_FG=$(tput setaf 1)
GREEN_BG=$(tput setab 2)
RESET=$(tput sgr0)
AWESOME_FZF_LOCATION="$ZSH_PATH/zsh/conf/fzf.zsh"


# ........................[  2. General Utilities  ]........................ #

# Show list of awesome functions defined in this file
function fzf_menu() {
    if [ ! -r "$AWESOME_FZF_LOCATION" ]; then
        echo "${RED_FG}Awesome-FZF file not found at $AWESOME_FZF_LOCATION${RESET}"
        return 1
    fi

    local selected
    selected=$(grep -E "^[ \t]*function " "$AWESOME_FZF_LOCATION" |
        sed -e "s/^[ \t]*function //" -e "s/() {.*//" |
        grep -v "fzf_menu" |
        sort |
        fzf --prompt="FZF Tools > " \
            --preview "grep -n -A 20 \"function {}\" \"$AWESOME_FZF_LOCATION\" | bat --color=always --style=numbers -l bash 2>/dev/null || cat" \
            --preview-window="right:60%:wrap")

    [[ -n "$selected" ]] && "$selected"
}

# Universal Uninstaller (Arch/Pacman & macOS/Brew)
function fzf_uninstall() {
    clear
    echo "${RED_FG}Uninstall Menu...${RESET}"
    local installed_packages selected_packages manager_cmd

    if [[ "$IS_MAC" -eq 1 ]] && is_installed brew; then
        echo ":: Loading Homebrew packages..."
        installed_packages=$(brew leaves)
        selected_packages=$(echo "$installed_packages" | fzf --multi --preview 'brew info {1}')
        manager_cmd="brew uninstall"

    elif is_installed pacman; then
        echo ":: Loading Pacman packages..."
        installed_packages=$(pacman -Qe | awk '{print $1}')
        selected_packages=$(echo "$installed_packages" | fzf --multi --preview 'pacman -Qi {1}')
        manager_cmd="sudo pacman -Rns"
    else
        echo "Error: No supported package manager (pacman/brew) found."
        return 1
    fi

    if [[ -n "$selected_packages" ]]; then
        echo "Removing: $selected_packages"
        echo "$selected_packages" | xargs $manager_cmd
        echo "${GREEN_BG}Uninstalled!${RESET}"
    else
        echo "No packages selected."
    fi
}

function fzf_rm() {
    if [[ "$#" -eq 0 ]]; then
        find . -maxdepth 1 -type f | fzf --multi | xargs -I '{}' rm -rf {}
    else
        command rm -rf "$@"
    fi
}



function fenv() {
    env | fzf | cut -d= -f2
}

function fkill() {
    local pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    [ -n "$pid" ] && echo "$pid" | xargs kill -${1:-9}
}

function cheat_sheet() {
    local languages="python go lua cpp rust js"
    local utils="tar xargs awk sed find"
    local selected=$(printf "%s\n%s" "$(echo $languages | tr ' ' '\n')" "$(echo $utils | tr ' ' '\n')" | fzf)

    [ -z "$selected" ] && return

    echo -n "query: "
    read query

    if echo "$languages" | grep -qs "$selected"; then
        curl -s "cht.sh/$selected/$(echo "$query" | tr ' ' '+')?Q"
    else
        curl -s "cht.sh/$selected~$(echo "$query" | tr ' ' '+')?Q"
    fi
}


# ........................[  3. Navigation & File Finding  ]........................ #

function f_open() {
    local file=$(fzf --multi --reverse)
    if [[ $file ]]; then
        echo "$file" | while read -r prog; do $EDITOR "$prog"; done
    else
        echo "${RED_FG}Cancelled FZF${RESET}"
    fi
}

function fcd() {
    local dir
    dir=$(find "${1:-.}" -path '*/\.*' -prune -o -type d -print 2>/dev/null | fzf +m) && cd "$dir"

    # Optimized: Cached check for eza/exa
    if is_installed eza; then
        eza -al --color=always --icons --git --group-directories-first
    elif is_installed exa; then
        exa -al --color=always --icons --git --group-directories-first
    else
        ls -al
    fi
}

function fcd_all() {
    local dir=$(find "${1:-.}" -type d 2>/dev/null | fzf +m) && cd "$dir" && ls
}

function fcd_file() {
    local file=$(fzf +m -q "$1") && cd "$(dirname "$file")" && ls
}

function cd_work() {
    local projects="$WORK_DIR"
    [[ ! -d $projects ]] && echo "$projects does not exist" && return 1

    local project
    if is_installed fd; then
        project=$(fd -t d --max-depth 1 . "$projects" | awk -F/ '{print $(NF-1)}' | fzf)
    else
        project=$(find "$projects" -maxdepth 1 -mindepth 1 -type d -not -path '*/.*' | awk -F/ '{print $NF}' | fzf)
    fi

    [[ -n $project ]] && cd "$projects/$project"
}


# ........................[  4. Git Integration  ]........................ #

is_in_git_repo() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }
fzf-down() { fzf --ansi --height 50% --min-height 20 --bind ctrl-f:preview-down,ctrl-b:preview-up --bind ctrl-p:toggle-preview "$@"; }
_pager='delta --side-by-side -w ${FZF_PREVIEW_COLUMNS:-$COLUMNS}'

function git_status() {
    is_in_git_repo || return
    local selected
    selected=$(git -c color.status=always status --short |
        fzf --height 50% "$@" --border -m --ansi --nth 2..,.. \
            --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
        cut -c4- | sed 's/.* -> //')
    [[ -n "$selected" ]] && $EDITOR $selected
}

function git_checkout() {
    is_in_git_repo || return
    if [[ "$#" -eq 0 ]]; then
        local branches branch
        branches=$(git branch -a)

        # Optimized: Cached check for fzf-tmux
        if is_installed fzf-tmux; then
            branch=$(echo "$branches" | fzf-tmux -d $((2 + $(wc -l <<<"$branches"))) +m)
        else
            branch=$(echo "$branches" | fzf +m)
        fi

        local target=$(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
        [[ -n "$target" ]] && git checkout "$target"
    else
        git checkout "$@" 2>/dev/null || git checkout -b "$@"
    fi
}

function git_add() {
    is_in_git_repo || return 1
    [[ $# -ne 0 ]] && git add "$@" && return

    local extract="sed 's/^.*]  //' | sed 's/.* -> //' | sed -e 's/^\\\"//' -e 's/\\\"\$//'"
    local preview="file=\$(echo {} | $extract); git diff --color=always -- \$file | $_pager"

    local files=$(git -c color.status=always -c status.relativePaths=true status -su |
        sed -E 's/^(..[^[:space:]]*)[[:space:]]+(.*)$/[\1]  \2/' |
        fzf-down -0 --multi --header 'enter to add' --preview-window right:70% --preview "$preview" |
        sh -c "$extract")

    [[ -n $files ]] && echo "$files" | tr '\n' '\0' | xargs -0 -I % git add % && return
    echo 'Nothing to add.'
}

function git_log() {
    is_in_git_repo || return 1
    local _view="echo {} | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % git show --color=always % | $_pager"
    git log --color=always --format='%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an' |
        fzf-down --no-sort --reverse --tiebreak=index --no-multi \
            --header 'enter to view' \
            --preview-window right:70% --preview "$_view" \
            --bind "enter:execute:$_view | less -R"
}


# ........................[  5. Docker  ]........................ #

function docker_rm_container() {
    local containers=$(docker ps | tail -n +2 | awk '{print $1" "$NF}' | fzf -m | cut -d " " -f 1 | tr "\n" " ")
    [[ -n $containers ]] && docker rm $(echo $containers) -f
}

function docker_rm_image() {
    local images=$(docker images | tail -n +2 | awk '{print $1" "$3}' | fzf -m | cut -d " " -f 2 | tr "\n" " ")
    [[ -n $images ]] && docker rmi $(echo $images) -f
}


# ........................[  6. Completion Helpers  ]........................ #

_fzf_compgen_dir() {
    local base_dir="$1"

    # 1. Use 'fd' (Best performance)
    if is_installed fd; then
        fd --type d --hidden --follow --color=always \
           --exclude ".git" \
           --exclude "node_modules" \
           . "$base_dir"

    # 2. Fallback to 'find' (Universal)
    else
        # Logic:
        # IF name is .git OR node_modules -> Prune (Skip entire folder)
        # ELSE IF it is a directory -> Print it
        command find -L "$base_dir" \
            \( -name .git -o -name node_modules \) -prune -o \
            -type d -print 2>/dev/null
    fi
}

_fzf_compgen_unalias() {
    # 1. Create a secure temp file (works on Linux & macOS)
    local tmp=$(mktemp "${TMPDIR:-/tmp}/zsh-aliases.XXXXXX")

    # 2. Auto-Cleanup: Remove file when this function finishes (Success or Failure)
    trap "rm -f '$tmp'" EXIT

    # 3. Dump current aliases to the file
    # We need a file because the FZF preview window runs in a separate subshell
    # and doesn't know about the aliases defined in your current session.
    alias > "$tmp"

    # 4. Construct the Preview Command
    # - grep -F: Search for fixed strings (no regex escaping needed)
    # - {}=    : Matches 'aliasname=' to ensure exact match
    local preview_cmd="grep -F --color=always \"{}=\" '$tmp'"

    # Optional: Use bat for syntax highlighting if available
    if is_installed bat; then
        # -l zsh : Force Zsh syntax highlighting
        # --plain: Remove grid/headers for cleaner look in small window
        preview_cmd="$preview_cmd | bat -l zsh --style=plain --color=always"
    fi

    # 5. Run FZF
    # Input: "${(@k)aliases}" gets just the names (keys) of all aliases
    print -l "${(@k)aliases}" | fzf "$@" --preview "$preview_cmd"
}

_fzf_comprun() {
    local command=$1
    shift

    case "$command" in
        # 1. Directory Navigation
        cd|pushd|rmdir)
            if is_installed eza; then
                fzf "$@" --preview 'eza --tree --level=2 --color=always --icons=always --group-directories-first {} | head -200'
            elif is_installed tree; then
                fzf "$@" --preview 'tree -C {} | head -200'
            else
                # Fallback for stock Mac/Linux
                fzf "$@" --preview 'ls -1 --color=always {} | head -200'
            fi
            ;;

        # 2. Editors & Viewers
        vim|nvim|vi|nano|code|cat|bat|less|more)
            if is_installed bat; then
                fzf "$@" --preview 'bat --style=numbers --color=always --line-range :500 {}' \
                        --preview-window 'right:60%:border-left'
            else
                fzf "$@" --preview 'cat {}'
            fi
            ;;

        # 3. Environment Variables
        export|unset|printenv)
            fzf "$@" --preview "printenv {}" --preview-window="bottom:3:wrap"
            ;;

        # 4. SSH & Telnet
        ssh|telnet)
            fzf "$@" --preview 'cat ~/.ssh/config 2>/dev/null | grep -A 4 "Host {}" || echo "System Host: {}"' \
                    --preview-window="bottom:20%:wrap"
            ;;

        # 5. Process Management
        kill|pkill)
            fzf "$@" --preview 'ps -fp {1} 2>/dev/null || echo "Process not found"' \
                    --preview-window="bottom:20%:wrap"
            ;;

        # 6. Service Management (Linux)
        systemctl)
             fzf "$@" --preview 'systemctl status {1} --no-pager 2>/dev/null || echo "Status unavailable"' \
                      --preview-window="right:60%:wrap"
             ;;

        # 7. Service Management (macOS)
        #    'launchctl list' shows PID, Last Exit Status, and Label
        launchctl)
             fzf "$@" --preview 'launchctl list {1} 2>/dev/null || echo "No info available for {1}"' \
                      --preview-window="bottom:20%:wrap"
             ;;

        # 8. Git
        git)
            if is_installed delta; then
                fzf "$@" --preview 'git diff --color=always {} | delta' --preview-window 'right:60%'
            else
                fzf "$@" --preview 'git diff --color=always {}' --preview-window 'right:60%'
            fi
            ;;

        # 9. Unalias
        unalias)
            _fzf_compgen_unalias "$@"
            ;;

        # 10. Fallback (Everything else)
        *)
            # We determine the preview command HERE in the parent shell
            # because 'is_installed' cannot be called inside the 'fzf' subshell.

            local preview_cmd="echo {}"

            # Determine File Viewer
            if is_installed bat; then
                # If it's a file, use bat
                preview_cmd="if [ -f {} ]; then bat --style=numbers --color=always --line-range :500 {};"
            else
                preview_cmd="if [ -f {} ]; then cat {};"
            fi

            # Determine Directory Viewer
            if is_installed eza; then
                 # Append eza logic
                 preview_cmd+=" elif [ -d {} ]; then eza --tree --level=2 --color=always --icons=always {} | head -200;"
            elif is_installed tree; then
                 preview_cmd+=" elif [ -d {} ]; then tree -C {} | head -200;"
            else
                 preview_cmd+=" elif [ -d {} ]; then ls -1 --color=always {};"
            fi

            # Close the logic
            preview_cmd+=" else echo {}; fi"

            # Run FZF with the constructed command
            fzf "$@" --preview "$preview_cmd"
            ;;
    esac
}

