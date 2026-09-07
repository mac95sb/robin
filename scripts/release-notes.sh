#!/usr/bin/env bash
set -euo pipefail
version=${1:-HEAD}
if [[ "$version" != HEAD && ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Expected HEAD or a version such as v1.0.0 or v1.1.0-rc.1" >&2
  exit 1
fi
: "${OPENAI_API_KEY:?Set OPENAI_API_KEY for Communiqué}"
: "${COMMUNIQUE_MODEL:?Set COMMUNIQUE_MODEL to an OpenAI model with tool calling}"
mkdir -p .robin/releases
mise exec github:jdx/communique@1.3.5 -- communique generate "$version" \
  --model "$COMMUNIQUE_MODEL" --dry-run --output ".robin/releases/$version.md"
test -s ".robin/releases/$version.md"
