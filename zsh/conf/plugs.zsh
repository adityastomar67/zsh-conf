# █▀█ █   █ █ █▀▀ █ █▄ █ █▀
# █▀▀ █▄▄ █▄█ █▄█ █ █ ▀█ ▄█

export ZSH_COMPDUMP=~/.cache/.zcompdump-$HOST
OMZ_HOME="$HOME/.oh-my-zsh"
ZINIT_HOME="$HOME/.zinit"

##--> Zinit setup <--##
if [ ! -d "$ZINIT_HOME" ]; then
  clear
  echo "ZINIT not found. Cloning..."
  git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

alias use='zinit light'
alias ice='zinit ice'
alias load='zinit load'

ice depth"1"

use jeffreytse/zsh-vi-mode
use zsh-users/zsh-completions
use hlissner/zsh-autopair
use zdharma-continuum/fast-syntax-highlighting
use MichaelAquilina/zsh-you-should-use
use Aloxaf/fzf-tab

ice wait'3' lucid
load zsh-users/zsh-history-substring-search

ice wait'3' lucid
load zsh-users/zsh-autosuggestions

ice wait'3' lucid
load zsh-users/zsh-syntax-highlighting

ice wait'2' lucid
load zdharma-continuum/history-search-multi-word

ice wait'2' lucid
load jeffreytse/zsh-vi-mode

ice wait'5' lucid
unalias use ice load

##--> OMZ setup <--##
if [ $OMZ = "Yes" ]; then
  if [ ! -d "$OMZ_HOME" ]; then
    clear
    echo "OH-MY-ZSH not found. Cloning..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  plugins=(
    git
    history
    web-search
    copybuffer
    dirhistory
  )
  source "$OMZ_HOME/oh-my-zsh.sh"
  sleep 2
  if [ -f $HOME/.zshrc.pre-oh-my-zsh ]; then
    rm -rf $HOME/.zshrc
    command mv $HOME/.zshrc.pre-oh-my-zsh $HOME/.zshrc
  fi
elif [ $OMZ = "No" ]; then
  [ -d $OMZ_HOME ] && rm -rf $OMZ_HOME
fi

##--> Checking for .zcompdump file generated by plugs.zsh <--##
if [ -f $HOME/.zcompdump ]; then
  rm -rf $HOME/.zcompdump
fi

##--> Other Plugins <--##
command -v aws &>/dev/null && complete -C aws_completer aws
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# vim:filetype=zsh
