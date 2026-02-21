#!/usr/bin/env zsh

# ------------------------------------------------------------------------------
# File Purpose
#   This is the master installation script for the Zsh-conf environment.
#   It orchestrates the setup process, including dependency resolution,
#   file backups, symlinking, and feature configuration.
#
# Problems Solved
#   - Automates complex dotfile installation steps.
#   - Handles OS differences (macOS vs Linux) for package management.
#   - Provides a safe "Atomic Backup" mechanism before overwriting files.
#   - Visually guides the user through font capability checks.
#
# Features / Responsibilities
#   - Object-Oriented Simulation (Classes for UI, System, Config).
#   - Visual Feedback (Spinners, Colored Logs, ASCII Headers).
#   - Idempotency (Can be run multiple times safely).
#   - Self-Cleanup (Removes installer artifacts after success).
#
# Usage Notes
#   Run directly via: zsh install.zsh
#   Or curl-pipe: sh -c "$(curl -fsSL ...)"
# ------------------------------------------------------------------------------

#

# 0. Setup & Safety Initialization
# ───────────────────────────────────────────────────────────────────────
## Establish a predictable execution environment to prevent side effects.

# Reset shell options to Zsh defaults (ignores user aliases/functions)
emulate -L zsh

# Security:
# - ERR_EXIT: Stop immediately if a command fails.
# - NO_UNSET: Treat unset variables as errors.
# - PIPE_FAIL: Catch errors even inside pipes.
setopt ERR_EXIT NO_UNSET PIPE_FAIL

# File Safety: Prevent '>' from overwriting existing files accidentally.
setopt NO_CLOBBER


# 1. Class: Theme
# ───────────────────────────────────────────────────────────────────────
## Defines the visual palette, colors, and unicode symbols used
## throughout the installation process.

typeset -A THEME_COLORS
typeset -A THEME_ICONS

Theme::init() {
    # Palette (Using tput for terminal portability)
    # --------------------------------------------------------------------------
    THEME_COLORS[RED]=$(tput setaf 203)     # Error / Stop
    THEME_COLORS[GREEN]=$(tput setaf 156)   # Success
    THEME_COLORS[YELLOW]=$(tput setaf 220)  # Warning
    THEME_COLORS[BLUE]=$(tput setaf 111)    # Info
    THEME_COLORS[PURPLE]=$(tput setaf 176)  # Questions
    THEME_COLORS[CYAN]=$(tput setaf 14)     # Package / Action
    THEME_COLORS[WHITE]=$(tput setaf 255)   # Text
    THEME_COLORS[GREY]=$(tput setaf 240)    # Subtext
    THEME_COLORS[BOLD]=$(tput bold)         # Emphasis
    THEME_COLORS[RESET]=$(tput sgr0)        # Reset

    # Icons (Nerd Fonts)
    # --------------------------------------------------------------------------
    THEME_ICONS[OK]="${THEME_COLORS[GREEN]}${THEME_COLORS[RESET]}"
    THEME_ICONS[ERR]="${THEME_COLORS[RED]}${THEME_COLORS[RESET]}"
    THEME_ICONS[WARN]="${THEME_COLORS[YELLOW]}${THEME_COLORS[RESET]}"
    THEME_ICONS[QUEST]="${THEME_COLORS[PURPLE]}${THEME_COLORS[RESET]}"
    THEME_ICONS[INFO]="${THEME_COLORS[BLUE]}${THEME_COLORS[RESET]}"
    THEME_ICONS[PKG]="${THEME_COLORS[CYAN]}${THEME_COLORS[RESET]}"
    THEME_ICONS[GEAR]="${THEME_COLORS[WHITE]}${THEME_COLORS[RESET]}"
}


# 2. Class: Config
# ───────────────────────────────────────────────────────────────────────
## Holds global state, file paths, and dependency lists.

typeset -A CONFIG_PATHS
typeset -a REQUIRED_PACKAGES

