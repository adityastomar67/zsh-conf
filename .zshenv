# ------------------------[  ZSH ENVIRONMENT CONFIG  ]------------------------ #
# This file is loaded first, before .zshrc.
# It defines the core switches and paths for the configuration framework.


# ........................[  Core Paths & Settings  ]........................ #

# Path where the main configuration resides
export ZSH_PATH="${ZSH_PATH:-$HOME/.config/zsh-conf}"

# Zsh Completion Dump Location
export ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/.zcompdump"

# Path where the main dotfiles resides
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Values for macOS
    export DOT_PATH="$HOME/.config/mac-dots"
else
    # Values for Linux or other systems
    export DOT_PATH="$HOME/.config/b001-dots"
fi

# Package Manager Selection (Options: "zap", "zinit", "omz")
export PLUG_MANAGER="zap"

# Prompt Theme (Options: "gh0st", "z", "10k", etc.)
export PROMPT_THEME="gh0st"

# Minimal ZSH settings for "Not So Advanced" User. ("Yes" to enable, "No" to disable)
export MINIMALIST="No"

# Define a list of paths you want to add.
## You can mix absolute paths (starting with /) and relative paths (relative to $HOME).
typeset -a USER_PATHS
USER_PATHS=(
    "/usr/local/go/bin"                      # Absolute Path
    ".scripts"                               # Relative to $HOME
    ".spicetify"
)


# ........................[  Feature Toggles  ]........................ #

# Automatically launch Tmux on terminal start ("Yes" / "No")
export USE_TMUX="No"

# Load custom aliases from config ("Yes" / "No")
export USE_ALIAS="No"

# Load custom functions from config ("Yes" / "No")
export USE_FUNCTION="No"

# Enable 'theme.sh' script integration ("Yes" / "No")
export OPT_THEME="No"


# ........................[  Advanced Integrations  ]........................ #

# NVIM_APPNAME switcher by @elijahmanor (Requires nvim >= 0.9.0)
export MULTI_NEOVIM="No"

# Load personal wallpapers and source zsh on change
export CUSTOM_WALL="No"

# Location for wallpapers
export WALL_DIR="$HOME/Backdrops"

# Load private/offline aliases (Not meant for git tracking)
export TEMP_OFFLINE_CONFIG="No"

# Want vi mode in Shell?
export VI_MODE="No"


# ........................[  Secrets & Debugging  ]........................ #

# Enable startup profiling ("1" to enable, "0" to disable)
export ZSH_BENCHMARK="1"

# Path to your env file
ENV_FILE="$ZSH_PATH/.env"

if [[ -f "$ENV_FILE" ]]; then
    # 1. Turn on 'allexport' (Automatically export all defined variables)
    set -a

    # 2. Source the file (Load the variables)
    source "$ENV_FILE"

    # 3. Turn off 'allexport' (Back to normal safety)
    set +a
fi

