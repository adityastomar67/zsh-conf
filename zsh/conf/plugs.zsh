# ------------------------[  PLUGIN MANAGER CONFIGURATION  ]------------------------ #
# This file handles the installation and loading of plugins based on the
# selected manager (Zinit, Oh-My-Zsh, or Zap).


# ........................[  1. Path Definitions  ]........................ #

local OMZ_HOME="$HOME/.oh-my-zsh"
local ZINIT_HOME="$HOME/.zinit"
local ZAP_HOME="$HOME/.local/share/zap"


# ........................[  2. Plugin Manager Logic  ]........................ #

# Option A: Zinit (Flexible & Fast)
if [ "$PLUG_MANAGER" = "zinit" ]; then

    # 1. Install Zinit if missing
    if [ ! -d "$ZINIT_HOME" ]; then
        echo "ZINIT not found. Cloning..."
        git clone --quiet --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi
    source "$ZINIT_HOME/zinit.zsh"

    # 2. Aliases & Turbo Mode
    alias use='zinit light'
    alias ice='zinit ice'
    alias load='zinit load'

    # 3. Load Plugins (Synchronous - Critical for UX)
    ice depth"1"
    use hlissner/zsh-autopair
    use Aloxaf/fzf-tab

    # 4. Load Plugins (Asynchronous/Turbo)

    # Load heavy completions immediately after prompt (wait'0') to unblock startup
    ice wait'0' lucid blockf
    load zsh-users/zsh-completions

    # Syntax highlighting (Only load one!)
    ice wait'0' lucid atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay"
    load zdharma-continuum/fast-syntax-highlighting

    # Utility plugins
    ice wait'1' lucid;  load MichaelAquilina/zsh-you-should-use
    ice wait'2' lucid;  load zsh-users/zsh-history-substring-search
    ice wait'2' lucid;  load zsh-users/zsh-autosuggestions
    ice wait'2' lucid;  load zdharma-continuum/history-search-multi-word
    ice wait'3' lucid;  load jeffreytse/zsh-vi-mode

    # 5. Cleanup aliases
    ice wait'5' lucid;  unalias use ice load


# Option B: Oh-My-Zsh (Standard & Robust)
elif [ "$PLUG_MANAGER" = "omz" ]; then

    # 1. Install OMZ if missing
    if [ ! -d "$OMZ_HOME" ]; then
        echo "OH-MY-ZSH not found. Cloning..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # 2. Configuration
    plugins=(git history web-search copybuffer dirhistory zsh-autosuggestions zsh-syntax-highlighting)

    DISABLE_UPDATE_PROMPT="true"
    ENABLE_CORRECTION="true"
    COMPLETION_WAITING_DOTS="true"

    source "$OMZ_HOME/oh-my-zsh.sh"

    # 3. Fix Zshrc (OMZ installer overwrites it)
    if [ -f "$HOME/.zshrc.pre-oh-my-zsh" ]; then
        rm -rf "$HOME/.zshrc"
        mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc"
    fi


# Option C: Zap (Minimal & Blazing Fast)
elif [ "$PLUG_MANAGER" = "zap" ]; then

    # 1. Install Zap if missing
    if [ ! -d "$ZAP_HOME" ]; then
        git clone --quiet --depth 1 https://github.com/zap-zsh/zap.git "$ZAP_HOME"
    fi

    [ -f "$ZAP_HOME/zap.zsh" ] && source "$ZAP_HOME/zap.zsh"

    # 2. Optimization Variables
    # CRITICAL FIX: This flag tells Autosuggestions: "Don't panic if another plugin
    # touches the widgets. I have handled the load order."
    # This stops the 621 function calls immediately.
    export ZSH_AUTOSUGGEST_MANUAL_REBIND=1

    # 3. Core Tools
    plug "zap-zsh/zap"
    plug "romkatv/zsh-defer"

    # 4. Functional Plugins (Load Immediately)
    plug "hlissner/zsh-autopair"
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
    local cmd_name="$1"
    local init_cmd="$2"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
    local cache_file="$cache_dir/zsh-${cmd_name}-init.zsh"

    # Only proceed if the command actually exists
    if (( $+commands[$cmd_name] )); then
        # Check if cache is missing OR if the binary is newer than the cache
        if [[ ! -f "$cache_file" || "$commands[$cmd_name]" -nt "$cache_file" ]]; then
            [ ! -d "$cache_dir" ] && mkdir -p "$cache_dir"
            eval "$init_cmd" > "$cache_file"
            zcompile "$cache_file" # Compile to .zwc for faster parsing
        fi
        source "$cache_file"
    fi
}


# ........................[  4. Tool Initialization  ]........................ #

# Zoxide (Smarter cd) - Cached
_eval_cache "zoxide" "zoxide init zsh"

# Starship (Prompt) - Cached
_eval_cache "starship" "starship init zsh"

# Atuin (Shell History) - Cached
_eval_cache "atuin" "atuin init zsh"

# AWS CLI - Lazy Loaded
# Only loads the completer when you actually type 'aws <TAB>'
if (( $+commands[aws] )); then
    function _aws_completer_lazy() {
        # Check if we can use the Zsh native completer first
        if [[ -f /usr/local/bin/aws_completer ]]; then
            # Standard AWS completer path
            local AWS_COMPLETER=/usr/local/bin/aws_completer
            bashcompinit 2>/dev/null || autoload -U +X bashcompinit && bashcompinit
            complete -C $AWS_COMPLETER aws
        else
            # Fallback or just re-source completion
            unset -f _aws_completer_lazy
            # Triggers default completion
        fi
        zle complete-word
    }
    compdef _aws_completer_lazy aws
fi

# vim:filetype=zsh
