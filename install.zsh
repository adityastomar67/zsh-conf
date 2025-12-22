#!/usr/bin/env zsh

# ------------------------[  ZSH CONFIGURATION INSTALLER  ]------------------------ #
# This script automates the setup of a custom Zsh environment.
#
# ARCHITECTURE (Object-Based):
#   1. Theme::      -> Colors, Icons, and visual constants.
#   2. Config::     -> Global paths and dependency lists.
#   3. UI::         -> Visual components (Spinner, Header, Confirm).
#   4. Log::        -> Standardized output wrappers.
#   5. Sys::        -> OS detection and Package Management abstraction.
#   6. FileSys::    -> File operations (Backup, Symlink, Patching).
#   7. Installer::  -> Business logic orchestration.


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
    Icon[PKG]="${Color[C]}${Color[Rst]}"
    Icon[GEAR]="${Color[W]}${Color[Rst]}"
}


# ........................[  2. Class: Config  ]........................ #
# Holds the state and configuration constants.

typeset -A Paths
typeset -a Dependencies

Config::init() {
    Paths[REPO]="$HOME/.config/zsh-conf"
    Paths[RC]="${ZDOTDIR:-$HOME}/.zshrc"
    Paths[ENV]="${ZDOTDIR:-$HOME}/.zshenv"
    Paths[BACKUP]="$HOME/.zsh_backups/$(date +%Y-%m-%d)"

    # Binary dependencies to ensure are present
    Dependencies=(
        "tmux" "ranger" "fd" "ripgrep" "lazygit"
        "zoxide" "fzf" "lsd" "npm" "ffmpegthumbnailer"
        "navi" "eza" "bat" "git-delta" "starship"
        "atuin" "shellcheck"
    )
}


# ........................[  3. Class: Log  ]........................ #
# Encapsulates all printing logic to ensure consistent formatting.

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

Log::pkg() {
    printf "  %s  %s%s%s\n" "${Icon[PKG]}" "${Color[C]}" "$1" "${Color[Rst]}"
}


# ........................[  4. Class: UI  ]........................ #
# Handles user interaction widgets and animations.

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
    echo "${Color[P]}"
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
    echo "              ${Color[K]}>> ZSH CONFIGURATION INSTALLER <<${Color[Rst]}"
    echo ""
}


# ........................[  5. Class: System  ]........................ #
# Abstraction layer for OS-specific commands (Package Managers).

typeset -A Sys

Sys::detect() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        Sys[PKG_MANAGER]="brew"
    elif command -v pacman &>/dev/null; then
        Sys[PKG_MANAGER]="pacman"
    elif command -v apt-get &>/dev/null; then
        Sys[PKG_MANAGER]="apt"
    elif command -v dnf &>/dev/null; then
        Sys[PKG_MANAGER]="dnf"
    else
        Log::error "Unsupported OS/Distro."
        exit 1
    fi
}

Sys::install() {
    local pkg="$1"
    if [[ "${Sys[PKG_MANAGER]}" == "pacman" ]]; then
        sudo pacman -S "$pkg" --noconfirm &>/dev/null &
    elif [[ "${Sys[PKG_MANAGER]}" == "brew" ]]; then
        brew install "$pkg" &>/dev/null &
    fi
}

Sys::is_installed() {
    # Returns 0 (true) if found, 1 (false) if not
    command -v "$1" >/dev/null 2>&1
}


# ........................[  6. Class: FileSystem  ]........................ #
# Abstraction layer for File I/O operations.

FileSys::patch() {
    local find="$1"
    local replace="$2"
    local file="$3"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|$find|$replace|g" "$file"
    else
        sed -i "s|$find|$replace|g" "$file"
    fi
}

FileSys::backup() {
    local file="$1"
    [[ ! -f "$file" ]] && return

    mkdir -p "${Paths[BACKUP]}"
    local ts=$(date +%H%M%S)
    # Atomic copy before any modification
    cp -a "$file" "${Paths[BACKUP]}/$(basename "$file")_$ts"
    Log::success "Atomic backup: $(basename "$file") -> ${Paths[BACKUP]}"
    sleep 2
}

FileSys::symlink() {
    local src="$1"
    local dest="$2"
    ln -sf "$src" "$dest"
    Log::success "Symlink created: $(basename "$dest")"
    sleep 2
}


# ........................[  7. Class: Installer  ]........................ #
# Main controller containing business logic.

