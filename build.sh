#!/usr/bin/env bash
# Type-check, bundle and zip one target.
#   ./build.sh web     -> dist/ and dist.zip                (Lambda Web Function)
#   ./build.sh lambda  -> dist-lambda/ and dist-lambda.zip  (classic Lambda + Function URL)
set -euo pipefail
cd "$(dirname "$0")"

case "${1:?usage: build.sh web|lambda}" in
  web) DIST=dist; CONFIG=rolldown.config.mjs ;;
  lambda) DIST=dist-lambda; CONFIG=rolldown.lambda.config.mjs ;;
  *) echo "usage: build.sh web|lambda" >&2; exit 1 ;;
esac

[[ -d node_modules ]] || pnpm install --frozen-lockfile
rm -rf "$DIST" "$DIST.zip"
# tsc only type-checks; rolldown strips types without checking them.
pnpm exec tsc -p tsconfig.json --noEmit
pnpm exec rolldown -c "$CONFIG"

# The Web Function bundle is ESM index.js; without "type": "module" Node would load it as CommonJS.
[[ "$DIST" != dist ]] || echo '{"type":"module"}' > dist/package.json

(cd "$DIST" && zip -qr -X "../$DIST.zip" . -x '.*' -x '*/.*')
echo "built $DIST.zip ($(wc -c < "$DIST.zip" | tr -d ' ') bytes)"
