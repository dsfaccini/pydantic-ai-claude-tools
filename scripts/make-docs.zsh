make-docs() {
    # the fucking cairo shit always fucking fails so this command helps
    export DYLD_FALLBACK_LIBRARY_PATH="/opt/homebrew/lib"
    export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/share/pkgconfig"
    local port=$((RANDOM % 1000 + 8000))
    uv run mkdocs serve --no-strict --dev-addr "127.0.0.1:$port"
}
