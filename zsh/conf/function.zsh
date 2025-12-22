# ------------------------[  ZSH FUNCTIONS CONFIGURATION  ]------------------------ #
# This file defines custom shell functions and utilities.
# Works on: Arch Linux & macOS
#
# NOTE: To disable functions, set USE_FUNCTION="No" in ~/.zshenv


# ........................[  1. Initialization  ]........................ #

# Exit if functions are disabled in config
[[ "$USE_FUNCTION" != "Yes" ]] && return

# Load FZF integration if available
[ -f "$ZSH_PATH/zsh/conf/fzf.zsh" ] && source "$ZSH_PATH/zsh/conf/fzf.zsh" &> /dev/null

# ---------------------------------------------------------
#  HELPER: Global Installation Check (Cached)
#  Usage: is_installed <program_name>
#  Coming from env.zsh
# ---------------------------------------------------------

# ........................[  2. Core Overrides & Wrappers  ]........................ #

safe_rm() {
    local flags=""
    local -a targets

    # Separate actual files/dirs from flags
    for arg in "$@"; do
        if [[ "$arg" == -* ]]; then
            flags="$flags $arg"
        else
            targets+=("$arg")
        fi
    done

    if [[ ${#targets[@]} -eq 0 ]]; then
        command rm $flags
        return
    fi

    for target in "${targets[@]}"; do
        if [[ "$target" == "/" || "$target" == "$HOME" ]]; then
            echo "Error: Protected path '$target'. Operation aborted." >&2
            return 1
        fi

        if [[ -d "$target" ]]; then
            echo -n ":: Directory detected: '$target'. Remove recursively? [y/N] "
            local confirm
            if [ -n "$ZSH_VERSION" ]; then
                read -k 1 confirm; echo
            else
                read -n 1 confirm; echo
            fi

            if [[ "$confirm" =~ ^[yY]$ ]]; then
                command rm -rf $flags "$target"
                echo "   Deleted '$target'."
            else
                echo "   Skipped."
            fi
        else
            command rm $flags "$target"
        fi
    done
}

v() {
    local app_name=""
    local use_sudo="no"
    local file="${1:-.}"

    if [[ "$MULTI_NEOVIM" == "Yes" ]]; then
        case "$1" in
            -a | --astro)  app_name="AstroNvim" ;;
            -l | --lazy)   app_name="LazyVim"   ;;
            -c | --chad)   app_name="NvChad"    ;;
            -n | --nv)     app_name="LazyNV"    ;;
        esac

        if [[ -n "$app_name" ]]; then
            shift
            file="${1:-.}"
        fi
    fi

    if [[ -e "$file" && ! -w "$file" ]]; then
        use_sudo="yes"
    elif [[ ! -e "$file" ]]; then
        local parent=$(dirname "$file")
        [[ -d "$parent" && ! -w "$parent" ]] && use_sudo="yes"
    fi

    if [[ "$use_sudo" == "yes" ]]; then
        if [[ -n "$app_name" ]]; then
            echo ":: Opening with sudo ($app_name)..."
            sudo -E env NVIM_APPNAME="$app_name" nvim "$@"
        else
            echo ":: Opening with sudo..."
            sudoedit "$@"
        fi
    else
        [[ -n "$app_name" ]] && export NVIM_APPNAME="$app_name"
        nvim "$@"
    fi
}


# ........................[  3. File & Directory Operations  ]........................ #