Config::init() {
    # Directory Definitions
    # --------------------------------------------------------------------------
    # The root directory where the configuration will live
    CONFIG_PATHS[REPO]="${ZDOTDIR:-$HOME/.config/zsh-conf}"
    CONFIG_PATHS[CACHE]="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-cache"

    # Target files
    CONFIG_PATHS[RC]="${CONFIG_PATHS[REPO]}/.zshrc"
    CONFIG_PATHS[ENV]="${CONFIG_PATHS[REPO]}/.zshenv"
    CONFIG_PATHS[CONF]="${CONFIG_PATHS[REPO]}/user.conf"
    CONFIG_PATHS[HIST]="${CONFIG_PATHS[CACHE]}/zhistory"
    CONFIG_PATHS[DUMP]="${CONFIG_PATHS[CACHE]}/.zcompdump"

    # Backup location (Time-stamped)
    CONFIG_PATHS[BACKUP]="${CONFIG_PATHS[REPO]}_backups/$(date +%Y-%m-%d)"

    # External Binaries
    BIN_TARGET_DIR="${CONFIG_PATHS[REPO]}/zsh/bin"
    BIN_SOURCE_REPO="https://github.com/adityastomar67/uniq-scripts.git"

    # Dependency Manifest
    # --------------------------------------------------------------------------
    # Tools required for the full experience.
    REQUIRED_PACKAGES=(
        "ai-commit" "atuin" "bat" "eza" "fd" "fzf" "gawk"
        "git-delta" "lazygit" "lsd" "navi"
        "npm" "ranger" "ripgrep" "shellcheck"
        "starship" "tmux" "zoxide"
    )
}

Config::calibrate_fonts() {
    print -f "\n  ${THEME_COLORS[CYAN]}:: FONT CAPABILITY CALIBRATION ::${THEME_COLORS[RESET]}\n"
    print -f "  ${THEME_COLORS[GREY]}Since scripts cannot see your screen, we need your eyes.${THEME_COLORS[RESET]}\n\n"
    sleep 1

    # --- Test 1: Nerd Fonts ---
    print "  1. Look at the icons inside the brackets:"
    print "     [  ]  [  ]  [  ]"
    sleep 1
    print ""
    print -n "     Do you see clear icons (Folder, Git, Python)? (Y/n): "
    read -k1 -r HAS_NERD
    print ""
    sleep 1

    # --- Test 2: Ligatures ---
    print ""
    print "  2. Look at these symbols:"
    print "     !=   =>   =="
    print ""
    sleep 1
    print -n "     Did the symbols merge into single glyphs? (Y/n): "
    read -k1 -r HAS_LIGATURES
    sleep 1
    print ""
    print ""

    # Feedback Loop
    if [[ "$HAS_NERD" =~ ^[Yy]$ ]]; then
        print -f "${THEME_COLORS[CYAN]}  ✔ Nerd Fonts enabled.${THEME_COLORS[RESET]}\n"
    else
        print -f "${THEME_COLORS[GREY]}  ✘ Nerd Fonts disabled. Switching to ASCII mode (simulated).${THEME_COLORS[RESET]}\n"
    fi

    if [[ "$HAS_LIGATURES" =~ ^[Yy]$ ]]; then
        print -f "${THEME_COLORS[CYAN]}  ✔ Ligatures confirmed.${THEME_COLORS[RESET]}\n"
    else
        print -f "${THEME_COLORS[GREY]}  ✘ Ligatures not detected (Visual only).${THEME_COLORS[RESET]}\n"
    fi

    # Confirmation if tests failed
    if [[ "$HAS_NERD" =~ ^[Nn]$ || "$HAS_LIGATURES" =~ ^[Nn]$ ]]; then
        sleep 2
        print -f "\n\n  ${THEME_COLORS[RED]}${THEME_COLORS[BOLD]}Do you want to continue with the above options? (Y/n)${THEME_COLORS[RESET]}"
        read -k1 -r ANS
        if [[ "$ANS" =~ ^[Nn]$ ]]; then
            print -f "\n  ${THEME_COLORS[RED]}Setup aborted by user.${THEME_COLORS[RESET]}\n"
            exit 1
        fi
    fi
}


# 3. Class: Logger
# ───────────────────────────────────────────────────────────────────────
## Standardized output wrappers to ensure consistent formatting.

Logger::info() {
    print -f "  %s  %s%s%s\n" "${THEME_ICONS[INFO]}" "${THEME_COLORS[BLUE]}" "$1" "${THEME_COLORS[RESET]}"
}

Logger::success() {
    print -f "  %s  %s%s%s\n" "${THEME_ICONS[OK]}" "${THEME_COLORS[GREEN]}" "$1" "${THEME_COLORS[RESET]}"
}

