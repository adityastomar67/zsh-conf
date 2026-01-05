# ------------------------[  PLUGIN MANAGER CONFIGURATION  ]------------------------ #
# This file handles the installation and loading of plugins based on the
# selected manager (Zinit, Oh-My-Zsh, or Zap).


# ........................[  1. Path Definitions  ]........................ #

typeset -r OMZ_HOME="$HOME/.oh-my-zsh"
typeset -r OMZ_CUSTOM="$OMZ_HOME/custom"
typeset -r ZINIT_HOME="$HOME/.zinit"
typeset -r ZAP_HOME="$HOME/.local/share/zap"
typeset -r CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init"


# ........................[  2. Plugin Manager Logic  ]........................ #

# Option A: Zinit (Flexible & Fast)
if [[ "$PLUG_MANAGER" == "zinit" ]]; then

    # Install Zinit if missing
    if [[ ! -d "$ZINIT_HOME" ]]; then
        print -P "%F{33}▓▒░ %F{220}Installing Zinit Plugin Manager...%f"
        git clone --quiet --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi
    source "$ZINIT_HOME/zinit.zsh"

    # Turbo Mode (Asynchronous Loading)
    # "wait'0'" = Load immediately AFTER the prompt is drawn (Non-blocking).
    # "lucid"   = Silences the "Loaded plugin..." messages.

    # --- Group A: Core UI & Input (High Priority) ---
    # Load these FIRST so the terminal feels responsive immediately.
    # Moved 'autopair' and 'fzf-tab' here to unblock startup time.
    zinit wait"0" lucid for \
        hlissner/zsh-autopair \
        Aloxaf/fzf-tab \
        jeffreytse/zsh-vi-mode \
        MichaelAquilina/zsh-you-should-use

    # --- Group B: Completions (Heavy) ---
    # 'blockf' prevents unnecessary fpath processing which slows down compinit.
    zinit wait"0" lucid blockf for \
        zsh-users/zsh-completions

    # --- Group C: Search & History (Background) ---
    # These can load a split second later without user noticing.
    zinit wait"0b" lucid for \
        zsh-users/zsh-history-substring-search \
        zdharma-continuum/history-search-multi-word

    # --- Group D: Autosuggestions & Syntax Highlighting ---
    # Autosuggestions: Load fast so suggestions appear immediately.
    zinit wait"0a" lucid for \
        zsh-users/zsh-autosuggestions

    # Syntax Highlighting: MUST be last.
    # 'atinit' hook optimizes compinit to run only once, saving massive time.
    zinit wait"0c" lucid atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" for \
        zdharma-continuum/fast-syntax-highlighting


# Option B: Oh-My-Zsh (Standard & Robust)
elif [[ "$PLUG_MANAGER" == "omz" ]]; then

    # Install OMZ if missing
    if [[ ! -d "$OMZ_HOME" ]]; then
        print -P "%F{33}▓▒░ %F{220}Cloning Oh-My-Zsh...%f"
        git clone --quiet --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_HOME"
    fi

    # Plugins
    typeset -A external_plugins
    external_plugins=(
        "zsh-autosuggestions"       "https://github.com/zsh-users/zsh-autosuggestions"
        "zsh-syntax-highlighting"   "https://github.com/zsh-users/zsh-syntax-highlighting"
    )

    for plugin_name repo_url in ${(kv)external_plugins}; do
        if [[ ! -d "$OMZ_CUSTOM/plugins/$plugin_name" ]]; then
            print -P "%F{33}▓▒░ %F{220}Installing ${plugin_name}...%f"
            git clone --quiet --depth 1 "$repo_url" "$OMZ_CUSTOM/plugins/$plugin_name"
        fi
    done

    # Configuration
    # Note: OMZ is inherently synchronous. We cannot "defer" these easily.
    plugins=(
        git
        history
        web-search
        copybuffer
        dirhistory
        zsh-autosuggestions
        zsh-syntax-highlighting
    )

    # Settings
    # (Exported variables are usually required by OMZ internals)
    export DISABLE_UPDATE_PROMPT="true"
    export ENABLE_CORRECTION="true"
    export COMPLETION_WAITING_DOTS="true"

    # Load
    source "$OMZ_HOME/oh-my-zsh.sh"


