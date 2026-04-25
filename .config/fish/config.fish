# Initialize Starship prompt
if not status is-interactive
    return
end

set -g fish_greeting ""

fastfetch
starship init fish | source
zoxide init fish | source

# === Pywal colors for Fish ===
# Use colors.fish (this is the correct one for graphical terminals)
if test -f ~/.cache/wal/colors.fish
    source ~/.cache/wal/colors.fish
end

alias dotfiles='git --git-dir=/home/varun/.dotfiles/ --work-tree=/home/varun'
