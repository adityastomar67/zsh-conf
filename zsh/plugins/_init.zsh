# ───────────────────────────────────────────────────────────────────────────────────────
# File: _init.zsh
# Purpose: Orchestrates the loading of Zsh plugins and autoloadable functions.
# Problem: Centralizes the logic for installing plugin dependencies and
#          lazy-loading custom functions to ensure a fast shell startup.
# Features:
#   - Triggers the core plugin installer.
#   - Conditionally loads the Fuzzy Finder module (only if binary exists).
#   - Dynamically registers "annex" functions for autoloading.
#
# Usage:
#   Source this file during the Zsh initialization sequence (usually in .zshrc).
#   Ensure $ZSH_CONFIG_ROOT is defined.
#

# ───────────────────────────────────────────────────────────────────────────────────────

# ── core plugin installation ─────────────────────────────────────────────────

# Execute the plugin installation utility.
#   This function (defined in _core.utils) iterates over the global $ZPLUGINS
#   array and installs missing dependencies.
plug

# ── conditional modules ──────────────────────────────────────────────────────

# Load the Fuzzy Finder integration only if prerequisites are met.
#
# Logic:
#   1. Check if the 'fzf' binary is available in $PATH (via is_installed).
#   2. Check if the configuration file '_fuzzy' exists in our plugins directory.
if (( $+commands[fzf] )); then
    source "$ZSH_CONFIG_ROOT/plugins/_fuzzy"
fi

# ── autoload registration ────────────────────────────────────────────────────

#region Annex Loading

# Add the 'annexes' directory to the Zsh function search path ($fpath).
#   We prepend it to ensure our custom functions take precedence over system defaults.
fpath=("$ZSH_CONFIG_ROOT/plugins/annexes" $fpath)

# Dynamically mark all scripts in the annex directory for autoloading.
#
# Flags:
#   -U : Mark functions as undefined (load on first use).
#   -z : Force Zsh style autoloading (ignores KSH_AUTOLOAD).
#
# Glob Modifiers:
#   (N) : Null Glob. If no files match, return an empty list instead of erroring.
#   (:t): Tail. Extracts the filename (basename) from the full path.
local digest="$ZSH_CONFIG_ROOT/plugins/annexes.zwc"
if [[ -f "$digest" ]]; then
    # Load from the compiled digest (Fastest)
    autoload -w "$digest"
else
    # Fallback: Load individual files
    autoload -Uz "$ZSH_CONFIG_ROOT/plugins/annexes/"*(N:t)
fi

#endregion
