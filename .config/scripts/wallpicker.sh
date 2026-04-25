#!/bin/bash
WALL_DIR="$HOME/Pictures/Wallpapers"
THUMB_DIR="$HOME/.cache/wallpaper-thumbs"
mkdir -p "$THUMB_DIR"

# Build the menu entries first, then pipe to rofi and capture selection
wall=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" \) | while read -r img; do
    thumb_name=$(echo "$img" | md5sum | cut -d' ' -f1)
    thumb="${THUMB_DIR}/${thumb_name}.jpg"

    if [ ! -f "$thumb" ]; then
        magick "$img" -thumbnail 300x -quality 60 "$thumb" 2>/dev/null
    fi

    echo -en "$img\x00icon\x1f${thumb}\n"
done | rofi -dmenu \
    -theme ~/.config/rofi/wallpaper.rasi \
    -show-icons \
    -p "Wallpapers")

[ -z "$wall" ] && exit 1

/home/varun/.local/bin/random-wall.sh "$wall"