Logger::warn() {
    print -f "  %s  %s%s%s\n" "${THEME_ICONS[WARN]}" "${THEME_COLORS[YELLOW]}" "$1" "${THEME_COLORS[RESET]}"
}

Logger::error() {
    print -f "  %s  %s%s%s\n" "${THEME_ICONS[ERR]}" "${THEME_COLORS[RED]}" "$1" "${THEME_COLORS[RESET]}"
}

Logger::package() {
    print -f "  %s  %s%s%s\n" "${THEME_ICONS[PKG]}" "${THEME_COLORS[CYAN]}" "$1" "${THEME_COLORS[RESET]}"
}


# 4. Class: UserInterface (UI)
# ───────────────────────────────────────────────────────────────────────
## Handles widgets, animations, and user prompts.

#

Interface::typewriter() {
    local text="$1"
    local delay=0.02
    for ((i = 0; i < ${#text}; i++)); do
        print -f "%s" "${text:$i:1}"
        sleep $delay
    done
    print ""
}

Interface::prompt_confirm() {
    local question="$1"
    print -f "  %s  %s ${THEME_COLORS[GREY]}[y/N]${THEME_COLORS[RESET]} " "${THEME_ICONS[QUEST]}" "$question"
    read -k 1 -r response
    print ""
    [[ "$response" =~ ^[yY]$ ]]
}

Interface::spinner() {
    local pid=$1
    local msg="$2"
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    # Safety: Ensure cursor is visible even if script crashes
    trap "tput cnorm; exit" SIGINT SIGTERM

    tput civis # Hide cursor

    # Loop while process (pid) is still running
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr:0:1}

        # Draw Spinner
        print -f "\r  ${THEME_COLORS[CYAN]}%s${THEME_COLORS[RESET]}  %s" "$temp" "$msg"

        # Rotate String
        spinstr=${spinstr:1}${spinstr:0:1}
        sleep $delay
    done

    # Cleanup
    print -f "\r\033[K"     # Clear line
    tput cnorm            # Show cursor
    trap - SIGINT SIGTERM # Remove trap
}

Interface::print_banner() {
    sleep 2
    clear
    print "${THEME_COLORS[PURPLE]}"
    print "  ▒███████▒  ██████  ██░ ██  ▄████▄   ▒█████   ███▄    █   █████▒"
    print "  ▒ ▒ ▒ ▄▀░▒██    ▒ ▓██░ ██▒▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █ ▓██   ▒ "
    print "  ░ ▒ ▄▀▒░ ░ ▓██▄   ▒██▀▀██░▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒▒████ ░ "
    print "    ▄▀▒   ░  ▒   ██▒░▓█ ░██ ▒▓▓▄ ▄██▒▒██   ██ ▓██▒  ▐▌██▒ ▓█▒  ░ "
    print "  ▒███████▒▒██████▒▒░▓█▒░██▓▒ ▓███▀ ░░ ████▓▒ ▒██░   ▓██. ▒█░   "
    print "  ░▒▒ ▓░▒░▒▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒  ▒ ░    "
    print "   ░░▒ ▒ ░ ▒░ ░▒  ░ ░ ▒ ░▒░ ░  ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░ ░      "
    print "   ░ ░ ░ ░ ░░  ░  ░   ░  ░░ ░░        ░ ░ ░ ▒     ░   ░ ░  ░ ░     "
    print "     ░ ░          ░   ░  ░  ░░ ░          ░ ░           ░           "
    print "${THEME_COLORS[RESET]}"
    print "              ${THEME_COLORS[GREY]}>> ZSH CONFIGURATION INSTALLER <<${THEME_COLORS[RESET]}"
    print ""
}


# 5. Class: System
# ───────────────────────────────────────────────────────────────────────
## Abstraction layer for OS-specific commands (Package Managers).

typeset -A SYSTEM_INFO

System::detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SYSTEM_INFO[PKG_MANAGER]="brew"
    elif (( $+commands[pacman] )); then
        SYSTEM_INFO[PKG_MANAGER]="pacman"
    elif (( $+commands[apt-get] )); then
        SYSTEM_INFO[PKG_MANAGER]="apt"
    elif (( $+commands[dnf] )); then
        SYSTEM_INFO[PKG_MANAGER]="dnf"
    else
        Logger::error "Unsupported OS/Distro."
        exit 1
    fi
}

System::install_package() {
    local pkg="$1"

    # Pre-authenticate sudo to prevent background process from hanging
    if [[ "${SYSTEM_INFO[PKG_MANAGER]}" != "brew" ]]; then
        sudo -v
    fi

    # Background execution for spinner compatibility
    case "${SYSTEM_INFO[PKG_MANAGER]}" in
        pacman) sudo pacman -S --noconfirm "$pkg" &>/dev/null & ;;
        brew)   brew install "$pkg" &>/dev/null & ;;
        apt)    sudo apt-get install -y "$pkg" &>/dev/null & ;;
        dnf)    sudo dnf install -y "$pkg" &>/dev/null & ;;
    esac
}

