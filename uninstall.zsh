#!/usr/bin/env zsh

# ------------------------[  ZSH CONFIGURATION UNINSTALLER  ]------------------------ #
# This script removes the custom Zsh configuration, symlinks, and plugins.
#
# ARCHITECTURE (Object-Based):
#   1. Theme::        -> Colors, Icons, and visual constants.
#   2. Config::       -> Paths to target for deletion.
#   3. UI::           -> Visual components (Spinner, Header, Confirm).
#   4. Log::          -> Standardized output wrappers.
#   5. Cleaner::      -> Removal logic (The "Business Logic").
#   6. Uninstaller::  -> Main orchestration.


# ........................[  1. Class: Theme  ]........................ #
# Responsible for defining the visual palette and symbols.

typeset -A Color
typeset -A Icon

Theme::init() {
    # Palette
    Color[R]=$(tput setaf 203) # Red
    Color[G]=$(tput setaf 156) # Green
    Color[Y]=$(tput setaf 220) # Yellow
    Color[B]=$(tput setaf 111) # Blue
    Color[P]=$(tput setaf 176) # Purple
    Color[C]=$(tput setaf 14)  # Cyan
    Color[W]=$(tput setaf 255) # White
    Color[K]=$(tput setaf 240) # Gray
    Color[Bld]=$(tput bold)
    Color[Rst]=$(tput sgr0)

    # Icons
    Icon[OK]="${Color[G]}${Color[Rst]}"
    Icon[ERR]="${Color[R]}${Color[Rst]}"
    Icon[WARN]="${Color[Y]}${Color[Rst]}"
    Icon[Q]="${Color[P]}${Color[Rst]}"
    Icon[INFO]="${Color[B]}${Color[Rst]}"
    Icon[TRASH]="${Color[R]}${Color[Rst]}"
}


# ........................[  2. Class: Config  ]........................ #
# Holds the paths of artifacts to look for and remove.

typeset -A Paths
typeset -a PluginDirs

Config::init() {
    Paths[REPO]="$HOME/.config/zsh-conf"
    Paths[RC]="${ZDOTDIR:-$HOME}/.zshrc"
    Paths[ENV]="${ZDOTDIR:-$HOME}/.zshenv"
    Paths[TEMP]="$HOME/User-Overrides.zsh"
    Paths[CACHE]="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-cache"

    # Plugin Managers installed by plugs.zsh
    PluginDirs=(
        "$HOME/.zinit"
        "$HOME/.oh-my-zsh"
        "$HOME/.local/share/zap"
    )
}


# ........................[  3. Class: Log  ]........................ #
# Encapsulates all printing logic.

Log::info() {
    printf "  %s  %s%s%s\n" "${Icon[INFO]}" "${Color[B]}" "$1" "${Color[Rst]}"
}

Log::success() {
    printf "  %s  %s%s%s\n" "${Icon[OK]}" "${Color[G]}" "$1" "${Color[Rst]}"
}

Log::warn() {
    printf "  %s  %s%s%s\n" "${Icon[WARN]}" "${Color[Y]}" "$1" "${Color[Rst]}"
}

Log::error() {
    printf "  %s  %s%s%s\n" "${Icon[ERR]}" "${Color[R]}" "$1" "${Color[Rst]}"
}

Log::delete() {
    printf "  %s  %s%s%s\n" "${Icon[TRASH]}" "${Color[R]}" "$1" "${Color[Rst]}"
}

Log::backup() {
    printf "  %s  %s%s%s\n" "${Icon[OK]}" "${Color[C]}" "$1" "${Color[Rst]}"
}

# ........................[  4. Class: UI  ]........................ #
# Handles user interaction widgets.

