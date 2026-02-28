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
# ───────────────────────────────────────────────────────────────────────────────────────


# ── core plugin installation ─────────────────────────────────────────────────
# Execute the plugin installation utility.
#   This function (defined in _core.utils) iterates over the global $ZPLUGINS
#   array in the $ZDOTDIR/user.conf file and installs missing dependencies.
plug


# ── conditional modules ──────────────────────────────────────────────────────
# Load Fuzzy Finder only if the binary exists AND the config file is present
local _fuzzy_file="$ZSH_CONFIG_ROOT/plugins/_fuzzy"
if (( $+commands[fzf] )) && [[ -f "$_fuzzy_file" ]]; then
    source "$_fuzzy_file"
fi


# ── autoload registration ────────────────────────────────────────────────────
# Add the 'annexes' directory to the Zsh function search path ($fpath).
#   We prepend it to ensure our custom functions take precedence over system defaults.
fpath=("$ZSH_CONFIG_ROOT/plugins/annexes" $fpath)

# Dynamically mark all scripts in the annex directory for autoloading.
# Flags:
#   -U : Mark functions as undefined (load on first use).
#   -z : Force Zsh style autoloading (ignores KSH_AUTOLOAD).
# Glob Modifiers:
#   (N) : Null Glob. If no files match, return an empty list instead of erroring.
#   (:t): Tail. Extracts the filename (basename) from the full path.
local digest="$ZSH_CONFIG_ROOT/plugins/annexes.zwc"
if [[ -f "$digest" ]]; then
    # -w: Load from the compiled digest (Fastest)
    autoload -w "$digest"
else
    # Fallback: Load individual files
    autoload -Uz "$ZSH_CONFIG_ROOT/plugins/annexes/"*(N:t)
fi
