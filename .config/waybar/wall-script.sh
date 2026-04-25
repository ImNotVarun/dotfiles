#!/bin/bash
# Sequential wallpaper changer with Pexels API integration and Google Backdrop
# Supports local wallpapers, random Pexels images, and Google featured photos

# Folder paths
WALLPAPER_DIR_MAIN="$HOME/Pictures/Wallpapers/wallpapers"

# Pexels API configuration
PEXELS_API_KEY="YpSEegTLnMhjNk3hsYAT6ObN6VT6CU8P22WoaqE24Gcry1S2mGASjvwN"
PEXELS_CACHE_DIR="$HOME/.cache/pexels_wallpapers"
mkdir -p "$PEXELS_CACHE_DIR"

# Google Backdrop cache
BACKDROP_CACHE_DIR="$HOME/.cache/backdrop_wallpapers"
mkdir -p "$BACKDROP_CACHE_DIR"

# Backdrop state files
BACKDROP_URLS_FILE="$BACKDROP_CACHE_DIR/urls_list.txt"
BACKDROP_INDEX_FILE="$BACKDROP_CACHE_DIR/current_index"

# Base file to store last wallpaper index
STATE_DIR="$HOME/.cache/wallpaper_indices"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/main_index"

# Determine mode based on argument
mode="$1"
search_query="$2"

