# Superfile: cd to last browsed directory on quit
spf() {
    local SPF_LAST_DIR="$HOME/Library/Application Support/superfile/lastdir"
    rm -f "$SPF_LAST_DIR"
    command spf "$@"
    if [ -f "$SPF_LAST_DIR" ]; then
        # superfile writes "cd '/path/to/dir'" — eval it directly
        eval "$(cat "$SPF_LAST_DIR")"
        rm -f "$SPF_LAST_DIR"
    fi
}
