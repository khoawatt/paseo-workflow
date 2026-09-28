#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v node >/dev/null 2>&1 || { printf 'BLOCKED: Node.js 24 LTS is required\n' >&2; exit 1; }
node -e 'const [major,minor]=process.versions.node.split(".").map(Number);process.exit(major<24||major>=27||(major===24&&minor<21)?1:0)' \
  || { printf 'BLOCKED: Node.js >=24.21.0 <27 is required\n' >&2; exit 1; }
exec node "$ROOT_DIR/src/cli.ts" "$@"
