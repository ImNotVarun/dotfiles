function bang
    set -l query (string join "+" $argv)
    xdg-open "https://duckduckgo.com/?q=$query"
end
