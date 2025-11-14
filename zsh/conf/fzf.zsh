# ▄▀█ █ █ █ █▀▀ █▀ █▀█ █▀▄▀█ █▀▀ ▄▄ █▀▀ ▀█ █▀▀
# █▀█ ▀▄▀▄▀ ██▄ ▄█ █▄█ █ ▀ █ ██▄    █▀  █▄ █▀

if command -v fzf >/dev/null; then
    if [ $USE_FUNCTION = "Yes" ]; then

        AWESOME_FZF_LOCATION="$ZSH_PATH/zsh/conf/fzf.zsh"
        RED_FG=$(tput setaf 1)
        GREEN_BG=$(tput setab 2)
        RESET=$(tput sgr0)

        ##--> List Awesome FZF Functions <--##
        function fzf-awesome-list() {
            if [ -r $AWESOME_FZF_LOCATION ]; then
                selected=$(grep -E "(function fzf-)(.*?)[^(]*" $AWESOME_FZF_LOCATION | sed -e "s/^[ \t]*function fzf-//" | sed -e "s/() {//" | grep -v "selected=" | fzf --prompt="Awesome-FZF functions > ")
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
            clear
            echo "${RED_FG}Uninstall Menu...${RESET}"

            # Get a list of installed packages
            installed_packages=$(pacman -Qe | awk '{print $1}')

            # Prompt user to select packages to remove using fzf
            selected_packages=$(echo "$installed_packages" | fzf --multi --preview '')

            # Remove selected packages
            if [[ -n "$selected_packages" ]]; then
                echo "Removing selected packages:"
                echo "$selected_packages"
                sudo pacman -Rns $selected_packages
                echo "${GREEN_BG}Uninstalled!${RESET}"
            else
                echo "No packages selected."
            fi
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

    fw() {
        local projects=$HOME/Documents/Workspace

        if [[ ! -d $projects ]]; then
            echo -e "$projects dir does not exist"
            return 1
        fi

        local project=$(fd -t d --max-depth 1 . $projects | awk -F/ '{print $(NF-1)}' | fzf)

        [[ -z $project ]] && return

        cd $projects/$project
    }

    fenv () {
        local version=$(ll $HOME/.local/bin | grep python | awk '{print $11}' |
            fzf --delimiter='python' --with-nth=2
        )

        [[ -z $version ]] && return

        virtualenv .venv -p=$version
    }

    fdrc () {
        local containers=$(docker ps | tail -n +2 | awk '{print $1" "$NF}' | fzf -m | cut -d " " -f 1 | tr "\n" " ")

        [[ -z $containers ]] && return

        docker rm $(echo $containers) -f
    }

    fdri () {
        local images=$(docker images | tail -n +2 | awk '{print $1" "$3}' | fzf -m |  cut -d " " -f 2 | tr "\n" " ")

        [[ -z $images ]] && return

        docker rmi $(echo $images) -f
    }

    fpac () {
        pacman -Slq |
            fzf --multi --preview 'pacman -Si {1}' |
            xargs -ro sudo pacman -S
    }

    fapt () {
        apt list |
            fzf --multi --delimiter="/" --with-nth=1 --preview 'apt-cache policy {1}' |
            awk -F/ '{print $1}' |
            xargs -ro sudo apt-get install
    }

    fc () {
        local languages=(
            python
            go
            lua
        )

        local utils=(
            tar
            xargs
            awk
        )

        local selected=$(printf "$(echo $languages | tr ' ' '\n')\n$(echo $utils | tr ' ' '\n')" | fzf)

        echo -n "query: "
        read query

        if printf $languages | grep -qs $selected; then
            curl cht.sh/$selected/$(echo $query | tr ' ' '+')\?Q
        else
            curl cht.sh/$selected~$query\?Q
        fi
    }

    # Helpers
    is_in_git_repo() {
        git rev-parse --is-inside-work-tree > /dev/null 2>&1
    }

    fzf-down() {
        fzf --ansi --height 50% --min-height 20 \
            --bind ctrl-f:preview-down,ctrl-b:preview-up \
            --bind ctrl-p:toggle-preview $@
    }

        _pager='delta --side-by-side -w ${FZF_PREVIEW_COLUMNS:-$COLUMNS}'
        _format='%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an'

        # fuzzy git diff
        _gdNames="git diff --name-status | sed -E 's/^(.)[[:space:]]+(.*)$/[\1]  \2/'"
        _gdToFilename="echo {} | sed 's/.*]  //'"

    function gd () {
        is_in_git_repo || return

        # Diff files if passed as arguments
        [[ $# -ne 0 ]] && git diff $@ && return

        local repo preview
        repo=$(git rev-parse --show-toplevel)
        preview="$_gdToFilename | xargs -I % git diff $repo/% | $_pager"

        eval $_gdNames |
        fzf-down --no-sort --no-multi \
            --header 'enter to view' \
            --preview-window right:70% \
            --preview $preview \
            --bind "enter:execute:$preview | less -R" \
    }

    # fuzzy git add selector
    function ga() {
        is_in_git_repo || return 1

        # Add files if passed as arguments
        [[ $# -ne 0 ]] && git add $@ && return

        local changed unmerged untracked files opts preview extract
        changed=$(git config --get-color color.status.changed red)
        unmerged=$(git config --get-color color.status.unmerged red)
        untracked=$(git config --get-color color.status.untracked red)

        # NOTE: paths listed by 'git status -su' mixed with quoted and unquoted style
        # remove indicators | remove original path for rename case | remove surrounding quotes
        extract="
            sed 's/^.*]  //' |
            sed 's/.* -> //' |
            sed -e 's/^\\\"//' -e 's/\\\"\$//'"

        preview="
            file=\$(echo {} | $extract)
            if (git status -s -- \$file | grep '^??') &>/dev/null; then  # diff with /dev/null for untracked files
            git diff --color=always --no-index -- /dev/null \$file | $_pager | sed '2 s/added:/untracked:/'
            else
            git diff --color=always -- \$file | $_pager
            fi"

        files=$(git -c color.status=always -c status.relativePaths=true status -su |
            sed -E 's/^(..[^[:space:]]*)[[:space:]]+(.*)$/[\1]  \2/' |
            fzf-down -0 --multi \
            --header 'enter to add' \
            --preview-window right:70% --preview $preview |
            sh -c $extract)

        [[ -n $files ]] && echo $files | tr '\n' '\0' | xargs -0 -I % git add % && return

        echo 'Nothing to add.'
    }


    # fuzzy git reset HEAD (unstage) selector
    _gdCached="git diff --cached"
    _gdCachedDiff="$_gdCached --color=always -- {} | $_pager"

    function gr () {
        is_in_git_repo || return 1

        # Reset files if passed as arguments
        [[ $# -ne 0 ]] && git reset -q HEAD $@ && return

        files=$(eval "$_gdCached --name-only --relative" |
            fzf-down -0 --multi \
            --header 'enter to reset' \
            --preview-window right:70% --preview $_gdCachedDiff
        )

        [[ -n $files ]] && echo $files | tr '\n' '\0' | xargs -0 -I % git reset -q HEAD % && return

        echo 'Nothing to unstage.'
    }

    # fuzzy git cherry pick
    function gcp () {
        is_in_git_repo || return 1

        [[ -z $1 ]] && echo "Please specify target branch" && return 1

        # Cherry pick if commit hash is passed
        [[ $# > 1 ]] && { git cherry-pick ${@:2}; return $?; }

        local base target preview
        base=$(git branch --show-current)
        target=$1
        preview="echo {1} | xargs -I % git show --color=always % | $_pager"

        git cherry $base $target --abbrev -v | cut -d ' ' -f2- |
            fzf-down -0 --multi \
            --header 'enter to cherry pick' \
            --preview-window right:70% --preview $preview |
            cut -d' ' -f1 | xargs -I % git cherry-pick %
    }

    # fuzzy git branch delete
    _glGraphDelete="git log -n 50 --graph --color=always --format=\"$_format\" {}"

    function gbd () {
        is_in_git_repo || return 1

        git branch --sort=-committerdate |
            grep --invert-match '\*' |
            cut -c 3- |
            fzf-down --multi \
            --header "enter to delete" \
            --preview-window right:70% --preview $_glGraphDelete |
            xargs --no-run-if-empty git branch --delete --force
    }

    # fuzzy git commit browser with previews and vim integration
    _glNoGraph="git log --color=always --format=\"$_format\""
    _gitLogLineToHash="echo {} | grep -o '[a-f0-9]\{7\}' | head -1"
    _viewGitLogLine="$_gitLogLineToHash | xargs -I % git show --color=always % | $_pager"
    _viewGitLogLineUnfancy="$_gitLogLineToHash | xargs -I % git show %"

    function glog() {
        is_in_git_repo || return 1

        eval $_glNoGraph |
        fzf-down --no-sort --reverse --tiebreak=index --no-multi \
            --header 'enter to view, ctrl-v to open in vim' \
            --preview-window right:70% \
            --preview $_viewGitLogLine \
            --bind "enter:execute:$_viewGitLogLine | less -R" \
            --bind "ctrl-v:execute:$_viewGitLogLineUnfancy | $EDITOR -"
    }

    # fgs - easier way to deal with stashes
    # type fgs to get a list of your stashes
    # enter shows you the contents of the stash
    # ctrl-d shows a diff of the stash against your current HEAD
    # ctrl-o pops a stash
    # ctrl-y applies a stash
    # ctrl-x dropss a stash
    _gsStashShow='git stash show --color=always -p $(cut -d" " -f1 <<< {})'
    _gsStashShowFancy="$_gsStashShow | $_pager"
    _gsDiff='git diff --color=always $(cut -d" " -f1 <<< {})'

    function gs() {
        is_in_git_repo || return 1

        local out k reflog

        out=(
            $(git stash list --pretty='%C(yellow)%gd %>(14)%Cgreen%cr %C(blue)%gs' |
            fzf-down --no-sort --reverse --no-multi \
                --header 'enter to show, ctrl-d to diff, ctrl-o to pop, ctrl-y to apply, ctrl-x to drop' \
                --preview-window right:70% \
                --preview $_gsStashShowFancy \
                --bind "enter:execute:$_gsStashShowFancy | less -R > /dev/tty" \
                --bind "ctrl-d:execute:$_gsDiff | $_pager | less -R > /dev/tty" \
                --expect=ctrl-o,ctrl-y,ctrl-x
            )
        )

        k=${out[1]}
        reflog=${out[2]}

        [ -n $reflog ] && case $k in
            ctrl-o) git stash pop $reflog ;;
            ctrl-y) git stash apply $reflog ;;
            ctrl-x) git stash drop $reflog ;;
        esac
    }

    # fuzzy git checkout file
    function gcf() {
        is_in_git_repo || return 1

        [[ $# -ne 0 ]] && { git checkout -- $@; return $?; }

        local cmd files
        cmd="git diff --color=always -- {} | $_pager"

        files=$(
            git ls-files --modified $(git rev-parse --show-toplevel) |
            fzf-down -0 --multi \
            --header 'enter to checkout' \
            --preview-window right:70% --preview $cmd
        )

        [[ -n $files ]] && echo $files | tr '\n' '\0' | xargs -0 -I % git checkout %
    }

    # fuzzy git checkout branch
    _glGraph='git log -n 50 --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr% C(auto)%an" $(sed s/^..// <<< {} | cut -d" " -f1)'

    function gco() {
        is_in_git_repo || return 1

        [[ $# -ne 0 ]] && { git checkout $@; return $?; }

        local branch=$(
            git branch --all --sort=-committerdate | grep -v HEAD |
            fzf-down --no-multi \
            --header 'enter to checkout' \
            --preview-window right:70% --preview $_glGraph
        )

        [[ -z $branch ]] && return 1

        git checkout $(echo $branch | sed "s/.* //")
    }

    # fuzzy git checkout branch
    function gcb () {
        is_in_git_repo || return 1

        [[ $# -ne 0 ]] && { git checkout -b $@; return $?; }

        local cmd preview branch
        cmd="git branch --all --sort=-committerdate | grep -v HEAD"
        preview="git log {1} -n 50 --graph --pretty=format:'$_format' --color=always --abbrev-commit --date=relative"

        branch=$(
            eval $cmd |
            fzf-down --no-sort --no-multi --tiebreak=index \
            --header 'enter to checkout' \
            --preview-window right:70% \
            --preview $preview | awk '{print $1}'
        )

        [[ -z $branch ]] && return 1

        # track the remote branch if possible
        if ! git checkout --track $branch 2>/dev/null; then
            git checkout $branch
        fi
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

    # Smart file finder with ripgrep content preview
    if command -v rg &> /dev/null; then
        export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*" --glob "!node_modules/*"'
    elif command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'
    else
        export FZF_DEFAULT_COMMAND='find . -type f'
    fi
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    fi

    # Enhanced file preview with syntax highlighting
    export FZF_CTRL_T_OPTS="
    --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {} 2>/dev/null || tree -C {} 2>/dev/null'
    --bind 'ctrl-/:toggle-preview'
    "

    # Enhanced directory search
    export FZF_ALT_C_OPTS="
    --preview 'eza --tree --color=always {} | head -200'
    "
fi

# vim:filetype=zsh
