# ------------------------[  ZSH FUNCTIONS CONFIGURATION  ]------------------------ #
# This file defines custom shell functions and utilities.
#
# NOTE: To disable functions, set USE_FUNCTION="No" in ~/.zshenv


# ........................[  1. Initialization  ]........................ #

# Exit if functions are disabled in config
[[ "$USE_FUNCTION" != "Yes" ]] && return

# Load FZF integration if available
[ -f "$ZSH_PATH/zsh/conf/fzf.zsh" ] && source "$ZSH_PATH/zsh/conf/fzf.zsh" &> /dev/null


# ........................[  2. Core Overrides & Wrappers  ]........................ #

# Safer rm: Removes directories with -rf automatically
rm() {
    for arg in "$@"; do
        if [ -d "$arg" ]; then
            command rm -rf "$arg"
            continue
        fi
        command rm "$arg"
    done
}

# Advanced Editor Launcher (Supports Multi-Config Neovim)
v() {
    if [ "$MULTI_NEOVIM" = "Yes" ] && [ $# -gt 1 ] && [ ! -f "$1" ] && [ ! -d "$1" ]; then
        case "$1" in
            -a | --astro)  NVIM_APPNAME=AstroNvim nvim "$2" ;;
            -l | --lazy)   NVIM_APPNAME=LazyVim nvim "$2"   ;;
            -c | --chad)   NVIM_APPNAME=NvChad nvim "$2"    ;;
            -n | --nv)     NVIM_APPNAME=LazyNV nvim "$2"    ;;
            *)             echo "No config found for the choice!" >&2 ;;
        esac
    else
        local file="${1:-.}"
        if [[ -e "$file" && ! -w "$file" ]]; then
            sudoedit "$file"
        else
            nvim "$file"
        fi
    fi
}

# Use Git’s colored diff when available
if command -v git &>/dev/null; then
    diff() {
        git diff --no-index --color-words "$@"
    }
fi


# ........................[  3. File & Directory Operations  ]........................ #

# Smart Directory Creation: mkdir -p then touch file
touchdir() { mkdir -p "$(dirname "$1")" && touch "$1"; }

# Create dir and enter it
takedir() { mkdir -p "$@" && cd "${@:$#}"; }

# Smart 'Take': Clones git repo or creates dir
take() {
    if [[ $1 =~ ^([A-Za-z0-9]\+@|https?|git|ssh|ftps?|rsync).*\.git/?$ ]]; then
        git clone "$1"
        cd "$(basename "${1%%.git}")"
    else
        takedir "$1"
    fi
}

# Go Up Multiple Directories (e.g., up 3)
up() {
    local limit="${1:-1}"
    local d=""
    for ((i = 1; i <= limit; i++)); do
        d="../$d"
    done
    cd "$d" || echo "Couldn't go up $limit dirs."
}

# Smart Extraction
ex() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2) tar xjf "$1" ;;
            *.tar.gz)  tar xzf "$1" ;;
            *.bz2)     bunzip2 "$1" ;;
            *.rar)     unrar x "$1" ;;
            *.gz)      gunzip "$1" ;;
            *.tar)     tar xf "$1" ;;
            *.tbz2)    tar xjf "$1" ;;
            *.tgz)     tar xzf "$1" ;;
            *.zip)     unzip "$1" ;;
            *.Z)       uncompress "$1" ;;
            *.7z)      7z x "$1" ;;
            *.deb)     ar x "$1" ;;
            *.tar.xz)  tar xf "$1" ;;
            *.tar.zst) unzstd "$1" ;;
            *)         echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Calculate Size (File or Directory)