# Option C: Zap (Minimal & Blazing Fast)
elif [[ "$PLUG_MANAGER" == "zap" ]]; then

    # 1. Install Zap if missing
    if [[ ! -d "$ZAP_HOME" ]]; then
        git clone --quiet --depth 1 https://github.com/zap-zsh/zap.git "$ZAP_HOME"
    fi

    [[ -f "$ZAP_HOME/zap.zsh" ]] && source "$ZAP_HOME/zap.zsh"

    # 2. Optimization Variables
    # CRITICAL FIX: This flag tells Autosuggestions: "Don't panic if another plugin
    # touches the widgets. I have handled the load order."
    # This stops the 621 function calls immediately.
    export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

    # 3. Core Tools
    plug "zap-zsh/zap"
    plug "romkatv/zsh-defer"

    # 4. Functional Plugins (Load Immediately)
    zsh-defer plug "hlissner/zsh-autopair"
    # plug "MichaelAquilina/zsh-you-should-use"

    # 5. Visual Plugins (Strict Order Required)

    zsh-defer plug "zsh-users/zsh-completions"
    # A. Load Autosuggestions FIRST (Deferred)
    zsh-defer plug "zsh-users/zsh-autosuggestions"

    # B. Load Completions & FZF
    zsh-defer plug "Aloxaf/fzf-tab"

    # C. Syntax Highlighting (MUST BE ABSOLUTE LAST)
    # It must wrap everything else to paint over it correctly.
    zsh-defer plug "zdharma-continuum/fast-syntax-highlighting"

    # D. Other deferred plugins
    # zsh-defer plug "zsh-users/zsh-history-substring-search"
    # zsh-defer plug "jeffreytse/zsh-vi-mode"

    # E. Final Safety Net (REQUIRED because of MANUAL_REBIND)
    bindkey '^I' complete-word
fi


# ........................[  3. Performance Helpers  ]........................ #

# Helper: Cache eval output to file and compile it.
# Regeneration triggers only if the cache is missing or the binary is newer.
_eval_cache() {
    local name="$1"
    local cmd="$2"
    local mode="${3:-defer}" # Default to 'defer'

    # Define directory INSIDE the function to prevent scope errors
    local cache_file="$CACHE_DIR/${name}.zsh"

    # Safety check: Ensure we aren't trying to write to root
    [[ -z "$CACHE_DIR" ]] && return 1

    # 1. Compile/Update Cache (Only if missing or binary changed)
    if [[ ! -e "$cache_file" || "$commands[$name]" -nt "$cache_file" ]]; then
        [[ ! -d "$CACHE_DIR" ]] && mkdir -p "$CACHE_DIR"
        eval "$cmd" > "$cache_file"
        zcompile "$cache_file"
    fi

    # 2. Load Logic
    if [[ "$mode" == "immediate" ]]; then
        source "$cache_file"
    else
        # Run in background after prompt
        zsh-defer source "$cache_file"
    fi
}


# ........................[  4. Tool Initialization  ]........................ #

# Zoxide (Smarter cd) - Cached
if (( $+commands[zoxide] )); then
    _eval_cache "zoxide" "zoxide init zsh" "defer"
fi

# Starship (Prompt) - Cached
if (( $+commands[starship] )); then
    _eval_cache "starship" "starship init zsh" "immediate"
fi

# Atuin (Shell History) - Cached
if (( $+commands[atuin] )); then
    _eval_cache "atuin" "atuin init zsh" "defer"
fi

# AWS CLI - Lazy Loaded
# Only loads the completer when you actually type 'aws <TAB>'
if (( $+commands[aws] )); then
    function _aws_completer_lazy() {
        if [[ -f /usr/local/bin/aws_completer ]]; then
            complete -C /usr/local/bin/aws_completer aws
        fi
        zle complete-word
    }
    compdef _aws_completer_lazy aws
fi