Installer::dependencies() {
    UI::header
    Log::info "Analyzing Dependencies..."
    sleep 2

    local to_install=()
    local installed=()

    for pkg in "${Dependencies[@]}"; do
        if Sys::is_installed "$pkg"; then
            installed+=("$pkg")
        else
            to_install+=("$pkg")
        fi
    done

    for package in "${to_install[@]}"; do
        UI::header
        Log::info "Analyzing Dependencies..."
        [[ ${#installed[@]} -gt 0 ]] && Log::info "Already installed: ${installed[*]}"
        echo

        if UI::confirm "Install ${Color[Bld]}$package${Color[Rst]}?"; then
            Sys::install "$package"
            UI::spinner $! "Installing ${package}..."
            wait $!

            if Sys::is_installed "$package"; then
                Log::success "Installed $package"
            else
                Log::error "Failed to install $package"
            fi
        else
            Log::warn "Skipped $package"
        fi
    done
}

Installer::ensure_zsh() {
    if ! command -v zsh &>/dev/null; then
        if UI::confirm "Zsh is not installed. Install it?"; then
            Sys::install "zsh"
            wait $!
            Log::success "Zsh installed!"
        else
            Log::warn "Skipping Zsh installation."
        fi
    else
        Log::success "Zsh is present."
    fi
}

Installer::configure_features() {
    UI::header
    Log::info "Feature Configuration"
    sleep 2

    local options=(
        "Tmux Integration" "Alias Expansion" "Custom Functions"
        "Theme Engine" "Multi-Neovim Setup" "Custom Wallpapers"
        "Temp Offline config"
    )
    local config_var=(
        "USE_TMUX" "USE_ALIAS" "USE_FUNCTION"
        "OPT_THEME" "MULTI_NEOVIM" "CUSTOM_WALL"
        "TEMP_OFFLINE_CONFIG"
    )

    if [[ -f "${Paths[ENV]}" ]]; then
        # Note: Arrays are 1-indexed in Zsh, but we iterate to align logic
        for ((i = 1; i <= ${#options[@]}; i++)); do
            UI::header
            Log::info "Feature Configuration"
            echo
            if UI::confirm "Enable ${Color[Bld]}${options[$i]}${Color[Rst]}?"; then
                # Abstracted patch
                FileSys::patch "${config_var[$i]}=\"No\"" "${config_var[$i]}=\"Yes\"" "${Paths[REPO]}/.zshenv"
                printf "      %s Enabled %s\n" "${Icon[GEAR]}" "${options[$i]}"
            else
                printf "      ${Color[K]}· Disabled %s${Color[Rst]}\n" "${options[$i]}"
            fi
        done
    else
        Log::error "${Paths[ENV]} (source) not found."
    fi
}

Installer::run() {
    local DATE=$(date +%Y-%m-%d)
    local ID=$(date +%s)

    # 1. Init System
    Theme::init
    Config::init
    Sys::detect

    # 2. UI Intro
    UI::header
    sleep 1
    UI::typewriter "  :: Initializing setup environment..."
    sleep 2
    printf "\n"

    # 3. Zsh Check
    Installer::ensure_zsh

    # 4. Backups
    UI::header
    Log::info "Backup System"
    sleep 1
    FileSys::backup "${Paths[RC]}"
    FileSys::backup "${Paths[ENV]}"

    # 5. Clone
    UI::header
    Log::info "Downloading Configurations..."
    sleep 1

    # Handle collision
    [[ -d "${Paths[REPO]}" ]] && mv "${Paths[REPO]}" "${Paths[REPO]}_${DATE}_${ID}"

    git clone --quiet "https://github.com/adityastomar67/zsh-conf.git" "${Paths[REPO]}" &
    UI::spinner $! "Cloning repository..."
    wait $!

    printf "\r\033[K"
    Log::success "Config downloaded to ${Paths[REPO]}"
    sleep 2

    # 6. Symlinks
    FileSys::symlink "${Paths[REPO]}/.zshrc" "${Paths[RC]}"
    FileSys::symlink "${Paths[REPO]}/.zshenv" "${Paths[ENV]}"

    # 7. Default Shell
    if [[ $SHELL != "/usr/bin/zsh" ]] && [[ $SHELL != "/bin/zsh" ]]; then
        UI::header
        Log::warn "Changing shell to Zsh (Requires Root). Reboot required."
        if UI::confirm "Change default shell to Zsh?"; then
            chsh -s $(which zsh)
            sleep 1
            Log::success "Shell changed!"
        fi
    fi

    # 8. Dependencies
    Installer::dependencies

    # 9. Features
    Installer::configure_features

    # 10. Finalize
    UI::header
    Log::info "Finalizing..."
    sleep 2

    if command -v zsh &>/dev/null; then
        zsh -c "autoload -U zrecompile && zrecompile -p ${Paths[REPO]}/.zshrc" &>/dev/null \
            && Log::success "Autoload -u zrecompile: RECOMPILED!!" || true
        sleep 2
    fi

    echo
    Log::warn "Removing Installer Scripts..."
    [[ -e "${Paths[REPO]}/install.zsh" ]] && rm -rf "${Paths[REPO]}/install.zsh"
    sleep 2

    Log::success "Cleanup complete."
    echo
    sleep 2

    # Exit Summary
    printf "\n${Color[G]}  Installation Finished Successfully! ${Color[Rst]}\n"
    printf "  ${Color[K]}Restarting your terminal or run 'zsh' to see changes.${Color[Rst]}\n\n"
    sleep 4

    # Switch context
    [[ $? -eq 0 ]] && clear && SHOW_CONFIG_WARNING=1 exec zsh || return
}


# ........................[  8. Entry Point  ]........................ #
# Invoke the static main method of the Installer class.

# Only run if this file is the main script being executed
if [[ "$0" == "${(%):-%x}" ]]; then
    Installer::run "$@"
fi