fs() {
    if du -b /dev/null >/dev/null 2>&1; then
        local arg=-sbh
    else
        local arg=-sh
    fi
    if [[ -n "$@" ]]; then
        du $arg -- "$@"
    else
        du $arg .[^.]* ./*
    fi
}

# Sort File Content Unique
srt() {
    mv "$1" "$1.bak"
    sort "$1.bak" | uniq > "$1"
    rm "$1.bak"
}

# Delete files recursively by name
del() {
    find . -type f -name "$1" -ls -delete
}

# Empty Trash
empty_trash() {
    [ ! -d "$HOME/.Trash/files" ] && return
    printf "%s\n" "EMPTYING TRASH"
    sudo command rm -rf "$HOME/.Trash/files/*"
}


# ........................[  4. Developer Tools  ]........................ #

# Universal Code Runner
prog() {
    if [ -f "$1" ]; then
        case "$1" in
            *.cpp)  g++ -std=c++20 "$1" && ./a.out && rm -f a.out ;;
            *.c)    gcc "$1" && ./a.out && rm -f a.out ;;
            *.java) javac "$1" && java "$(basename -s .java "$1")" && rm -f *.class ;;
            *.py)   python "$1" ;;
            *.sh)   bash "$1" ;;
            *.pl)   perl "$1" ;;
            *.rb)   ruby "$1" ;;
            *.go)   go run "$1" ;;
            *.js)   node "$1" ;;
            *.php)  php "$1" ;;
            *)      echo "'$1' is not a supported file type." ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Initialize Git Repository
repo() {
    git init
    [ ! -e "./README.md" ] && touch README.md
    [ ! -e "./.gitignore" ] && touch .gitignore
    git branch -m main
    git remote add origin "$1"
    git add .
    git commit -m "First Commit"
    git push origin HEAD
}

# Git Log Browser (Requires fzf)
git_log() {
    git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --toggle-sort=\` \
        --bind "ctrl-m:execute:echo '{}' | grep -o '[a-f0-9]\{7\}' | head -1 | xargs -I % sh -c 'git show --color=always % | less -R'"
}

# Lazygit Integration (Changes dir on exit)
if command -v lazygit &>/dev/null; then
    lz() {
        export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
        lazygit "$@"
        if [ -f "$LAZYGIT_NEW_DIR_FILE" ]; then
            cd "$(cat "$LAZYGIT_NEW_DIR_FILE")"
            rm -f "$LAZYGIT_NEW_DIR_FILE" >/dev/null
        fi
    }
fi

# Simple Python HTTP Server
server() {
    local port="${1:-8000}"
    sleep 1 && open "http://localhost:${port}/" &
    python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Cheat Sheet Lookup
cht() {
    local options=${2:-Q}
    curl cht.sh/"$1"?"$options"
}


# ........................[  5. Utilities & Stats  ]........................ #

# Stopwatch
stopwatch() {
    local date1=$(date +%s)
    while true; do
        echo -ne "$(date -u --date @$(($(date +%s) - date1)) +%H:%M:%S)\r"
        sleep 0.1
    done
}

# Countdown (Usage: countdown 60)
countdown() {
    local date1=$(($(date +%s) + $1))
    while [ "$date1" -ge $(date +%s) ]; do
        echo -ne "$(date -u --date @$(($date1 - $(date +%s))) +%H:%M:%S)\r"
        sleep 0.1
    done
}

# Weather Check
get_temperature() {
    local response
    response=$(curl --silent 'https://api.openweathermap.org/data/2.5/weather?id=5110253&units=imperial&appid=<your_api_key>')
    local status=$(echo "$response" | jq -r '.cod')
    case $status in
        200)
            printf "Location: %s %s\n" "$(echo "$response" | jq '.name') $(echo "$response" | jq '.sys.country')"
            printf "Forecast: %s\n" "$(echo "$response" | jq '.weather[].description')"
            printf "Temperature: %.1f°F\n" "$(echo "$response" | jq '.main.temp')"
            ;;
        *) echo "Error: $status" ;;
    esac
}

# Most Used Commands Stats
hstat() {
    fc -l 1 | awk '{ CMD[$2]++; count++; } END { for (a in CMD) print CMD[a] " " CMD[a]*100/count "% " a }' | grep -v "./" | sort -nr | head -20 | column -c3 -s " " -t | nl
}

# Currency Rate (USD -> RUB default)
rate() {
    local from=${1:-usd}
    local to=${2:-rub}
    local erapi_key="71afe1269a1f5f7206152de2b43a9819"
    local rate=$(curl -s "http://api.exchangeratesapi.io/v1/latest?access_key=${erapi_key}" | jq .rates.${(U)to})
    echo "1 ${(U)from} is ${rate} ${(U)to}"
}

# Crypto Rate (Bitcoin -> USD default)
crate() {
    local coin=${1:-bitcoin}
    local currency=${2:-usd}
    local crate=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=${coin}&vs_currencies=${currency}" | jq .${coin}.${currency})
    echo "1 ${coin} is ${crate} $currency"
}


# ........................[  6. Miscellaneous  ]........................ #

# Default Greeter (Color Bars)
_default_greeter() {
    local c1="\033[1;30m" c2="\033[1;31m" c3="\033[1;32m" c4="\033[1;33m"
    local c5="\033[1;34m" c6="\033[1;35m" c7="\033[1;36m" c8="\033[1;37m"
    local reset="\033[1;0m"
    printf "\n $c1▇▇ $c2▇▇ $c3▇▇ $c4▇▇ $c5▇▇ $c6▇▇ $c7▇▇ $c8▇▇ $reset\n\n"
}

# Edit & Source Zshrc
editZsh() {
    [ ! -f ~/.zshrc ] && return
    nvim ~/.zshrc
    source ~/.zshrc
    echo "New .zshrc sourced."
}

# Conda Initialization
cond() {
    __conda_setup="$('/opt/miniconda3/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/opt/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="/opt/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
}

# Matrix Effect
matrix() {
    local lines=$(tput lines)
    local cols=$(tput cols)
    echo -e "\e[1;40m"
    clear
    while :; do
        echo $lines $cols $(( $RANDOM % $cols)) $(( $RANDOM % 72 ))
        sleep 0.05
    done | awk '
    {
        letters="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*()"
        lines=$1; random_col=$3; c=$4
        letter=substr(letters,c,1)
        cols[random_col]=0;
        for (col in cols) {
            line=cols[col]; cols[col]=cols[col]+1;
            printf "\033[%s;%sH\033[2;32m%s", line, col, letter;
            printf "\033[%s;%sH\033[1;37m%s\033[0;0H", cols[col], col, letter;
            if (cols[col] >= lines) { cols[col]=0; }
        }
    }'
}

# vim:filetype=zsh
