#!/usr/bin/env zsh

# ------------------------[  ZSH CONFIGURATION UNINSTALLER  ]------------------------ #
# This script removes the custom Zsh configuration, symlinks, and plugins.
#
# ARCHITECTURE (Object-Based):
#   1. Theme::      -> Colors, Icons, and visual constants.
#   2. Config::     -> Paths to target for deletion.
#   3. UI::         -> Visual components (Spinner, Header, Confirm).
#   4. Log::        -> Standardized output wrappers.
#   5. Cleaner::    -> Removal logic (The "Business Logic").
#   6. Uninstaller::-> Main orchestration.


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
    Paths[CACHE]="${XDG_CACHE_HOME:-$HOME/.cache}"
    
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


# ........................[  4. Class: UI  ]........................ #
# Handles user interaction widgets.

UI::separator() {
    printf "${Color[K]}────────────────────────────────────────────────────────────${Color[Rst]}\n"
}

UI::typewriter() {
    local text="$1"
    local delay=0.01
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
    local pid=$!
    local msg="$1"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "  ${Color[C]}%c${Color[Rst]}  %s" "$spinstr" "$msg"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r\033[K"
    done
}

UI::header() {
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
    echo "               ${Color[K]}>> ZSH CONFIGURATION CLEANUP <<${Color[Rst]}"
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
            Log::warn "Skipping $link (Points to $target, not our repo)"
        fi
    elif [[ -f "$link" ]]; then
        Log::warn "Skipping $link (It is a real file, not a symlink)"
    fi
}

Cleaner::remove_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        rm -rf "$dir"
        Log::delete "Removed Directory: $dir"
    fi
}

Cleaner::remove_cache() {
    # Remove compiled zsh files and caches
    find "${Paths[CACHE]}" -name "zsh-*-init.zsh" -delete 2>/dev/null
    find "${Paths[CACHE]}" -name "zsh-*-init.zsh.zwc" -delete 2>/dev/null
    find "$HOME" -name ".zcompdump*" -delete 2>/dev/null
    
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
    
    if ! UI::confirm "Are you sure you want to proceed?"; then
        Log::info "Aborted by user."
        exit 0
    fi

    # 2. Remove Symlinks
    UI::separator
    Log::info "Removing Configuration Links..."
    Cleaner::remove_symlinks "${Paths[RC]}"
    Cleaner::remove_symlinks "${Paths[ENV]}"

    # 3. Remove Repository
    UI::separator
    Log::info "Removing Configuration Repository..."
    if [[ -d "${Paths[REPO]}" ]]; then
        Cleaner::remove_dir "${Paths[REPO]}"
    else
        Log::info "Repository not found (Already removed?)"
    fi

    # 4. Remove Plugin Managers
    UI::separator
    Log::info "Removing Plugin Managers..."
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

    # 5. Clear Cache
    UI::separator
    Log::info "Cleaning Cache..."
    Cleaner::remove_cache

    # 6. Restore Shell
    UI::separator
    Cleaner::restore_shell

    # 7. Finalize
    UI::separator
    Log::success "Uninstallation complete."
    echo
    
    # Check for backups to remind user
    local backup_count=$(ls -1 "$HOME" | grep ".zshrc_" | wc -l)
    if [[ $backup_count -gt 0 ]]; then
        Log::info "Note: You have $backup_count backup(s) of .zshrc in $HOME."
        Log::info "You may want to manually restore one: 'mv .zshrc_DATE .zshrc'"
    fi
    
    echo ""
    Log::info "Please restart your terminal."
}


# ........................[  7. Entry Point  ]........................ #

Uninstaller::run "$@"
