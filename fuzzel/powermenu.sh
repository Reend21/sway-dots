#!/bin/bash

chosen=$(printf " Shutdown\n󰜉 Reboot\n󰑓 Reload Sway\n󰍃 Logout" | \
fuzzel --dmenu)
--prompt "  " \
--line-height 22)

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