mkfile() {
    if [[ $# -eq 0 ]]; then
        echo "Usage: mkfile <path/to/file>" >&2
        return 1
    fi

    for file in "$@"; do
        mkdir -p "$(dirname "$file")"
        if touch "$file"; then
            echo ":: Created: $file"
        else
            echo "Error: Failed to create '$file'" >&2
        fi
    done
}

mkcd() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        echo "Usage: mkcd <directory>" >&2
        return 1
    fi

    if mkdir -p "$dir" && cd "$dir"; then
        echo ":: Created and entered: $(pwd)"
    else
        echo "Error: Could not create directory '$dir'" >&2
        return 1
    fi
}

take() {
    local source="$1"
    local target="$2"
    local protocol_regex='^(https?|git|ssh|ftps?|rsync)://|^[a-zA-Z0-9]+@'

    if [[ "$source" =~ $protocol_regex ]]; then
        if [[ -z "$target" ]]; then
            target=$(basename "${source%%.git}")
        fi
        git clone "$source" "$target" && cd "$target"
    else
        target="$source"
        mkdir -p "$target" && cd "$target"
    fi
}

up() {
    local levels="${1:-1}"
    if [[ ! "$levels" =~ ^[0-9]+$ ]]; then
        echo "Error: Argument must be a number." >&2
        return 1
    fi

    local d=""
    for ((i = 1; i <= levels; i++)); do
        d="../$d"
    done

    if cd "$d"; then
        echo ":: Now at $(pwd)"
    else
        echo "Error: Could not go up $levels directories." >&2
        return 1
    fi
}

extract() {
    local file="$1"
    if [[ -z "$file" ]] || [[ ! -f "$file" ]]; then
        echo "Error: '$file' is not a valid file." >&2
        return 1
    fi

    echo ":: Extracting '$file'..."

    case "$file" in
        *.tar.bz2|*.tbz2)   tar xjf "$file"    ;;
        *.tar.gz|*.tgz)     tar xzf "$file"    ;;
        *.tar.xz|*.txz)     tar xf  "$file"    ;;
        *.tar.zst)          tar --zstd -xf "$file" 2>/dev/null || tar -I zstd -xf "$file" ;;
        *.tar)              tar xf  "$file"    ;;
        *.rar)              unrar x "$file"    ;;
        *.zip)              unzip   "$file"    ;;
        *.7z)               7z x    "$file"    ;;
        *.bz2)              bunzip2 "$file"    ;;
        *.gz)               gunzip  "$file"    ;;
        *.xz)               unxz    "$file"    ;;
        *.Z)                uncompress "$file" ;;
        *)
            echo "Error: '$file' cannot be extracted." >&2
            return 1
            ;;
    esac
}

