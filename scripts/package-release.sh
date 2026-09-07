#!/usr/bin/env bash
set -euo pipefail
case "$(uname -s)-$(uname -m)" in
  Linux-x86_64) platform=linux-x86_64 ;;
  Linux-aarch64) platform=linux-aarch64 ;;
  Darwin-arm64) platform=macos-aarch64 ;;
  *) echo "Unsupported release platform" >&2; exit 1 ;;
esac
flags=(-c release --product robin)
if [[ "$platform" == linux-* ]]; then flags+=(--static-swift-stdlib); fi
swift build "${flags[@]}"
binary="$(swift build -c release --show-bin-path)/robin"
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp "$binary" "$stage/robin"
git archive HEAD Templates | tar -xf - -C "$stage"
"$stage/robin" --help >/dev/null
mkdir "$stage/check"
for template in blank blog marketing dashboard api-service; do
  (cd "$stage/check" && "$stage/robin" init "Check${template//-/}" --template "$template")
  test -f "$stage/check/Check${template//-/}/Package.swift"
done
mkdir -p .robin/releases
tar -czf ".robin/releases/robin-$platform.tar.gz" -C "$stage" robin Templates
