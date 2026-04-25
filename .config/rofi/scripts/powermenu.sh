#!/bin/bash

chosen=$(printf "󰐥 Shutdown\n󰜉 Reboot\n󰤄 Suspend\n󰒲 Sleep\n󰍃 Logout\n󰖳 Windows" | rofi -dmenu \
    -config ~/.config/rofi/powermenu.rasi \
    -p "Power")

case "$chosen" in
    "󰐥 Shutdown")  systemctl poweroff ;;
    "󰜉 Reboot")    systemctl reboot ;;
    "󰤄 Suspend")   systemctl suspend ;;
    "󰒲 Sleep")     systemctl hybrid-sleep ;;
    "󰍃 Logout")    niri msg action quit ;;   # change to your compositor logout cmd
    "󰖳 Windows")   wineboot -r ;;            # or whatever your windows cmd is
esac
