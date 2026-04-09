#!/usr/bin/env bash
set -eo pipefail

# Build zip archives for Claude Web & Desktop App upload.
# Simple skills (SKILL.md only) are zipped as-is.
# Complex skills (with references/ or scripts/) are bundled into a single archive.
# Output: dist/<skill-name>.zip

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
SKILLS="mist-sle mist-device-inventory mist-client-analysis mist-client-troubleshoot mist-network-issues mist-network-config mist-switch-port"

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Build zip archives for uploading skills to Claude Web & Desktop App.

Options:
  -s, --skill NAME  Build a single skill (e.g., mist-sle)
  -c, --clean       Remove dist/ before building
  -l, --list        List skills and their archive type
  -h, --help        Show this help

Output: dist/<skill-name>.zip
EOF
}

list_skills() {
  echo "Skills and archive contents:"
  for skill in $SKILLS; do
    local src="$SCRIPT_DIR/skills/$skill"
    if [ -d "$src/references" ] || [ -d "$src/scripts" ]; then
      echo "  $skill (archive: SKILL.md + references/)"
    else
      echo "  $skill (archive: SKILL.md only)"
    fi
  done
}

build_skill() {
  local skill="$1"
  local src="$SCRIPT_DIR/skills/$skill"
  local out="$DIST_DIR/$skill.zip"

  if [ ! -d "$src" ]; then
    echo "  SKIP  $skill (not found)"
    return
  fi

  rm -f "$out"
  (cd "$src" && zip -r "$out" . -x '.*' > /dev/null 2>&1)
  local size
  size=$(du -h "$out" | cut -f1 | tr -d ' ')
  echo "  OK    $skill.zip ($size)"
}

# Parse arguments
CLEAN=false
SINGLE=""

while [ $# -gt 0 ]; do
  case "$1" in
    -s|--skill)
      SINGLE="$2"; shift 2 ;;
    -c|--clean)
      CLEAN=true; shift ;;
    -l|--list)
      list_skills; exit 0 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Clean
if [ "$CLEAN" = true ]; then
  rm -rf "$DIST_DIR"
fi

mkdir -p "$DIST_DIR"

# Build
if [ -n "$SINGLE" ]; then
  build_skill "$SINGLE"
else
  echo "Building skill archives..."
  echo ""
  for skill in $SKILLS; do
    build_skill "$skill"
  done
  echo ""
  echo "Archives saved to dist/"
fi
