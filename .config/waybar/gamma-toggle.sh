#!/bin/bash

# Gamma presets file
STATE_FILE="$HOME/.config/waybar/gamma_state"

# Define presets (name:gamma_values)
declare -A PRESETS=(
    ["Normal"]="1.0:1.0:1.0"
    ["Mild Vivid"]="0.8:0.85:0.9"
    ["Vivid"]="0.75:0.8:0.85"
    ["More Vivid"]="0.7:0.75:0.8"
    ["Very Vivid"]="0.65:0.7:0.75"
    ["Intense"]="0.6:0.65:0.7"
    ["Maximum"]="0.55:0.6:0.65"
)

# Order of presets
PRESET_ORDER=("Normal" "Mild Vivid" "Vivid" "More Vivid" "Very Vivid" "Intense" "Maximum")

# Initialize state file if it doesn't exist
if [[ ! -f "$STATE_FILE" ]]; then
    echo "Normal" > "$STATE_FILE"
fi

# Read current state
CURRENT=$(cat "$STATE_FILE")

# Handle click event (cycle to next preset)
if [[ "$1" == "click" ]]; then
    # Find current index
    for i in "${!PRESET_ORDER[@]}"; do
        if [[ "${PRESET_ORDER[$i]}" == "$CURRENT" ]]; then
            # Get next preset (wrap around)
            NEXT_INDEX=$(( (i + 1) % ${#PRESET_ORDER[@]} ))
            NEXT="${PRESET_ORDER[$NEXT_INDEX]}"
            
            # Apply gamma
            pkill gammastep
            sleep 0.1
            gammastep -O 6500 -g "${PRESETS[$NEXT]}" &
            
            # Save new state
            echo "$NEXT" > "$STATE_FILE"
            
            exit 0
        fi
    done
fi

# Output for waybar (default behavior)
echo "{\"text\":\"󰏘\", \"tooltip\":\"$CURRENT\", \"class\":\"gamma\"}"