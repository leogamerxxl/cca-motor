#!/usr/bin/env bash
# Launches the Perplexity MCP server (https://github.com/wynandw87/claude-code-perplexity-mcp)
# pinned to a reviewed commit. On first run it clones and builds that commit into a
# per-user cache; later runs start the cached build directly.
# stdout is the MCP stdio channel, so all build output goes to stderr.
set -euo pipefail

REPO_URL="https://github.com/wynandw87/claude-code-perplexity-mcp.git"
COMMIT="4221feecc5d54ca3ee5b2368aa88221468160d99"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/perplexity-mcp/$COMMIT"

if [ ! -f "$CACHE_DIR/dist/index.js" ]; then
  {
    echo "perplexity-mcp: building $COMMIT into $CACHE_DIR"
    mkdir -p "$(dirname "$CACHE_DIR")"
    tmp="$(mktemp -d "${CACHE_DIR}.tmp.XXXXXX")"
    git -C "$tmp" init -q
    git -C "$tmp" fetch -q --depth 1 "$REPO_URL" "$COMMIT"
    git -C "$tmp" checkout -q FETCH_HEAD
    # npm ci runs the package's "prepare" script, which compiles src/ to dist/.
    (cd "$tmp" && npm ci --no-audit --no-fund --loglevel=error)
    [ -f "$tmp/dist/index.js" ] || { echo "perplexity-mcp: build produced no dist/index.js"; exit 1; }
    rm -rf "$CACHE_DIR"
    mv "$tmp" "$CACHE_DIR"
  } 1>&2
fi

exec node "$CACHE_DIR/dist/index.js"