System::cleanup() {
    # 1. Determine Source vs Destination
    local current_script_path="${(%):-%x}"
    local source_dir="${current_script_path:A:h}" # Absolute path of this script's dir
    local dest_dir="${CONFIG_PATHS[REPO]:A}"      # Absolute path of install target

    Logger::info "Cleaning up..."

    # 2. Remove Install Artifacts inside the Destination
    local artifacts=("install.zsh" "README.md" "LICENSE")

    for item in "${artifacts[@]}"; do
        local target="${CONFIG_PATHS[REPO]}/$item"
        if [[ -e "$target" ]]; then
            rm -rf "$target"
        fi
    done

    # 3. Smart Cleanup of Source Directory
    # If the user ran the installer from ~/Downloads/zsh-conf, ask to delete it
    # since we installed a copy to ~/.config/zsh-conf
    if [[ "$source_dir" != "$dest_dir" ]]; then
        Logger::warn "Installer ran from temporary location: $source_dir"

        # Safety: Prevent deletion of Home or Root
        if [[ "$source_dir" == "$HOME" || "$source_dir" == "/" ]]; then
            Logger::error "Unsafe source directory detected. Skipping source deletion."
        else
            if Interface::prompt_confirm "Delete this source directory to save space?"; then
                cd "$HOME" || exit
                rm -rf "$source_dir"
                Logger::success "Source repository removed."
            else
                Logger::info "Source repository kept."
            fi
        fi
    fi
    sleep 2
}


# 6. Class: FileSystem
# ───────────────────────────────────────────────────────────────────────
## Helpers for File I/O, patching, and backups.

FileSystem::atomic_backup() {
    local file="$1"
    [[ ! -f "$file" ]] && return

    mkdir -p "${CONFIG_PATHS[BACKUP]}"
    local timestamp=$(date +%H%M%S)

    # -a: Archive mode (preserve attributes)
    cp -a "$file" "${CONFIG_PATHS[BACKUP]}/$(basename "$file")_$timestamp"

    Logger::success "Atomic backup: $(basename "$file") -> ${CONFIG_PATHS[BACKUP]}"
    sleep 2
}

FileSystem::create_symlink() {
    local src="$1"
    local dest="$2"

    # -s: Symbolic, -f: Force
    ln -sf "$src" "$dest"

    Logger::success "Symlink created: $(basename "$dest")"
    sleep 2
}


# 7. Class: Installer (Controller)
# ───────────────────────────────────────────────────────────────────────
## Main business logic orchestration.

