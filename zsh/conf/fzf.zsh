# ▄▀█ █ █ █ █▀▀ █▀ █▀█ █▀▄▀█ █▀▀ ▄▄ █▀▀ ▀█ █▀▀
# █▀█ ▀▄▀▄▀ ██▄ ▄█ █▄█ █ ▀ █ ██▄    █▀  █▄ █▀

if command -v fzf >/dev/null; then
    if [ $USE_FUNCTION = "Yes" ]; then

        AWESOME_FZF_LOCATION="$HOME/.config/zsh/conf/fzf.zsh"
        RED_FG=$(tput setaf 1)
        GREEN_BG=$(tput setab 2)
        RESET=$(tput sgr0)

        ##--> List Awesome FZF Functions <--##
        function fzf-awesome-list() {
            if [ -r $AWESOME_FZF_LOCATION ]; then
                selected=$(grep -E "(function fzf-)(.*?)[^(]*" $AWESOME_FZF_LOCATION | sed -e "s/function fzf-//" | sed -e "s/() {//" | grep -v "selected=" | fzf --reverse --prompt="Awesome-FZF functions > ")
            else
                echo "${RED_FG}Awesome-FZF not found!!${RESET}"
            fi

            case "$selected" in
            "") ;; # Don't throw an exit error when we dont select anything
            *) "fzf-"$selected ;;
            esac
        }

        ##--> Enhanced Uninstall <--##
        function fzf-uninstall() {
            sudo -v &>/dev/null
            clear
            echo "${RED_FG}Uninstall Menu...${RESET}"
            pacman -Qq | fzf --multi --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns
            echo "${GREEN_BG}Uninstalled!${RESET}"
        }

        ##--> Enhanced rm <--##
        function fzf-rm() {
            if [[ "$#" -eq 0 ]]; then
                local files
                files=$(find . -maxdepth 1 -type f | fzf --multi)
                echo $files | xargs -I '{}' rm -rf {} #we use xargs so that filenames to capture filenames with spaces in them properly
            else
                command rm -rf "$@"
            fi
        }

        ##--> Man without options will use fzf to select a page <--##
        function fzf-man() {
            MAN="/usr/bin/man"
            if [ -n "$1" ]; then
                $MAN "$@"
                return $?
            else
                $MAN -k . | fzf --reverse --preview="echo {1,2} | sed 's/ (/./' | sed -E 's/\)\s*$//' | xargs $MAN" | awk '{print $1 "." $2}' | tr -d '()' | xargs -r $MAN
                return $?
            fi
        }

        ##--> fc-list with FZF <--##
        function fzf-fc() {
            fc-list |
                awk -F '[:,]' '{gsub("^ ", "", $2); print $2}' |
                sort |
                uniq |
                fzf |
                tr -d '\n' |
                xclip
        }

        ##--> Eval commands on the fly <--##
        function fzf-eval() {
            echo | fzf -q "$*" --preview-window=up:99% --preview="eval {q}"
        }

        ##--> Search list of your aliases and functions <--##
        function fzf-aliases-functions() {
            CMD=$(
                (
                    (alias)
                    (functions | grep "()" | cut -d ' ' -f1 | grep -v "^_")
                ) | fzf | cut -d '=' -f1
            )

            eval $CMD
        }

        ##--> File Finder (Open in $EDITOR) <--##
        function fzf-find-files() {
            local file=$(fzf --multi --reverse) # Get file from fzf
            if [[ $file ]]; then
                for prog in $( # Open all the selected files
                    echo $file
                ); do
                    $EDITOR $prog
                done
            else
                echo "${RED_FG}Cancelled FZF${RESET}"
            fi
        }

        ##--> Find Dirs <--##
        function fzf-cd() {
            local dir
            dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2>/dev/null | fzf +m) && cd "$dir"
            if [ $(command -v exa) ]; then
                clear && exa -al --color=always --icons --git --group-directories-first
            else
                command ls -al
            fi
        }

        ##--> Find Dirs (Hidden Included) <--##
        function fzf-cd-incl-hidden() {
            local dir
            dir=$(find ${1:-.} -type d 2>/dev/null | fzf +m) && cd "$dir"
            ls
        }

        ##--> CD into the directory of the selected file <--##
        function fzf-cd-to-file() {
            local file
            local dir
            file=$(fzf +m -q "$1") && dir=$(dirname "$file") && cd "$dir"
            ls
        }

        ##--> fdr - cd to selected parent directory <--##
        function fzf-cd-to-parent() {
            local declare dirs=()
            get_parent_dirs() {
                if [[ -d "${1}" ]]; then dirs+=("$1"); else return; fi
                if [[ "${1}" == '/' ]]; then
                    for _dir in "${dirs[@]}"; do echo $_dir; done
                else
                    get_parent_dirs $(dirname "$1")
                fi
            }
            local DIR=$(get_parent_dirs $(realpath "${1:-$PWD}") | fzf-tmux --tac)
            cd "$DIR"
            ls
        }

        ##--> Search ENV variables <--##
        function fzf-env-vars() {
            local out
            out=$(env | fzf)
            echo $(echo $out | cut -d= -f2)
        }

        ##--> Kill process using FZF <--##
        function fzf-kill-processes() {
            local pid
            pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')

            if [ "x$pid" != "x" ]; then
                echo $pid | xargs kill -${1:-9}
            fi
        }

        ##--> Enhanced Git Status (Open multiple files with tab + diff preview) <--##
        function fzf-git-status() {
            git rev-parse --git-dir >/dev/null 2>&1 || echo "You are not in a git repository" && return
            local selected
            selected=$(git -c color.status=always status --short |
                fzf --height 50% "$@" --border -m --ansi --nth 2..,.. \
                    --preview '(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500' |
                cut -c4- | sed 's/.* -> //')
            if [[ $selected ]]; then
                for prog in $(echo $selected); do $EDITOR $prog; done
            fi
        }

        ##--> tldr selection un=sing FZF <--##
        function fzf-tldr() {
            tldr --list | fzf --preview "tldr {1} --color=always" --preview-window=right,70% | xargs tldr
        }

        ##--> Checkout made more cool with fzf and tmux <--##
        function fzf-checkout() {
            if git rev-parse --git-dir >/dev/null 2>&1; then
                if [[ "$#" -eq 0 ]]; then
                    local branches branch
                    branches=$(git branch -a) &&
                        branch=$(echo "$branches" |
                            fzf-tmux -d $((2 + $(wc -l <<<"$branches"))) +m) &&
                        git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
                elif [ $(git rev-parse --verify --quiet $*) ] ||
                    [ $(git branch --remotes | grep --extended-regexp "^[[:space:]]+origin/${*}$") ]; then
                    echo "Checking out to existing branch"
                    git checkout "$*"
                else
                    echo "Creating new branch"
                    git checkout -b "$*"
                fi
            else
                echo "${RED_FG}Can't check out or create branch.${RESET} Not in a git repo"
            fi
        }

        ##--> Git Braches Selection <--##
        function fzf-git-branches() {
            if [ -d "./.git" ]; then
                git fetch
                selected_remote_branch=$(git branch -r | fzf | sed -e 's/^[[:space:]]*//')

                if [ -n "$selected_remote_branch" ]; then
                    selected_branch=$(echo "$selected_remote_branch" | sed -e 's/origin\///')

                    if git rev-parse --verify "$selected_branch"; then
                        git checkout "$selected_branch"
                    else
                        git checkout --track "$selected_remote_branch"
                    fi
                else
                    echo "Exit: You haven't selected a branch..."
                fi
            else
                echo -e "${RED_FG}Error:${RESET} There's no .git dir..."
                exit 1
            fi
        }
    fi

    function _fzf_compgen_dir() {
        fd --type d --hidden --follow --color=always --exclude ".git" --exclude ".hg" --exclude "node_modules" . "$1"
    }

    function _fzf_compgen_unalias() {
        tmpfile=$(mktemp /tmp/zsh-complete.XXXXXX)
        alias >"$tmpfile"
        fzf "$@" --preview 'ESCAPED=$(printf "%s=" {} | sed -e '"'"'s/[]\/$*.^[]/\\&/g'"'"'); cat '"$tmpfile"' | grep "^$ESCAPED"'
        rm "$tmpfile"
    }

    function _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
        cd) fzf "$@" --preview 'tree -C {} | head -200' ;;
        export | unset) fzf "$@" --preview "eval 'echo \$'{}" ;;
        ssh | telnet) fzf "$@" --preview 'echo {}' ;;
        unalias) _fzf_compgen_unalias "$@" ;;
        *) fzf "$@" ;;
        esac
    }

    ##--> FZF Defaults <--##
    export FZF_DEFAULT_OPTS="
--color fg:#d4d4d5
--color fg+:#f5c9c9
--color bg+:-1
--color hl:#0080ff
--color hl+:#FCE700
--color info:#79dcaa
--color prompt:#00788A
--color spinner:#3877ff
--color pointer:#d4d4d5
--color marker:#ffe59e
--color border:#101317
--color gutter:-1
--color info:#c397d8
--color header:#949494
--bind 'ctrl-j:preview-down'
--bind 'ctrl-k:preview-up'
--bind 'ctrl-a:select-all'
--bind 'ctrl-y:execute-silent(echo {+} | pbcopy)'
--bind 'ctrl-e:execute(echo {+} | xargs -o nvim)'
--bind 'ctrl-v:execute(code {+})'
--bind tab:down,shift-tab:up
--preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
--prompt '  '
--pointer ' '
--border none
--height 40"
    export FZF_DEFAULT_COMMAND='fd --hidden --follow'
fi

# vim:filetype=zsh
