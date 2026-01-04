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
    IS_MAC=0
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

function fman() {
    local MAN="/usr/bin/man"
    [ ! -f "$MAN" ] && MAN="man"

    if [ -n "$1" ]; then
        $MAN "$@"
    else
        $MAN -k . | fzf --reverse --preview="echo {1,2} | sed 's/ (/./' | sed -E 's/\)\s*$//' | xargs $MAN" | awk '{print $1 "." $2}' | tr -d '()' | $XARGS_R $MAN
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
    local projects="$HOME/Documents/Workspace"
    [[ ! -d $projects ]] && echo "$projects dir does not exist" && return 1

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
    fd --type d --hidden --follow --color=always --exclude ".git" . "$1"
}

_fzf_compgen_unalias() {
    local tmpfile=$(mktemp /tmp/zsh-complete.XXXXXX)
    alias >"$tmpfile"
    fzf "$@" --preview 'ESCAPED=$(printf "%s=" {} | sed -e '"'"'s/[]\/$*.^[]/\\&/g'"'"'); cat '"$tmpfile"' | grep "^$ESCAPED"'
    rm "$tmpfile"
}

_fzf_comprun() {
    local cmd=$1
    shift
    case "$cmd" in
        cd)           fzf "$@" --preview 'tree -C {} | head -200' ;;
        export|unset) fzf "$@" --preview "eval 'echo \$'{}" ;;
        ssh|telnet)   fzf "$@" --preview 'echo {}' ;;
        unalias)      _fzf_compgen_unalias "$@" ;;
        *)            fzf "$@" ;;
    esac
}


# ........................[  7. FZF Configuration  ]........................ #

export FZF_DEFAULT_OPTS="
--color fg:#d4d4d5,fg+:#f5c9c9,bg+:-1,hl:#0080ff,hl+:#FCE700
--color info:#79dcaa,prompt:#00788A,spinner:#3877ff,pointer:#d4d4d5
--color marker:#ffe59e,border:#101317,gutter:-1,header:#949494
--bind 'ctrl-j:preview-down,ctrl-k:preview-up,ctrl-a:select-all'
--bind 'ctrl-y:execute-silent(echo {+} | $CLIP_CMD)'
--bind 'ctrl-e:execute(echo {+} | xargs -o nvim)'
--bind 'ctrl-v:execute(code {+})'
--bind 'tab:down,shift-tab:up'
--prompt '  ' --pointer ' ' --border none --height 40
"

# Default Command (Optimized: Uses cached check to prefer rg > fd > find)
if is_installed rg; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!node_modules/*"'
elif is_installed fd; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'
else
    export FZF_DEFAULT_COMMAND='find . -type f'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

export FZF_CTRL_T_OPTS="
--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {} 2>/dev/null || tree -C {} 2>/dev/null'
--bind 'ctrl-/:toggle-preview'
"

export FZF_ALT_C_OPTS="
--preview 'eza --tree --color=always {} | head -200'
"