# Function to fetch Google Backdrop featured photo
fetch_backdrop_wallpaper() {
    # Check if we have cached URLs and haven't finished the collection yet
    if [ -f "$BACKDROP_URLS_FILE" ] && [ -f "$BACKDROP_INDEX_FILE" ]; then
        local current_index=$(<"$BACKDROP_INDEX_FILE")
        local total_urls=$(wc -l < "$BACKDROP_URLS_FILE")
        
        # If we still have URLs to go through
        if [ "$current_index" -lt "$total_urls" ]; then
            echo "📋 Using cached URL collection ($((current_index + 1))/$total_urls)" >&2
            
            # Get the URL at current index (1-indexed)
            local image_url=$(sed -n "$((current_index + 1))p" "$BACKDROP_URLS_FILE")
            
            # Increment index for next time
            echo "$((current_index + 1))" > "$BACKDROP_INDEX_FILE"
            
            # Download and return
            local filename="$BACKDROP_CACHE_DIR/backdrop_$current_index.jpg"
            
            echo "⬇️ Downloading Google Backdrop photo ($((current_index + 1))/$total_urls)" >&2
            curl -s \
                -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
                -H "Referer: https://clients3.google.com/" \
                "$image_url" -o "$filename"
            
            if [ $? -eq 0 ] && [ -f "$filename" ] && [ -s "$filename" ]; then
                if file "$filename" | grep -q "image"; then
                    notify-send "🎨 Google Backdrop" "Photo $((current_index + 1)) of $total_urls\n<i>From cached collection</i>" \
                        -u normal -t 4000 -i "$filename" 2>/dev/null || true
                    echo "$filename"
                    return 0
                fi
            fi
            
            echo "❌ Failed to download cached URL, fetching new collection..." >&2
            # Fall through to fetch new collection
        else
            echo "✅ Completed collection! Fetching new batch..." >&2
            # Fall through to fetch new collection
        fi
    fi
    
    # Fetch new collection from Google
    echo "📡 Fetching new Google Backdrop collection..." >&2
    
    # Chromecast backdrop HTML page
    local backdrop_url="https://clients3.google.com/cast/chromecast/home"
    
    # Make request to get the HTML page
    local response
    response=$(curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" "$backdrop_url")
    
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        echo "❌ Failed to fetch from Google Backdrop page" >&2
        return 1
    fi
    
    # Extract image URLs from the JSON data embedded in JavaScript
    # The data is in initialStateJson with escaped URLs
    local image_urls
    image_urls=$(echo "$response" | grep -oP 'https:\\\/\\\/ccp-lh\.googleusercontent\.com\\\/chromecast-private-photos\\\/[A-Za-z0-9_-]+' | sed 's/\\//g' | head -50)
    
    if [ -z "$image_urls" ]; then
        echo "❌ No chromecast-private-photos URLs found in JSON" >&2
        echo "Debug: Trying alternative extraction methods..." >&2
        # Try without escaped slashes
        image_urls=$(echo "$response" | grep -oP 'https://ccp-lh\.googleusercontent\.com/chromecast-private-photos/[A-Za-z0-9_-]+' | head -50)
        if [ -z "$image_urls" ]; then
            echo "❌ No images found at all in response" >&2
            echo "Debug: First 1000 chars of response:" >&2
            echo "$response" | head -c 1000 >&2
            return 1
        fi
    fi
    
    # Build array and save to file
    local urls_array=()
    > "$BACKDROP_URLS_FILE"  # Clear the file
    
    while IFS= read -r url; do
        # Remove any trailing characters, backslashes, and existing params
        url=$(echo "$url" | sed 's/\\//g' | sed 's/[,;")].*$//' | sed 's/=w[0-9].*$//')
        
        # Skip if it's a CSS/JS file or too short
        if [[ ! "$url" =~ \.(css|js)$ ]] && [ ${#url} -gt 50 ]; then
            # Add high quality parameters and save to file
            local hq_url="${url}=w2560-h1440-p-k-no-nd-mv"
            echo "$hq_url" >> "$BACKDROP_URLS_FILE"
            urls_array+=("$hq_url")
        fi
    done <<< "$image_urls"
    
    if [ ${#urls_array[@]} -eq 0 ]; then
        echo "❌ No valid image URLs in array" >&2
        return 1
    fi
    
    echo "🆕 Found ${#urls_array[@]} new backdrop images" >&2
    
    # Start from index 0
    echo "0" > "$BACKDROP_INDEX_FILE"
    
    # Download the first image
    local image_url="${urls_array[0]}"
    local filename="$BACKDROP_CACHE_DIR/backdrop_0.jpg"
    
    echo "⬇️ Downloading Google Backdrop photo (1/${#urls_array[@]})" >&2
    curl -s \
        -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" \
        -H "Referer: https://clients3.google.com/" \
        "$image_url" -o "$filename"
    
    if [ $? -eq 0 ] && [ -f "$filename" ] && [ -s "$filename" ]; then
        # Verify it's actually an image
        if file "$filename" | grep -q "image"; then
            # Send desktop notification with icon
            notify-send "🎨 Google Backdrop" "New collection: ${#urls_array[@]} photos\n<i>Photo 1 of ${#urls_array[@]}</i>" \
                -u normal -t 4000 -i "$filename" 2>/dev/null || true
            
            # Update index to 1 for next time
            echo "1" > "$BACKDROP_INDEX_FILE"
            
            echo "$filename"
            return 0
        else
            echo "❌ Downloaded file is not an image" >&2
            return 1
        fi
    else
        echo "❌ Failed to download image or file is empty" >&2
        notify-send "Wallpaper Error" "Failed to download Backdrop image" \
            -u critical -t 3000 -i dialog-error 2>/dev/null || true
        return 1
    fi
}

# Function to fetch popular horizontal image from Pexels
fetch_pexels_wallpaper() {
    local query="$1"
    
    # If no query provided, use predefined list
    if [ -z "$query" ]; then
        local queries=("trees" "mountains" "quote" "water" "animals" "landscape" "beach" "forest" "sky" "wildlife" "Green" "Night" "Nature" "Cute-Animals" "Clouds")
        local random_index=$((RANDOM % ${#queries[@]}))
        query="${queries[$random_index]}"
    fi
    
    # Random page from popular content (pages 1-50 for best results)
    local random_page=$((RANDOM % 10 + 1))
    
    # Use search endpoint with popularity sorting
    local url="https://api.pexels.com/v1/search?query=$query&orientation=landscape&per_page=80&page=$random_page"
    
    echo "📡 Fetching popular '$query' wallpapers from Pexels (page $random_page)..." >&2
    
    # Make API request
    local response
    response=$(curl -s -H "Authorization: $PEXELS_API_KEY" "$url")
    
    if [ $? -ne 0 ] || [ -z "$response" ]; then
        echo "❌ Failed to fetch from Pexels API" >&2
        return 1
    fi
    
    # Get all landscape/horizontal image URLs
    local image_urls
    image_urls=$(echo "$response" | grep -o '"original":"[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$image_urls" ]; then
        echo "❌ No images found in API response" >&2
        return 1
    fi
    
    # Convert to array and pick a random one
    local urls_array=()
    while IFS= read -r url; do
        urls_array+=("$url")
    done <<< "$image_urls"
    
    if [ ${#urls_array[@]} -eq 0 ]; then
        echo "❌ No images in array" >&2
        return 1
    fi
    
    # Select random image from the results
    local random_img_index=$((RANDOM % ${#urls_array[@]}))
    local image_url="${urls_array[$random_img_index]}"
    
    # Extract photographer name for attribution
    local photographer
    photographer=$(echo "$response" | grep -o '"photographer":"[^"]*"' | sed -n "$((random_img_index + 1))p" | cut -d'"' -f4)
    
    # Always use the same filename - new download replaces old one
    local filename="$PEXELS_CACHE_DIR/current_pexels_wallpaper.jpg"
    
    # Download image (will overwrite previous one)
    echo "⬇️ Downloading popular '$query' wallpaper by ${photographer:-Unknown} (image $((random_img_index + 1))/${#urls_array[@]})" >&2
    curl -s -H "Authorization: $PEXELS_API_KEY" "$image_url" -o "$filename"
    
    if [ $? -eq 0 ] && [ -f "$filename" ]; then
        # Send desktop notification with icon
        notify-send "🎨 Popular Wallpaper" "Photo by <b>${photographer:-Unknown}</b>\n<i>$query</i>" \
            -u normal -t 4000 -i "$filename" 2>/dev/null || true
        echo "$filename"
        return 0
    else
        echo "❌ Failed to download image" >&2
        notify-send "Wallpaper Error" "Failed to download Pexels image" \
            -u critical -t 3000 -i dialog-error 2>/dev/null || true
        return 1
    fi
}

# Handle Google Backdrop mode
if [ "$mode" = "backdrop" ] || [ "$mode" = "google" ]; then
    backdrop_wallpaper=$(fetch_backdrop_wallpaper)
    
    if [ $? -eq 0 ] && [ -n "$backdrop_wallpaper" ]; then
        wall="$backdrop_wallpaper"
        echo "🎨 Using Google Backdrop wallpaper: $wall" >&2
    else
        echo "❌ Failed to fetch Google Backdrop wallpaper" >&2
        notify-send "Backdrop Fetch Failed" "Could not download wallpaper from Google Backdrop\n<i>Check your internet connection</i>" \
            -u critical -t 5000 -i dialog-error 2>/dev/null || true
        exit 1
    fi
# Handle Pexels modes
elif [ "$mode" = "pexels" ] || [ "$mode" = "search" ]; then
    if [ "$mode" = "search" ]; then
        # Custom search query provided
        pexels_wallpaper=$(fetch_pexels_wallpaper "$search_query")
    else
        # Random from predefined list
        pexels_wallpaper=$(fetch_pexels_wallpaper "")
    fi
    
    if [ $? -eq 0 ] && [ -n "$pexels_wallpaper" ]; then
        wall="$pexels_wallpaper"
        echo "🎨 Using popular Pexels wallpaper: $wall" >&2
    else
        echo "❌ Failed to fetch Pexels wallpaper" >&2
        notify-send "Pexels Fetch Failed" "Could not download wallpaper from Pexels\n<i>Check your internet connection</i>" \
            -u critical -t 5000 -i dialog-error 2>/dev/null || true
        exit 1
    fi
else
    # Handle local wallpaper directory (default/left-click behavior)
    dir="$WALLPAPER_DIR_MAIN"
    
    # Get all wallpapers in the directory (sorted)
    mapfile -t wallpapers < <(find "$dir" -type f | sort)
    
    # Exit if no wallpapers found
    if [ ${#wallpapers[@]} -eq 0 ]; then
        echo "⚠️ No wallpapers found in $dir" >&2
        exit 1
    fi
    
    # Read last index or start from -1
    if [ -f "$STATE_FILE" ]; then
        last_index=$(<"$STATE_FILE")
    else
        last_index=-1
    fi
    
    # Calculate next index
    next_index=$(((last_index + 1) % ${#wallpapers[@]}))
    wall="${wallpapers[$next_index]}"
    
    # Save next index for the next click
    echo "$next_index" >"$STATE_FILE"
    
    # Send notification for local wallpapers
    notify-send "Wallpaper Changed" "<b>$(basename "$wall")</b>\n<i>Local wallpaper ${next_index}/${#wallpapers[@]}</i>" \
        -u normal -t 3000 -i "$wall" 2>/dev/null || true
fi
# --- SET WALLPAPER SAFELY ---

pkill swaybg

# Fully detach swaybg
nohup swaybg -i "$wall" -m fill >/dev/null 2>&1 &
disown

# --- RUN PYWAL ASYNC (VERY IMPORTANT) ---
(
  wal -i "$wall" -n -q -e -t

  # small delay to avoid race condition
  sleep 0.3

  pkill -USR2 waybar

  # update kitty
  if [ -f "$HOME/.cache/wal/sequences" ]; then
    cat "$HOME/.cache/wal/sequences"
  fi
) >/dev/null 2>&1 &

disown