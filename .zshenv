# ------------------------[  ZSH ENVIRONMENT CONFIG  ]------------------------ #
# This file is loaded first, before .zshrc.
# It defines the core switches and paths for the configuration framework.


# ........................[  Core Paths & Settings  ]........................ #

# Path where the main configuration resides
export ZSH_PATH="$HOME/.config/zsh-conf"

# Path where the main dotfiles resides
export DOT_PATH="$HOME/.config/b001-dots"

# Package Manager Selection (Options: "zap", "zinit", "omz")
export PLUG_MANAGER="zap"

# Prompt Theme (Options: "gh0st", "z", "10k", etc.)
export PROMPT_THEME="gh0st"

# Minimal ZSH settings for "Not So Advanced" User. ("1" to enable, "0" to disable)
export MINIMALIST="0"


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
export VI_MODE="Yes"


# ........................[  Secrets & Debugging  ]........................ #

# OpenAI API Key for CLI tools (Leave empty if using env.zsh or source from there)
export OPENAI_API_KEY=""

# Enable startup profiling ("1" to enable, "0" to disable)
export ZSH_BENCHMARK="0"
