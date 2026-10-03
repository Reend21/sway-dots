#!/bin/bash

chosen=$(printf "  Shutdown\n󰜉  Reboot\n󰑓  Reload Sway\n󰍃  Logout" | \
fuzzel --dmenu \
       --prompt "My baby shot me down.. ❯ " \
       --font "Iosevka Nerd Font:size=18" \
       --width 28 \
       --lines 4 \
       --line-height 32 \
       --horizontal-pad 20 \
       --vertical-pad 16)

case "$chosen" in
    *Shutdown)
        systemctl poweroff
        ;;
    *Reboot)
        systemctl reboot
        ;;
    *Reload*)
        swaymsg reload
        ;;
    *Logout)
        swaymsg exit
        ;;
esac