Installer::check_dependencies() {
    Interface::print_banner
    Logger::info "Analyzing Dependencies..."
    sleep 2

    local missing_pkgs=()
    local installed_pkgs=()

    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if (( $+commands[$pkg] )); then
            installed_pkgs+=("$pkg")
        else
            missing_pkgs+=("$pkg")
        fi
    done

    for package in "${missing_pkgs[@]}"; do
        Interface::print_banner
        Logger::info "Analyzing Dependencies..."
        [[ ${#installed_pkgs[@]} -gt 0 ]] && Logger::info "Already installed: ${installed_pkgs[*]}"
        print

        if Interface::prompt_confirm "Install ${THEME_COLORS[BOLD]}$package${THEME_COLORS[RESET]}?"; then
            # Start install in background
            System::install_package "$package"

            # Show spinner while waiting for PID ($!)
            Interface::spinner $! "Installing ${package}..."
            wait $!

            if (( $+commands[$package] )); then
                Logger::success "Installed $package"
            else
                Logger::error "Failed to install $package"
            fi
        else
            Logger::warn "Skipped $package"
        fi
    done
}

Installer::ensure_zsh_shell() {
    # 1. Install Zsh if missing
    if ! (( $+commands[zsh] )); then
        if Interface::prompt_confirm "Zsh is not installed. Install it?"; then
            System::install_package "zsh"
            wait $!
            Logger::success "Zsh installed!"
        else
            Logger::warn "Skipping Zsh installation. Script may fail."
        fi
    else
        Logger::success "Zsh is present."
    fi

    # 2. Set as Default Shell
    if [[ $SHELL != "/usr/bin/zsh" ]] && [[ $SHELL != "/bin/zsh" ]]; then
        Interface::print_banner
        Logger::warn "Changing shell to Zsh (Requires Root). Reboot required."
        if Interface::prompt_confirm "Change default shell to Zsh?"; then
            chsh -s "$(which zsh)"
            sleep 1
            Logger::success "Shell changed!"
        fi
    fi
}

Installer::configure_user_features() {
    Interface::print_banner
    Logger::info "Feature Configuration"
    sleep 2

    local feature_names=(
        "Alias Expansion" "Custom Functions" "Custom Wallpapers" "Use VI Mode"
        "Fancy Startup stuff" "Minimalist Config" "Multi-Neovim Setup" "Temp Offline config"
        "Theme Engine" "Tmux Integration"
    )

    local config_keys=(
        "LOAD_CUSTOM_ALIASES" "LOAD_CUSTOM_FUNCTIONS" "ENABLE_WALLPAPER_SYNC" "ENABLE_VI_MODE"
        "ENABLE_FANCY_STARTUP" "ENABLE_MINIMAL_MODE" "ENABLE_MULTI_NEOVIM" "LOAD_PRIVATE_CONFIG"
        "ENABLE_THEME_SH_INTEGRATION" "ENABLE_AUTO_TMUX"
    )

    if [[ -f "${CONFIG_PATHS[CONF]}" ]]; then
        local target_file="${CONFIG_PATHS[CONF]}"
        local sed_args=()

        # Iterate 1-based to match Zsh array behavior
        for ((i = 1; i <= ${#feature_names[@]}; i++)); do
            Interface::print_banner
            Logger::info "Feature Configuration"
            print

            if Interface::prompt_confirm "Enable ${THEME_COLORS[BOLD]}${feature_names[$i]}${THEME_COLORS[RESET]}?"; then
                # Queue modification logic for .zshenv
                sed_args+=("-e" "s|${config_keys[$i]}=\"No\"|${config_keys[$i]}=\"Yes\"|g")
                print -f "      %s Enabled %s\n" "${THEME_ICONS[GEAR]}" "${feature_names[$i]}"
            else
                print -f "      ${THEME_COLORS[GREY]}· Disabled %s${THEME_COLORS[RESET]}\n" "${feature_names[$i]}"
            fi
        done

        if [[ ${#sed_args[@]} -gt 0 ]]; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "${sed_args[@]}" "$target_file"
            else
                sed -i "${sed_args[@]}" "$target_file"
            fi
        fi
    else
        Logger::error "${CONFIG_PATHS[CONF]} (source) not found."
    fi
}

Installer::main() {
    local DATE=$(date +%Y-%m-%d)
    local TIMESTAMP=$(date +%s)

    # 1. Initialization
    Theme::init
    Config::init
    System::detect_os

    # 2. Font Check
    Interface::print_banner
    sleep 1
    Interface::typewriter "  :: Checking Nerd Fonts/Font Ligatures..."
    sleep 2
    Config::calibrate_fonts

    # 3. Intro
    Interface::print_banner
    sleep 1
    Interface::typewriter "  :: Initializing setup environment..."
    sleep 2
    print -f "\n"

    # 4. Prerequisites
    Installer::ensure_zsh_shell

    # 5. Backups
    Interface::print_banner
    Logger::info "Backup System"
    sleep 1
    FileSystem::atomic_backup "${CONFIG_PATHS[RC]}"
    FileSystem::atomic_backup "${CONFIG_PATHS[ENV]}"
    FileSystem::atomic_backup "${CONFIG_PATHS[CONF]}"
    mkdir -p "${CONFIG_PATHS[CACHE]}" 2>/dev/null

    # 6. Repository Cloning
    Interface::print_banner
    Logger::info "Downloading Configurations..."
    sleep 1

    # Handle Directory Collision (Back up existing folder)
    if [[ -d "${CONFIG_PATHS[REPO]}" ]]; then
        mkdir -p "${CONFIG_PATHS[BACKUP]}"
        mv "${CONFIG_PATHS[REPO]}" "${CONFIG_PATHS[BACKUP]}/zsh-conf"
    fi

    # Parallel Cloning
    {
        local temp_dir="/tmp/zsh_bin_${TIMESTAMP}"

        # Start both clones concurrently
        git clone -b remastered --single-branch --depth=1 --quiet "https://github.com/adityastomar67/zsh-conf.git" "${CONFIG_PATHS[REPO]}" &
        local pid_repo=$!

        git clone --depth=1 --quiet "$BIN_SOURCE_REPO" "$temp_dir" &
        local pid_bin=$!

        # Wait for both config and binary clones to finish
        wait $pid_repo
        wait $pid_bin

        # Now safely copy the binary dependencies (since repo clone is done)
        mkdir -p "$BIN_TARGET_DIR"
        cp -a "$temp_dir/." "$BIN_TARGET_DIR/"
        rm -rf "$temp_dir"
    } &

    Interface::spinner $! "Cloning repository..."
    wait $!

    print -f "\r\033[K"
    Logger::success "Config downloaded to ${CONFIG_PATHS[REPO]}"
    sleep 2

    # Move History and Compdump to new locations
    [[ -f "${CONFIG_PATHS[HIST]}" ]] && rm -f "${CONFIG_PATHS[HIST]}"
    [[ -f "${CONFIG_PATHS[REPO]}/zhistory" ]] && mv "${CONFIG_PATHS[REPO]}/zhistory" "${CONFIG_PATHS[HIST]}"


    # 7. Environment Setup
    Interface::print_banner
    Logger::info "Environment Setup"
    cat <<'EOF' >| "$HOME/.zshenv"
# .zshenv - Zsh environment configuration
# This file is sourced by all instances of zsh.
# It sets the ZDOTDIR variable to point to your custom configuration directory.

export ZDOTDIR="$HOME/.config/zsh-conf"
EOF
    Logger::success "ZDOTDIR configured in $HOME/.zshenv"
    sleep 1


    # 8. Dependencies & Features
    Installer::check_dependencies
    Installer::configure_user_features

    # 9. Finalization
    Interface::print_banner
    Logger::info "Finalizing..."
    (
        # 1. Branch & Header
        git config --global color.status.header "#9e9e9e italic"
        git config --global color.status.branch "#ffd700 bold"
        git config --global color.status.nobranch "#00bfff bold"

        # 2. Staging Area (Index)
        git config --global color.status.added "#a6e22e bold"
        git config --global color.status.updated "#9fef66 bold"
        git config --global color.status.changed "#fd971f bold"

        # 3. Working Tree (Unstaged)
        git config --global color.status.worktree "#f92672 bold"
        git config --global color.status.untracked "#ae81ff"
        git config --global color.status.ignored "#555555"

        # 4. Critical Events (FIXED)
        git config --global color.status.unmerged "#ffffff #ff0033 bold ul"

        # 5. Diff Colors
        git config --global color.diff.meta "#75715e"
        git config --global color.diff.frag "#9fef66 bold"
        git config --global color.diff.func "#f8f8f2"
        git config --global color.diff.old "#f92672"
        git config --global color.diff.new "#a6e22e"
        git config --global color.diff.whitespace "red reverse"
    ) &
    sleep 2

    # 10. Cleanup
    print
    System::cleanup

    Logger::success "Cleanup complete."
    print

    Interface::print_banner

    # 11. Exit & Onboarding
    print -f "\n${THEME_COLORS[GREEN]}  Installation Finished Successfully! ${THEME_COLORS[RESET]}\n"

    # Inject Welcome Screen source if missing
    if ! grep -q "_ui.welcome" "${CONFIG_PATHS[REPO]}/.zshrc"; then
        print 'source "$ZSH_CONFIG_ROOT/lib/_ui.welcome"' >> "${CONFIG_PATHS[REPO]}/.zshrc"
    fi
    sleep 2

    if Interface::prompt_confirm "Launch new shell now?"; then
        exec zsh
    else
        print
        Logger::info "Please restart your terminal manually to see changes."
        exit 0
    fi
}


# 8. Entry Point
# ───────────────────────────────────────────────────────────────────────
## Only execute if this script is run directly (not sourced).

if [[ "$0" == "${(%):-%x}" ]]; then
    Installer::main "$@"
fi
