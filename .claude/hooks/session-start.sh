#!/bin/bash
# SessionStart hook for Claude Code on the web: installs the shared toolset
# (graphify, headroom, omniroute) and starts OmniRoute on loopback.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

export PATH="$HOME/.local/bin:$PATH"

command -v graphify >/dev/null 2>&1 || uv tool install graphifyy
graphify install >/dev/null

command -v headroom >/dev/null 2>&1 || uv tool install --python 3.13 "headroom-ai[all]"

command -v omniroute >/dev/null 2>&1 || npm install -g omniroute --no-audit --no-fund
if ! curl -s -o /dev/null --max-time 2 http://127.0.0.1:20128/; then
  OMNIROUTE_SERVER_HOST=127.0.0.1 nohup omniroute > /tmp/omniroute.log 2>&1 &
  for _ in $(seq 1 30); do
    curl -s -o /dev/null --max-time 2 http://127.0.0.1:20128/ && break
    sleep 1
  done
fi

echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "${CLAUDE_ENV_FILE:-/dev/null}"
echo "export OMNIROUTE_BASE_URL=http://127.0.0.1:20128" >> "${CLAUDE_ENV_FILE:-/dev/null}"
