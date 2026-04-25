#!/bin/bash
# ~/.config/niri/fullscreen-all.sh

# Get all window IDs and fullscreen each one
niri msg --json windows | jq -r '.[].id' | while read -r id; do
    niri msg action fullscreen-window --id "$id"
done

# Kill waybar
pkill waybar