UI::typewriter() {
    local text="$1"
    local delay=0.02
    for ((i = 0; i < ${#text}; i++)); do
        printf "%s" "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

UI::confirm() {
    printf "  %s  %s ${Color[K]}[y/N]${Color[Rst]} " "${Icon[Q]}" "$1"
    read -k 1 -r response
    echo ""
    [[ "$response" =~ ^[yY]$ ]]
}

UI::spinner() {
    local pid=$1
    local msg="$2"
    # MacOS/BSD 'sleep' does not support fractional seconds in older versions,
    # but modern macOS does. If issues arise, use 1 (though animation will be slow).
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    # Ensure cursor is visible on exit (even if crashed)
    trap "tput cnorm; exit" SIGINT SIGTERM

    tput civis # Hide cursor
    while kill -0 "$pid" 2>/dev/null; do
        # Extract the first character of spinstr
        local temp=${spinstr:0:1}
        # Print: Cyan spinner + standard text
        printf "\r  ${Color[C]}%s${Color[Rst]}  %s" "$temp" "$msg"
        # Rotate string
        spinstr=${spinstr:1}${spinstr:0:1}
        sleep $delay
    done

    # Final cleanup
    printf "\r\033[K" # Clear line
    tput cnorm # Restore cursor
    trap - SIGINT SIGTERM # Reset trap
}


UI::header() {
    sleep 2
    clear
    echo "${Color[R]}"
    echo "  ▒███████▒  ██████  ██░ ██  ▄████▄   ▒█████   ███▄    █   █████▒"
    echo "  ▒ ▒ ▒ ▄▀░▒██    ▒ ▓██░ ██▒▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █ ▓██   ▒ "
    echo "  ░ ▒ ▄▀▒░ ░ ▓██▄   ▒██▀▀██░▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒▒████ ░ "
    echo "    ▄▀▒   ░  ▒   ██▒░▓█ ░██ ▒▓▓▄ ▄██▒▒██   ██ ▓██▒  ▐▌██▒ ▓█▒  ░ "
    echo "  ▒███████▒▒██████▒▒░▓█▒░██▓▒ ▓███▀ ░░ ████▓▒ ▒██░   ▓██. ▒█░   "
    echo "  ░▒▒ ▓░▒░▒▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒  ▒ ░    "
    echo "   ░░▒ ▒ ░ ▒░ ░▒  ░ ░ ▒ ░▒░ ░  ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░ ░      "
    echo "   ░ ░ ░ ░ ░░  ░  ░   ░  ░░ ░░        ░ ░ ░ ▒     ░   ░ ░  ░ ░     "
    echo "     ░ ░          ░   ░  ░  ░░ ░          ░ ░           ░           "
    echo "${Color[Rst]}"
    echo "                 ${Color[K]}>> ZSH CONFIGURATION CLEANUP <<${Color[Rst]}"
    echo ""
}


# ........................[  5. Class: Cleaner  ]........................ #
# Logic for removing files and directories.

Cleaner::remove_symlinks() {
    local link="$1"
    # Check if it is actually a symlink
    if [[ -L "$link" ]]; then
        # Check if it points to our repo
        local target=$(readlink "$link")
        if [[ "$target" == *"${Paths[REPO]}"* ]]; then
            rm "$link"
            Log::delete "Removed Symlink: $link"
        else
            Log::warn "Skipping $link (Points to $target. Remove it manually!)"
        fi
    # 2. Check if it is a Real File (Backup it)
    elif [[ -f "$link" ]]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local backup_name="${link}.bak_${timestamp}"

        mv "$link" "$backup_name"
        Log::backup "Regular file found. Backed up to: $(basename "$backup_name")"

    # 3. Not found
    else
        Log::info "File not found: $link (Already clean)"
    fi
    sleep 3
}

Cleaner::remove_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        Log::delete "Removed Directory: $dir"
    fi
    sleep 2
}

Cleaner::remove_cache() {
    {
        # Remove compiled zsh files and caches
        command rm -rf "${Paths[CACHE]}"
        command find "$HOME" -name ".zcompdump*" -delete 2>/dev/null
        command find "$HOME" -name "*.zwc" -delete 2>/dev/null
    } &

    UI::spinner $! "Cleaning Cache..."
    wait $!
    Log::delete "Cleared Zsh caches and compdumps"
}

Cleaner::restore_shell() {
    if [[ $SHELL == "/usr/bin/zsh" ]] || [[ $SHELL == "/bin/zsh" ]]; then
        if command -v bash &>/dev/null; then
            if UI::confirm "Switch default shell back to Bash?"; then
                chsh -s $(which bash)
                Log::success "Default shell set to Bash."
            fi
        else
            Log::warn "Bash not found. Skipping shell switch."
        fi
    fi
}


# ........................[  6. Class: Uninstaller  ]........................ #
# Main controller containing business logic.

Uninstaller::run() {
    # 1. Init
    Theme::init
    Config::init
    UI::header

    UI::typewriter "  :: Initializing cleanup sequence..." "${Color[R]}"
    sleep 1
    printf "\n"

    Log::warn "This will remove your Zsh configuration and plugins."
    Log::warn "It will NOT uninstall system packages (tmux, fzf, etc)."
    echo
    sleep 1

    if ! UI::confirm "Are you sure you want to proceed?"; then
        Log::info "Aborted by user."
        echo
        exit 0
    fi

    # 2. Remove Symlinks
    UI::header
    Log::info "Removing Configuration Links..."
    sleep 1
    Cleaner::remove_symlinks "${Paths[RC]}"
    Cleaner::remove_symlinks "${Paths[ENV]}"
    Cleaner::remove_symlinks "${Paths[TEMP]}"

    # 3. Remove Repository
    UI::header
    Log::info "Removing Configuration Repository..."
    sleep 2
    if [[ -d "${Paths[REPO]}" ]]; then
        Cleaner::remove_dir "${Paths[REPO]}"
    else
        Log::info "Repository not found (Already removed?)"
    fi

    # 4. Remove Plugin Managers
    UI::header
    Log::info "Removing Plugin Managers..."
    sleep 2
    local plugins_found=0
    for dir in "${PluginDirs[@]}"; do
        if [[ -d "$dir" ]]; then
            ((plugins_found++))
            if UI::confirm "Remove plugin manager at $dir?"; then
                 Cleaner::remove_dir "$dir"
            else
                 Log::info "Skipped $dir"
            fi
        fi
    done
    [[ $plugins_found -eq 0 ]] && Log::info "No active plugin managers found."
    sleep 2

    # 5. Clear Cache
    UI::header
    Cleaner::remove_cache

    # 6. Restore Shell
    UI::header
    Cleaner::restore_shell

    # 7. Finalize
    UI::header
    Log::success "Uninstallation complete."
    echo
    sleep 2

    # Check for backups to remind user
    local backup_count=$(ls -1 "$HOME" | grep ".zshrc_" | wc -l)
    if [[ $backup_count -gt 0 ]]; then
        Log::info "Note: You have $backup_count backup(s) of .zshrc in $HOME."
        Log::info "You may want to manually restore one: 'mv .zshrc_DATE .zshrc'"
        sleep 2
    fi

    Log::info "Please restart your terminal."
    echo
    sleep 2

    # FORCE EXIT to prevent any re-execution loop
    exit 0
}


# ........................[  7. Entry Point  ]........................ #

# Only run if this file is the main script being executed
[[ "$0" == "${(%):-%x}" ]] && Uninstaller::run "$@"
