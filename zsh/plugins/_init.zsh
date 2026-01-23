
# Install Plugins (if ZPLUGINS array is set)
plug    # Coming from _core.utils


[[ -f "$ZSH_CONFIG_ROOT/plugins/_fuzzy" ]] && source "$ZSH_CONFIG_ROOT/plugins/_fuzzy"

# Annex Loading: Dynamically adds 'annexes' to the fpath (function path).
# (N:t) modifier:
#   N: null_glob (don't error if empty)
#   t: tail (basename only)
fpath=("$ZSH_CONFIG_ROOT/plugins/annexes" $fpath)
autoload -Uz "$ZSH_CONFIG_ROOT/plugins/annexes/"*(N:t)
