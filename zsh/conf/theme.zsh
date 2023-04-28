# ▀█▀ █ █ █▀▀ █▀▄▀█ █▀▀   █▀ █ █
#  █  █▀█ ██▄ █ ▀ █ ██▄ ▄ ▄█ █▀█

if [ $OPT_THEME = "Yes" ]; then

    ##--> Theme.sh Config <--##
    if ! command -v theme.sh >/dev/null; then
        sudo curl -Lo /usr/bin/theme.sh 'https://raw.githubusercontent.com/adityastomar67/theme.sh/master/bin/theme.sh' && sudo chmod +x /usr/bin/theme.sh
    fi

    [ -e ~/.theme_history ] && theme.sh "$(theme.sh -l | tail -n1)"

    # Optional
    last_theme() {
        theme.sh "$(theme.sh -l | tail -n2 | head -n1)"
    }
    zle -N last_theme

    # Bind C-o to the last theme.
    bindkey '^O' last_theme

    alias th='theme.sh -i'

    # Interactively load a light theme
    alias thl='theme.sh --light -i'

    # Interactively load a dark theme
    alias thd='theme.sh --dark -i'
fi

if [ $CUSTOM_WALL = "Yes" ]; then
    if [ ! -d "$HOME/.config/wall" ]; then
        # Clone it to the perfect location
        dunstify -u low -i ~/.config/bspwm/assets/reload.svg 'Custom Walls' "Cloning adityastomar67's Walls..."
        git clone --quiet https://github.com/adityastomar67/Wallpapers "$HOME/.config/wall"
        dunstify -u low -i ~/.config/bspwm/assets/reload.svg 'Custom Walls' "Cloning complete."

        # Move all the static wallpapers to `wall` directory and select the files with .png extension
        cd "$HOME/.config/wall" || exit
        command mv Static/* .
        /usr/bin/ls | grep "wall[0-9]*.png" >list.txt

        # Move all the .png files to .jpg
        list="./list.txt"
        while IFS= read -r file; do
            mv -- "$file" "${file%.png}.jpg"
        done <"$list"

        # Remove unnecessary files and set wallpaper
        command rm -rf .git/ README.md Static Live list.txt
    fi
    RandomWall
fi

# vim:filetype=zsh
