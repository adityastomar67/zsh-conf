# █▀▀ █ █ █▄ █ █▀▀ ▀█▀ █ █▀█ █▄ █ █▀
# █▀  █▄█ █ ▀█ █▄▄  █  █ █▄█ █ ▀█ ▄█

if [ $USE_FUNCTION = "Yes" ]; then

    ##--> If $1 is a directory, remove it with rm only <--##
    function rm() {
        for arg in "$@"; do
            # check if the argument is a directory
            if [ -d "$arg" ]; then
                # if it is, then remove it with rm
                command rm -rf "$arg"
                # and continue to the next argument
                continue
            fi
            # if it is not a directory, then remove it with the original rm
            command rm "$arg"
        done
    }

    ##--> For Launcing NeoVim and SudoEdit with same command <--##
    function v() {
        if [ $(nvim --version | grep -oP '(?<=^NVIM v)[0-9|.][0-9|.][0-9|.]') = 0.9 ] && [ $# -gt 0 ] && [ ! -f $1 ] && [ ! -d $1 ]; then
            case "$1" in
            -a | --astro)
                NVIM_APPNAME=AstroNvim nvim $2
                ;;
            -l | --lazy)
                NVIM_APPNAME=LazyVim nvim $2
                ;;
            -c | --chad)
                NVIM_APPNAME=NvChad nvim $2
                ;;
            -n | --nv)
                NVIM_APPNAME=LazyNV nvim $2
                ;;
            *)
                echo "No config found for the choice!" >&2
                ;;
            esac
        else
            file=$1
            if [[ -e $file && ! -w $file ]]; then
                sudoedit $file
            else
                nvim $file
            fi
        fi
    }

    ##--> Get Temperature for $CITY <--##
    function get_temperature() {
        local response=""
        response=$(curl --silent 'https://api.openweathermap.org/data/2.5/weather?id=5110253&units=imperial&appid=<your_api_key>')
        local status=$(echo $response | jq -r '.cod')
        case $status in
        200)
            printf "Location: %s %s\n" "$(echo $response | jq '.name') $(echo $response | jq '.sys.country')"
            printf "Forecast: %s\n" "$(echo $response | jq '.weather[].description')"
            printf "Temperature: %.1f°F\n" "$(echo $response | jq '.main.temp')"
            printf "Temp Min: %.1f°F\n" "$(echo $response | jq '.main.temp_min')"
            printf "Temp Max: %.1f°F\n" "$(echo $response | jq '.main.temp_max')"
            ;;
        401)
            echo "401 error"
            ;;
        *)
            echo "error"
            ;;
        esac
    }

    ##--> Empty Trash Bin <--##
    function empty_trash() {
        [ ! -d "$HOME/.Trash/files" ] && return
        printf "%s\n" "EMPTYING TRASH"
        sudo command rm -rf $HOME/.Trash/files/*
    }

    ##--> Initializing a Repository <--##
    function repo() {
        git init
        if [[ ! -e "./README.md" ]]; then
            touch README.md
        fi
        if [[ ! -e "./.gitignore" ]]; then
            touch .gitignore
        fi
        git branch -m main
        git remote add origin "$1"
        git add .
        git commit -m "First Commit"
        git push origin HEAD
    }

    ##--> Countdown function for terminal <--##
    function countdown() {
        date1=$(($(date +%s) + $1))
        while [ "$date1" -ge $(date +%s) ]; do
            echo -ne "$(date -u --date @$(($date1 - $(date +%s))) +%H:%M:%S)\r"
            sleep 0.1
        done
    }

    ##--> Stopwatch function for terminal <--##
    function stopwatch() {
        date1=$(date +%s)
        while true; do
            echo -ne "$(date -u --date @$(($(date +%s) - $date1)) +%H:%M:%S)\r"
            sleep 0.1
        done
    }

    ##--> Create the directory while creating the file <--##
    function touchdir() { mkdir -p "$(dirname "$1")" && touch "$1"; }

    ##--> Recursively delete `passed type' files <--##
    function del() {
        find . -type f -name "$1" -ls -delete
    }

    ##--> Initialize conda <--##
    function cond() {
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

    ##--> Sorting file's content <--##
    function srt() {
        mv "$1" "$1.bak"
        sort "$1.bak" | uniq >$1
        rm "$1.bak"
    }

    ##--> Determine size of a file or total size of a directory <--##
    function fs() {
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

    ##--> Code Runner <--##
    function prog() {
        if [ -f "$1" ]; then
            case $1 in
            *.cpp) g++ -std=c++20 "$1" && ./a.out && rm -f a.out ;;
            *.c) gcc "$1" && ./a.out && rm -f a.out ;;
            *.java) javac "$1" && java "$(basename -s .java "$1")" && rm -f *.class ;;
            *.py) python "$1" ;;
            *.sh) bash "$1" ;;
            *.pl) perl "$1" ;;
            *.rb) ruby "$1" ;;
            *.go) go run "$1" ;;
            *.js) node "$1" ;;
            *.php) php "$1" ;;
            *) echo "'$1' is not a supported file type." ;;
            esac
        else
            echo "'$1' is not a valid file"
        fi
    }

    ##--> Function extract for common file formats <--##
    function ex() {
        if [ -f "$1" ]; then
            case $1 in
            *.tar.bz2) tar xjf $1 ;;
            *.tar.gz) tar xzf $1 ;;
            *.bz2) bunzip2 $1 ;;
            *.rar) unrar x $1 ;;
            *.gz) gunzip $1 ;;
            *.tar) tar xf $1 ;;
            *.tbz2) tar xjf $1 ;;
            *.tgz) tar xzf $1 ;;
            *.zip) unzip $1 ;;
            *.Z) uncompress $1 ;;
            *.7z) 7z x $1 ;;
            *.deb) ar x $1 ;;
            *.tar.xz) tar xf $1 ;;
            *.tar.zst) unzstd $1 ;;
            *) echo "'$1' cannot be extracted via extract()" ;;
            esac
        else
            echo "'$1' is not a valid file"
        fi
    }

    ##--> Navigation <--##
    function up() {
        local d=""
        local limit="$1"

        # Default to limit of 1
        if [ -z "$limit" ] || [ "$limit" -le 0 ]; then
            limit=1
        fi

        for ((i = 1; i <= limit; i++)); do
            d="../$d"
        done

        # perform cd. Show error if cd fails
        if ! cd "$d"; then
            echo "Couldn't go up $limit dirs."
        fi
    }

    ##--> Directly backup the data to gdrive using terminal <--##
    function backupToDrive() {
        cp "$1" /Users/ <username >/Google\ Drive/Config/.zshrc
        echo "New .zshrc backed up to Google Drive."
    }

    ##--> Editing .zshrc and sourcing <--##
    function editZsh() {
        [ ! -f ~/.zshrc ] && return
        nvim ~/.zshrc
        source ~/.zshrc
        backupToDrive ~/.zshrc
        echo "New .zshrc sourced."
    }

    ##--> Create a data URL from a file <--##
    function dataurl() {
        local mimeType=$(file -b --mime-type "$1")
        if [[ $mimeType == text/* ]]; then
            mimeType="${mimeType};charset=utf-8"
        fi
        echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
    }

    ##--> Create a new React App <--##
    function react() {
        npx create-react-app $1
        cd $1
        npm i -D eslint
        npm i -D eslint-config-prettier eslint-plugin-prettier
        npm i -D eslint-config-airbnb eslint-plugin-import eslint-plugin-jsx-a11y eslint-plugin-react eslint-plugin-react-hooks
        [ -f "~/.eslintrc.json" ] && cp "${HOME}/.eslintrc.json" .
        [ -f "~/.prettierrc.json" ] && cp "${HOME}/.prettierrc" .
        echo $1 >README.md
        rm -rf yarn.lock
        # cd src
        # rm -f App.css App.test.js index.css logo.svg serviceWorker.js
        mkdir components views
        git add -A
        git commit -m "Initial commit."
        cd ..
        clear
        code .
    }

    ##--> Use Git’s colored diff when available <--##
    hash git &>/dev/null
    if [ $? -eq 0 ]; then
        function diff() {
            git diff --no-index --color-words "$@"
        }
    fi

    ##--> Start an HTTP server from a directory, optionally specifying the port <--##
    function server() {
        local port="${1:-8000}"
        sleep 1 && open "http://localhost:${port}/" &
        # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
        # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
        python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
    }

    ##--> Git commit browser. needs fzf <--##
    function git_log() {
        git log --graph --color=always \
            --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
            fzf --ansi --no-sort --reverse --tiebreak=index --toggle-sort=\` \
                --bind "ctrl-m:execute:
            echo '{}' | grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R'"
    }

    ##--> Compress the PDF <--##
    function compress-pdf() {
        local level="screen"
        [[ "$3" != "" ]] && level="$3"
        [ $(command -v gs) ] &&
            gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/"$level" -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$2.pdf" "$1.pdf" ||
            echo 'Ghostscript - gs needs to be installed.'
    }

    ##--> Files with FZF <--##
    function _smooth_fzf() {
        local fname
        local current_dir="$PWD"
        cd "${XDG_CONFIG_HOME:-~/.config}"
        fname="$(fzf)" || return
        $EDITOR "$fname"
        cd "$current_dir"
    }

    ##--> Shell greeter <--##
    function _default_greeter() {
        c1="\033[1;30m"
        c2="\033[1;31m"
        c3="\033[1;32m"
        c4="\033[1;33m"
        c5="\033[1;34m"
        c6="\033[1;35m"
        c7="\033[1;36m"
        c8="\033[1;37m"
        reset="\033[1;0m"
        printf "\n $c1▇▇ $c2▇▇ $c3▇▇ $c4▇▇ $c5▇▇ $c6▇▇ $c7▇▇ $c8▇▇ $reset\n\n"
    }

    ##--> Top memory hawk processes <--##
    function toppy() {
        history |
            awk '{
            CMD[$2]++;
            count++;
        } END {
        for (a in CMD)
            print CMD[a] " " CMD[a] / count * 100 "% " a;
        }' |
            grep -v "./" |
            column -c3 -s " " -t |
            sort -nr |
            nl |
            head -n 21
    }

    ##--> Setting lz for lazygit <--##
    if [[ $(command -v lazygit) ]]; then
        function lz() {
            export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

            lazygit "$@"

            if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
                cd "$(command cat $LAZYGIT_NEW_DIR_FILE)"
                rm -f $LAZYGIT_NEW_DIR_FILE >/dev/null
            fi
        }
    fi

fi

# TODO: Not Working correcly...Need to check
# fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim

# vim:filetype=zsh
