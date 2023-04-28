# ▄▀█ █░░ █ ▄▀█ █▀
# █▀█ █▄▄ █ █▀█ ▄█

##--> Example aliases <--##
# alias "alias_name"=<alias_command>

##--> Check if program is installed or not <--##
is_installed() {
    pacman -Qi $1 &>/dev/null
    return $?
}

##--> Unsetting all the aliases <--##
unalias -a

if [ $USE_ALIAS = "Yes" ]; then

    ##--> Sudo not required for some system commands <--##
    for command in mount umount sv pacman updatedb su shutdown poweroff reboot; do
        alias $command="sudo $command"
    done
    unset command

    ##--> Copy & Paste <--##
    alias copy='xsel --clipboard --input'
    alias paste='xsel --clipboard --output'
    alias xclip='xclip -selection clipboard'

    ##--> Memory & Process <--##
    alias p="ps -f"
    alias paux='ps aux | grep'
    alias psmem='ps auxf | sort -nr -k 4'
    alias pscpu='ps auxf | sort -nr -k 3'
    alias most='du -hsx * | sort -rh | head -10'
    alias psmem10='ps auxf | sort -nr -k 4 | head -10'
    alias pscpu10='ps auxf | sort -nr -k 3 | head -10'

    ##--> Command line shortcuts <--##
    alias -g S="| sed"
    alias -g H="| head"
    alias -g T="| tail"
    alias -g G="| grep"
    alias -g L="| less"
    alias -g M="| most"
    alias -g LL="2>&1 | less"
    alias -g NE="2> /dev/null"
    alias -g CA="2>&1 | bat -A"
    alias -g NUL="> /dev/null 2>&1"
    alias -g P="2>&1| pygmentize -l pytb"

    ##--> Shell Change <--##
    alias tozsh="sudo chsh $USER -s /bin/zsh && echo 'Now log out.'"
    alias tobash="sudo chsh $USER -s /bin/bash && echo 'Now log out.'"
    alias tofish="sudo chsh $USER -s /bin/fish && echo 'Now log out.'"

    ##--> Languages <--##
    alias py=python
    alias java="java $JDK_JAVA_OPTIONS"

    ##--> Directories <--##
    if [[ -d ~/dotfiles ]]; then
       alias dt="cd ~/dotfiles"
    elif [[ -d ~/.dotfiles ]]; then
       alias dt="cd ~/.dotfiles"
    elif [[ -d ~/.dots ]]; then
       alias dt="cd ~/.dots"
    fi
    [ -d ~/Projects ] && alias pj="cd ~/Projects"
    [ -d ~/Documents ] && alias dc="cd ~/Documents"
    [ -d ~/Downloads ] && alias dl="cd ~/Downloads"
    [ -d ~/Workspace ] && alias wk="cd ~/Workspace"
    alias cd..="cd ../"
    alias cd...="cd ../../"
    alias cd....="cd ../../../"
    alias cd.....="cd ../../../../"
    alias cd......="cd ../../../../../"
    alias ~="cd ~" 2>/dev/null
    alias -="cd -" 2>/dev/null
    alias ..="cd ../"
    alias ...="cd ../../"
    alias ....="cd ../../../"
    alias .....="cd ../../../../"
    alias ......="cd ../../../../../"
    alias .1="cd -1"
    alias .2="cd -2"
    alias .3="cd -3"
    alias .4="cd -4"
    alias .5="cd -5"
    alias .6="cd -6"
    alias .7="cd -7"
    alias .8="cd -8"
    alias .9="cd -9"

    ##--> Updating <--##
    alias update="paru -Syu --nocombinedupgrade"
    alias font-up='sudo fc-cache -fv'
    alias npm-up="sudo npm install npm@latest -g"
    alias upgrade="npm-up && pip-up && pacman -Syyu"
    alias grub-up="sudo grub-mkconfig -o /boot/grub/grub.cfg"
    alias pip-up="sudo pip3 list --outdated | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 pip3 install -U"

    ##--> Greping <--##
    alias grepin="grep -i"
    alias hgrep="fc -El 0 | grep"
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias sgrep="grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} "

    ##--> More Flags <--##
    alias mv="mv -i"
    alias calc="bc -l"
    alias tar="tar tf"
    alias wget="wget -c"
    alias free="free -m"
    alias dud="du -d 1 -h"
    alias nano="nano -00x"
    alias killl='killall -q'
    alias sorter="sort -n -r"
    alias du='ncdu -x --color off'
    alias startx='startx -- -keeptty >~/.xorg.log 2>&1'

    ##--> Config edit <--##
    alias zedit="$EDITOR ~/.zshrc"
    alias bedit="$EDITOR ~/.bashrc"
    alias visudo="$EDITOR /etc/sudoers"
    alias nvedit="cd $XDG_NVIM && $EDITOR init.lua"
    alias fedit="$EDITOR ~/.config/fish/config.fish"

    ##--> System <--##
    alias _="sudo"
    alias :q="exit"
    alias help="man"
    alias cls="clear"
    alias clr="clear"
    alias h="history"
    alias c="command"
    alias x="chmod +x"
    alias clean="clear"
    alias run-help="man"
    alias ping='ping -c 5'
    alias unexport="unset"
    alias logout="bspc quit"
    alias halt="sudo /sbin/halt"
    alias please='sudo $(fc -ln -1)'
    alias reboot="sudo /sbin/reboot"
    alias gping="ping -c5 google.com"
    alias fastping='ping -c 100 -s .2'
    alias poweroff="sudo /sbin/poweroff"
    alias shutdown="sudo /sbin/shutdown"
    alias lock='xscreensaver-command -lock'
    alias flighton="sudo rfkill block all"
    alias flightoff="sudo rfkill unblock all"
    alias tty-clock="tty-clock -S -c -C4 -D -s -n"
    alias suspend="systemctl suspend; locklauncher"
    alias snr="sudo service network-manager restart"

    ##--> Get fastest mirrors <--##
    alias gpg-check="gpg2 --keyserver-options auto-key-retrieve --verify"
    alias gpg-retrieve="gpg2 --keyserver-options auto-key-retrieve --receive-keys"
    alias mirrora="sudo reflector --latest 50 --number 20 --sort age --save /etc/pacman.d/mirrorlist"
    alias mirrord="sudo reflector --latest 50 --number 20 --sort delay --save /etc/pacman.d/mirrorlist"
    alias mirrors="sudo reflector --latest 50 --number 20 --sort score --save /etc/pacman.d/mirrorlist"
    alias mirrors="sudo reflector --verbose --latest 5 --country 'United States' --age 6 --sort rate --save /etc/pacman.d/mirrorlist"

    ##--> Extras <--##
    alias findr="\fd"
    alias week='date +%V'
    alias ip="curl ipinfo.io/ip"
    alias ff="find . -type f -name"
    alias path='echo -e ${PATH//:/\\n}'
    alias suck='sudo make clean install'
    alias merge="xrdb -merge ~/.Xresources"
    alias mantenimiento="yay -Sc && sudo pacman -Scc"
    alias purga='sudo pacman -Rns $(pacman -Qtdq) ; sudo fstrim -av'
    alias dday='date +"%Y.%m.%d - " | xclip -select clipboard ; date +"%Y.%m.%d"'
    alias ddate='date +"%R - %a, %B %d, %Y" | xclip -select clipboard && date +"%R - %a, %B %d, %Y"'
    alias weather='clear && curl -s wttr.in/$LOCATION | head -n $(($(curl -s wttr.in/$LOCATION | wc -l)  - 2)) | tail -n $(($(curl -s wttr.in/$LOCATION | wc -l)  - 4))'

    ##--> Binary Checks <--##
    is_installed gv && alias ps=gv
    is_installed bat && alias cat='bat'
    is_installed xchm && alias chm=xchm
    is_installed xdvi && alias dvi=xdvi
    is_installed sc-im && alias scim='sc-im'
    is_installed ytfzf && alias yt="ytfzf -t"
    is_installed mycli && alias mysql="mycli"
    is_installed fzf && alias f="clear && fzf"
    is_installed neomutt && alias mail="neomutt"
    is_installed ripgrep && alias grep="ripgrep"
    is_installed bluetoothctl && alias bt=bluetoothctl
    is_installed duf && alias df="duf" || alias df="df -h"
    is_installed nvim && alias vim="nvim" vimdiff="nvim -d"
    is_installed protonvpn-cli && alias pvpn='protonvpn-cli'
    is_installed journalctl && alias jctl="journalctl -p 3 -xb"
    is_installed rsync && alias cp="rsync -WavP --human-readable --progress"
    is_installed fusermount && alias unmount-phone="fusermount -u $HOME/Phone"
    is_installed trash && alias rm="trash --trash-dir='$HOME/.Trash' --recursive"
    is_installed go-mtpfs && alias mount-phone="go-mtpfs $HOME/Phone &>/dev/null & disown"
    is_installed cbonsai && alias ccbonsai="cbonsai -ilt 0.02 -c '  ,  ,  ,  ,  ' -L 5"
    is_installed transmission-cli && alias tsm='transmission-cli -D -u 10 -w ~/Downloads/torrents'

    if is_installed exa; then
        alias l.="exa -a | egrep '^\.'"
        alias la="exa -a --color=always --icons --group-directories-first"
        alias ll="exa -l --color=always --icons --group-directories-first"
        alias lt="exa -aT --level=2 --color=always --group-directories-first"
        alias l="exa -l --color=always --icons --git --group-directories-first"
        alias ls="clr && exa -al --color=always --icons --git --group-directories-first"
    fi

    if is_installed lsd; then
        alias ls="lsd -a --group-directories-first"
        alias ll="lsd -la --group-directories-first"
    fi

    if is_installed logo-ls; then
        alias lls="logo-ls"
        alias lla="logo-ls -l --all"
    fi

    if is_installed udisksctl; then
        alias mount-iso="udisksctl loop-setup -r -f"
        alias unmount-iso="udisksctl loop-delete -b"
        alias mount-ssd="udisksctl mount -b /dev/nvme0n1p1"
        alias unmount-ssd="udisksctl unmount -b /dev/nvme0n1p1"
    fi

    if is_installed ranger; then
        alias r="ranger"
        alias fm="ranger"
    fi

    if is_installed broot; then
        alias br="broot -dhp"
        alias bs="broot --sizes"
    fi

    if is_installed ptsh; then
        alias me-in=ptpwd
        alias mkdir=ptmkdir
    fi

    if is_installed yt-dlp; then
        alias ytv-best="yt-dlp -f bestvideo+bestaudio "
        alias yta-aac="yt-dlp --extract-audio --audio-format aac "
        alias yta-m4a="yt-dlp --extract-audio --audio-format m4a "
        alias yta-mp3="yt-dlp --extract-audio --audio-format mp3 "
        alias yta-wav="yt-dlp --extract-audio --audio-format wav "
        alias yta-best="yt-dlp --extract-audio --audio-format best "
        alias yta-flac="yt-dlp --extract-audio --audio-format flac "
        alias yta-opus="yt-dlp --extract-audio --audio-format opus "
        alias yta-vorbis="yt-dlp --extract-audio --audio-format vorbis "
    fi

    if is_installed yay; then
        alias yain="yay -S"
        alias yare="yay -R"
        alias yains="yay -U"
        alias yarep="yay -Si"
        alias yaloc="yay -Qi"
        alias yalst="yay -Qe"
        alias yaupd="yay -Sy"
        alias yaconf="yay -Pg"
        alias yaupg="yay -Syu"
        alias yarem="yay -Rns"
        alias yareps="yay -Ss"
        alias yalocs="yay -Qs"
        alias yamir="yay -Syy"
        alias yaorph="yay -Qtd"
        alias upgrade="yay -Syu"
        alias yainsd="yay -S --asdeps"
        alias yas="yay -Syu --noconfirm"
    fi

    if is_installed emacs; then
        alias em="/usr/bin/emacs -nw"
        alias emacs="emacsclient -c -a 'emacs'"
        alias doomsync="~/.emacs.d/bin/doom sync"
        alias doomdoctor="~/.emacs.d/bin/doom doctor"
        alias doomupgrade="~/.emacs.d/bin/doom upgrade"
    fi

    if is_installed pacman; then
        alias i="pacman -S"
        alias pacin="pacman -S"
        alias pacre="pacman -R"
        alias pacls="pacman -Ql"
        alias pacins="pacman -U"
        alias pacrep="pacman -Si"
        alias pacloc="pacman -Qi"
        alias pacown="pacman -Qo"
        alias pacupd="pacman -Sy"
        alias pacrem="pacman -Rns"
        alias pacreps="pacman -Ss"
        alias paclocs="pacman -Qs"
        alias pacupg="pacman -Syu"
        alias pacmir="pacman -Syy"
        alias pacfiles="pacman -F"
        alias pacfileupg="pacman -Fy"
        alias paclsorphans="pacman -Qdt"
        alias pacinsd="pacman -S --asdeps"
        alias cleanup="pacman -Rns (pacman -Qtdq)"
        alias unlock="sudo rm /var/lib/pacman/db.lck"
        alias pacrmorphans='pacman -Rs $(pacman -Qtdq)'
    fi

    if is_installed zathura; then
        alias zth=zathura
        alias pdf=zathura
    fi

    if is_installed tmux; then
        alias ts="tmux ls"
        alias attach="tmux attach -t"
    fi

    if is_installed git; then
        alias g=git
        alias ggpur=ggu
        alias grm='git rm'
        alias gam="git am"
        alias ga="git add"
        alias gd="git diff"
        alias gl="git pull"
        alias gp='git push'
        alias gf="git fetch"
        alias ghh="git help"
        alias gm='git merge'
        alias gsh='git show'
        alias grh='git reset'
        alias gb="git branch"
        alias gr='git remote'
        alias gap="git apply"
        alias gbs="git bisect"
        alias grb='git rebase'
        alias gst='git status'
        alias gsw='git switch'
        alias gts='git tag -s'
        alias grs='git restore'
        alias gpv='git push -v'
        alias grev='git revert'
        alias gru='git reset --'
        alias gc="git commit -v"
        alias gco="git checkout"
        alias gg="git gui citool"
        alias gcs="git commit -S"
        alias gaa="git add --all"
        alias gbD="git branch -D"
        alias gba="git branch -a"
        alias gbd="git branch -d"
        alias grv='git remote -v'
        alias gss='git status -s'
        alias glg="git log --stat"
        alias gams="git am --skip"
        alias gra='git remote add'
        alias gsb='git status -sb'
        alias gswc='git switch -c'
        alias gsr='git svn rebase'
        alias gstp='git stash pop'
        alias grbi='git rebase -i'
        alias gcp="git cherry-pick"
        alias glp=_git_log_prettily
        alias gbl="git blame -b -w"
        alias gbsb="git bisect bad"
        alias gama="git am --abort"
        alias gsd='git svn dcommit'
        alias gsta='git stash push'
        alias gstd='git stash drop'
        alias gstl='git stash list'
        alias gcb="git checkout -b"
        alias gcmsg="git commit -m"
        alias gstc='git stash clear'
        alias grmc='git rm --cached'
        alias gca="git commit -v -a"
        alias commit="git commit -m"
        alias push="git push origin"
        alias gfo="git fetch origin"
        alias glgg="git log --graph"
        alias pull="git pull origin"
        alias gapa="git add --patch"
        alias gclean="git clean -id"
        alias gau="git add --update"
        alias gbsg="git bisect good"
        alias gcsm="git commit -s -m"
        alias gcss="git commit -S -s"
        alias gds="git diff --staged"
        alias gma='git merge --abort'
        alias gpr='git pull --rebase'
        alias gpu='git push upstream'
        alias gstaa='git stash apply'
        alias gtv='git tag | sort -V'
        alias gup='git pull --rebase'
        alias gcam="git commit -a -m"
        alias grhh='git reset --hard'
        alias gcas="git commit -a -s"
        alias gbsr="git bisect reset"
        alias gbss="git bisect start"
        alias gapt="git apply --3way"
        alias gcf="git config --list"
        alias gav="git add --verbose"
        alias gcl="git clone --quiet"
        alias gdca="git diff --cached"
        alias glgp="git log --stat -p"
        alias gpd='git push --dry-run'
        alias grup='git remote update'
        alias gstall='git stash --all'
        alias grmv='git remote rename'
        alias grrm='git remote remove'
        alias gsi='git submodule init'
        alias grbo='git rebase --onto'
        alias grbs='git rebase --skip'
        alias gcld="git clone --depth"
        alias gamc="git am --continue"
        alias gbr="git branch --remote"
        alias gfg="git ls-files | grep"
        alias gcount="git shortlog -sn"
        alias 'gpf!'='git push --force'
        alias grba='git rebase --abort'
        alias gsu='git submodule update'
        alias grset='git remote set-url'
        alias gdw="git diff --word-diff"
        alias gcssm="git commit -S -s -m"
        alias gdup="git diff @{upstream}"
        alias grss='git restore --source'
        alias grst='git restore --staged'
        alias gcasm="git commit -a -s -m"
        alias gupv='git pull --rebase -v'
        alias gga="git gui citool --amend"
        alias globurl="noglob urlglobber "
        alias gsts='git stash show --text'
        alias grbc='git rebase --continue'
        alias "gc!"="git commit -v --amend"
        alias gbnm="git branch --no-merged"
        alias gk="\gitk --all --branches &!"
        alias gcpa="git cherry-pick --abort"
        alias gstu='gsta --include-untracked'
        alias gmtl='git mergetool --no-prompt'
        alias gpf='git push --force-with-lease'
        alias gcpc="git cherry-pick --continue"
        alias "gca!"="git commit -v -a --amend"
        alias glo="git log --oneline --decorate"
        alias grbm='git rebase $(git_main_branch)'
        alias gupa='git pull --rebase --autostash'
        alias gamscp="git am --show-current-patch"
        alias gswm='git switch $(git_main_branch)'
        alias gdcw="git diff --cached --word-diff"
        alias gcm='git checkout $(git_main_branch)'
        alias glgm="git log --graph --max-count=10"
        alias gclr="git clone --recurse-submodules"
        alias grbd='git rebase $(git_develop_branch)'
        alias gswd='git switch $(git_develop_branch)'
        alias gfa="git fetch --all --prune --jobs=10"
        alias gcd='git checkout $(git_develop_branch)'
        alias "gcn!"="git commit -v --no-edit --amend"
        alias glgga="git log --graph --decorate --all"
        alias gcor="git checkout --recurse-submodules"
        alias gupav='git pull --rebase --autostash -v'
        alias grad='git rm -r --cached . && git add .'
        alias gmom='git merge origin/$(git_main_branch)'
        alias glog='git log --oneline --decorate --graph'
        alias glum='git pull upstream $(git_main_branch)'
        alias gmum='git merge upstream/$(git_main_branch)'
        alias grbom='git rebase origin/$(git_main_branch)'
        alias "gcan!"="git commit -v -a --no-edit --amend"
        alias gignore="git update-index --assume-unchanged"
        alias gke='\gitk --all $(git log -g --pretty=%h) &!'
        alias gpristine='git reset --hard && git clean -dffx'
        alias gsps='git show --pretty=short --show-signature'
        alias "gcans!"="git commit -v -a -s --no-edit --amend"
        alias gignored='git ls-files -v | grep "^[[:lower:]]"'
        alias ggpull='git pull origin "$(git_current_branch)"'
        alias ggpush='git push origin "$(git_current_branch)"'
        alias gdt="git diff-tree --no-commit-id --name-only -r"
        alias gmtlvim='git mergetool --no-prompt --tool=vimdiff'
        alias gunignore='git update-index --no-assume-unchanged'
        alias gloga='git log --oneline --decorate --graph --all'
        alias groh='git reset origin/$(git_current_branch) --hard'
        alias grt='cd "$(git rev-parse --show-toplevel || echo .)"'
        alias gpoat='git push origin --all && git push origin --tags'
        alias gwch='git whatchanged -p --abbrev-commit --pretty=medium'
        alias gpsup='git push --set-upstream origin $(git_current_branch)'
        alias gdct='git describe --tags $(git rev-list --tags --max-count=1)'
        alias ggsup='git branch --set-upstream-to=origin/$(git_current_branch)'
        alias gtl='gtl(){ git tag --sort=-v:refname -n -l "${1}*" }; noglob gtl'
        alias gunwip='git log -n 1 | grep -q -c "\-\-wip\-\-" && git reset HEAD~1'
        alias grwh='git rm --cached `git ls-files -i -c --exclude-from=.gitignore`'
        alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'
        alias grwhx='git ls-files -i -c --exclude-from=.gitignore | xargs git rm --cached'
        alias git-svn-dcommit-push='git svn dcommit && git push github $(git_main_branch):svntrunk'
        [ -d $HOME/Downloads/git-repos/ ] && alias clone="cd $HOME/Downloads/git-repos/ && git clone"
        alias glod='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'\'
        alias glol='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'\'
        alias glola='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'\'' --all'
        alias glols='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset'\'' --stat'
        alias gwip='git add -A; git rm $(git ls-files --deleted) 2> /dev/null; git commit --no-verify --no-gpg-sign -m "--wip-- [skip ci]"'
        alias glods='git log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ad) %C(bold blue)<%an>%Creset'\'' --date=short'
        alias gbda='git branch --no-color --merged | command grep -vE "^([+*]|\s*($(git_main_branch)|$(git_develop_branch))\s*$)" | command xargs git branch -d 2>/dev/null'
    fi

fi

# vim:filetype=zsh