dir_usage() {
    # Optimized: We store the preferred flags in a global variable so we don't
    # check `du` capabilities every time the function runs.
    if [[ -z "$_DU_OPTS" ]]; then
        if du -b /dev/null >/dev/null 2>&1; then
            _DU_OPTS="-sbh" # GNU/Linux
        else
            _DU_OPTS="-sh"  # macOS/BSD
        fi
    fi

    if [[ -n "$@" ]]; then
        du $_DU_OPTS -- "$@" | sort -rh
    else
        du $_DU_OPTS .[^.]* ./* 2>/dev/null | sort -rh
    fi
}

sort_uniq() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found." >&2
        return 1
    fi

    mv "$file" "$file.bak" && \
    sort "$file.bak" | uniq > "$file" && \
    rm "$file.bak" && \

    echo ":: Sorted and removed duplicates from '$file'."
}

rm_pattern() {
    local pattern="$1"
    if [[ -z "$pattern" ]]; then
        echo "Usage: rm_pattern <filename_pattern>" >&2
        return 1
    fi

    echo ":: Searching for files named '$pattern'..."
    local files_found=$(find . -type f -name "$pattern" -print)

    if [[ -z "$files_found" ]]; then
        echo "No files found matching '$pattern'."
        return 0
    fi

    echo "$files_found"
    echo ""
    echo -n ":: Delete these files? [y/N] "

    local confirm
    if [ -n "$ZSH_VERSION" ]; then
        read -q confirm; echo ""
    else
        read -n 1 confirm; echo ""
    fi

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        find . -type f -name "$pattern" -delete
        echo ":: Deleted."
    else
        echo ":: Aborted."
    fi
}

empty_trash() {
    local trash_dir=""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        trash_dir="$HOME/.Trash"
    else
        trash_dir="${XDG_DATA_HOME:-$HOME/.local/share}/Trash"
    fi

    if [[ ! -d "$trash_dir" ]]; then
        echo ":: Trash directory not found at: $trash_dir"
        return 0
    fi

    if [[ -z "$(ls -A "$trash_dir" 2>/dev/null)" ]]; then
        echo ":: Trash is already empty."
        return 0
    fi

    echo ":: Inspecting trash..."
    local size=$(du -sh "$trash_dir" 2>/dev/null | awk '{print $1}')

    echo -n ":: Empty trash and reclaim $size? [y/N] "

    local confirm
    if [ -n "$ZSH_VERSION" ]; then
        read -q confirm; echo ""
    else
        read -n 1 confirm; echo ""
    fi

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        if [[ "$OSTYPE" != "darwin"* ]]; then
            rm -rf "${trash_dir}/files/"* "${trash_dir}/info/"* 2>/dev/null
        else
            rm -rf "${trash_dir}/"* 2>/dev/null
        fi
        echo ":: Trash emptied. Reclaimed $size."
    else
        echo ":: Aborted."
    fi
}


# ........................[  4. Developer Tools  ]........................ #

run_code() {
    local file="$1"
    if [[ -z "$file" ]] || [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found." >&2
        return 1
    fi

    shift
    local base="${file%.*}"
    local tmp_bin="./.tmp_exec_${base}"

    echo ":: Running '$file'..."

    case "$file" in
        *.cpp)  g++ -std=c++20 "$file" -o "$tmp_bin" && "$tmp_bin" "$@" && rm -f "$tmp_bin" ;;
        *.c)    gcc "$file" -o "$tmp_bin" && "$tmp_bin" "$@" && rm -f "$tmp_bin" ;;
        *.rs)   rustc "$file" -o "$tmp_bin" && "$tmp_bin" "$@" && rm -f "$tmp_bin" ;;
        *.go)   go run "$file" "$@" ;;
        *.java) javac "$file" && java "$base" "$@" && rm -f "${base}.class" ;;
        *.py)   python3 "$file" "$@" ;;
        *.sh)   bash    "$file" "$@" ;;
        *.pl)   perl    "$file" "$@" ;;
        *.rb)   ruby    "$file" "$@" ;;
        *.js)   node    "$file" "$@" ;;
        *.ts)   ts-node "$file" "$@" ;;
        *.php)  php     "$file" "$@" ;;
        *.lua)  lua     "$file" "$@" ;;
        *.md)   glow    "$file" ;;
        *)
            echo "Error: '$file' format not supported by run_code()." >&2
            return 1
            ;;
    esac
}

mkrepo() {
    local remote_url="$1"

    if [[ -d ".git" ]]; then
        echo "Error: This directory is already a git repository." >&2
        return 1
    fi

    echo ":: Initializing Git repository..."
    git init --quiet

    if [[ ! -f "README.md" ]]; then
        echo "# $(basename "$PWD")" > README.md
    fi

    if [[ ! -f ".gitignore" ]]; then
        printf ".DS_Store\n.vscode/\n*.log\nnode_modules/\n__pycache__/\n" > .gitignore
    fi

    git branch -m main 2>/dev/null || git checkout -b main 2>/dev/null
    git add .
    git commit -m "Initial Commit" --quiet
    echo ":: Committed files."

    if [[ -n "$remote_url" ]]; then
        echo ":: Linking to remote: $remote_url"
        git remote add origin "$remote_url"
        if git push -u origin main; then
            echo ":: 🚀 Repository is live!"
        else
            echo "Error: Failed to push to remote. Check URL or Authentication." >&2
            return 1
        fi
    else
        echo ":: Repo initialized locally. (Add remote later via 'git remote add origin <url>')"
    fi
}

glog() {
    if ! is_installed fzf; then echo "Error: 'fzf' is not installed." >&2; return 1; fi
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then echo "Error: Not a git repository." >&2; return 1; fi

    local fmt="%C(auto)%h%d %C(blue)%an %C(reset)%s %C(black)%C(bold)%cr"
    local get_hash="grep -o '[a-f0-9]\{7,\}' | head -1"

    # --- Cached Clipboard Detection ---
    local copy_cmd=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        copy_cmd="pbcopy"
    else
        if is_installed wl-copy; then copy_cmd="wl-copy"
        elif is_installed xclip; then copy_cmd="xclip -sel c"
        elif is_installed xsel; then copy_cmd="xsel -ib"
        fi
    fi

    git log --graph --color=always --format="$fmt" "$@" | \
    fzf --ansi --no-sort --reverse --tiebreak=index \
        --preview "echo {} | $get_hash | xargs -I % git show --color=always %" \
        --preview-window=right:60%:wrap \
        --bind "enter:execute(echo {} | $get_hash | xargs -I % sh -c 'git show --color=always % | less -R')" \
        --bind "ctrl-y:execute-silent(echo {} | $get_hash | tr -d '\n' | $copy_cmd)+abort" \
        --header "Enter: View | Ctrl-Y: Copy Hash"
}

# --- Lazygit Wrapper (Startup Optimized) ---
# Removed the top-level 'if command -v lazygit' check to save load time.
# The check now happens only when you run 'lg'.
lg() {
    if ! is_installed lazygit; then
        echo "Error: 'lazygit' is not installed." >&2
        return 1
    fi

    local lg_config_file="${TMPDIR:-/tmp}/lazygit-chdir"
    LAZYGIT_NEW_DIR_FILE="$lg_config_file" command lazygit "$@"

    if [[ -f "$lg_config_file" ]]; then
        local target_dir=$(cat "$lg_config_file")
        if [[ -d "$target_dir" && "$target_dir" != "$PWD" ]]; then
            cd "$target_dir"
            echo ":: Switched to: $target_dir"
        fi
        rm -f "$lg_config_file"
    fi
}


# ........................[  5. Utilities & Stats  ]........................ #

stopwatch() {
    local start=$(date +%s)
    printf "\e[?25l"
    trap 'printf "\e[?25h\n"; return' INT

    while true; do
        local now=$(date +%s)
        local diff=$((now - start))

        local h=$((diff / 3600))
        local m=$(( (diff % 3600) / 60 ))
        local s=$((diff % 60))

        printf "\r\e[K  %02d:%02d:%02d" $h $m $s
        sleep 0.1
    done
}


countdown() {
    local total_seconds=0

    if [[ $# -eq 0 ]]; then
        total_seconds=60
    else
        for arg in "$@"; do
            case "$arg" in
                *h) total_seconds=$((total_seconds + ${arg%h} * 3600)) ;;
                *m) total_seconds=$((total_seconds + ${arg%m} * 60)) ;;
                *s) total_seconds=$((total_seconds + ${arg%s})) ;;
                *[0-9]*) total_seconds=$((total_seconds + arg)) ;;
                *) echo "Error: Unknown format '$arg'." >&2; return 1 ;;
            esac
        done
    fi

    if (( total_seconds <= 0 )); then echo "Error: Time must be > 0." >&2; return 1; fi

    local start=$(date +%s)
    local end=$((start + total_seconds))

    printf "\e[?25l"
    trap 'printf "\e[?25h\n"; return' INT
    echo ":: Timer started for ${total_seconds} seconds..."

    while (( $(date +%s) < end )); do
        local now=$(date +%s)
        local left=$((end - now))
        local h=$((left / 3600))
        local m=$(( (left % 3600) / 60 ))
        local s=$((left % 60))

        printf "\r\e[K  %02d:%02d:%02d" $h $m $s
        sleep 0.1
    done

    printf "\r\e[K  00:00:00\n"
    printf "\e[?25h\a"
    echo ":: Time is up!"
}

weather() {
    curl -s "wttr.in/${1:-}?mQ"
}

hist_stats() {
    fc -l 1 | awk '{
        cmd = $2
        if (cmd == "sudo") cmd = $3
        if (cmd !~ /^(\.\/|[A-Z]+=)/ && cmd != "") {
            CMD[cmd]++
            count++
        }
    }
    END {
        for (a in CMD) print CMD[a] " " a " " count
    }' | \
    sort -nr | head -15 | \
    awk '{
        count = $1; cmd = $2; total = $3
        percent = (count / total) * 100
        bar_len = int(percent / 2)
        bar = ""; for (i=0; i<bar_len; i++) bar = bar "▇"
        printf "%4d  %5.1f%%  %-12s  %s\n", count, percent, cmd, bar
    }'
}


# ........................[  6. Miscellaneous  ]........................ #

zconf() {
    local config_file="${ZDOTDIR:-$HOME}/.zshrc"
    local editor="${EDITOR:-${VISUAL:-vim}}"

    if [[ ! -f "$config_file" ]]; then
        echo "Error: Configuration file not found at $config_file" >&2
        return 1
    fi

    echo ":: Opening config with $(basename "$editor")..."
    if "$editor" "$config_file"; then
        echo ":: Reloading Zsh configuration..."
        source "$config_file" && echo ":: 🚀 Configuration updated successfully."
    else
        echo ":: Edit aborted."
    fi
}

matrix() {
    trap 'printf "\e[?25h\e[0m"; clear; return' INT
    printf "\e[?25l"
    clear

    while :; do
        read -s -k 1 -t 0.05 key < /dev/tty 2>/dev/null
        if [[ "$key" == "q" ]]; then break; fi
        echo
    done | awk -v lines="$(tput lines)" -v cols="$(tput cols)" '
    BEGIN {
        srand();
        chars = "ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍ0123456789:・.=*+-<>";
        len_chars = length(chars);
        for (c = 1; c <= cols; c++) {
            y[c] = -1 * int(rand() * 50);
            l[c] = int(rand() * 15) + 5;
        }
    }
    {
        for (c = 1; c <= cols; c++) {
            if (y[c] > lines + l[c] || (y[c] < 0 && rand() < 0.02)) {
                y[c] = 0;
                l[c] = int(rand() * 15) + 5;
            }
            if (y[c] >= 0) {
                if (y[c] - l[c] > 0 && y[c] - l[c] <= lines) {
                    printf "\033[%d;%dH ", y[c] - l[c], c;
                }
                if (y[c] > 0 && y[c] <= lines) {
                    r_char = substr(chars, int(rand() * len_chars) + 1, 1);
                    printf "\033[%d;%dH\033[32m%s", y[c], c, r_char;
                }
                if (y[c] + 1 > 0 && y[c] + 1 <= lines) {
                    r_char_head = substr(chars, int(rand() * len_chars) + 1, 1);
                    printf "\033[%d;%dH\033[1;37m%s", y[c] + 1, c, r_char_head;
                }
                y[c]++;
            } else {
                y[c]++;
            }
        }
        fflush();
    }'

    printf "\e[?25h\e[0m"
    clear
}

# vim:filetype=zsh
