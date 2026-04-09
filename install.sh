#!/usr/bin/env bash
set -eo pipefail

# Mist AI MCP Skills installer
# Copies skill directories into the skill path for the selected AI application.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS="mist-sle mist-device-inventory mist-client-analysis mist-client-troubleshoot mist-network-issues mist-network-config mist-switch-port"

# Application names, paths, and labels (parallel arrays)
APP_NAMES="claude goose trae gemini copilot"
APP_COUNT=5

get_app_path() {
  case "$1" in
    claude)  echo "$HOME/.claude/skills" ;;
    goose)   echo "$HOME/.goose/skills" ;;
    trae)    echo "$HOME/.trae/skills" ;;
    gemini)  echo "$HOME/.agents/skills" ;;
    copilot) echo "$HOME/.copilot/skills" ;;
    *)       return 1 ;;
  esac
}

get_app_label() {
  case "$1" in
    claude)  echo "Claude Code    (~/.claude/skills)" ;;
    goose)   echo "Goose / Block     (~/.goose/skills)" ;;
    trae)    echo "TRAE              (~/.trae/skills)" ;;
    gemini)  echo "Gemini CLI        (~/.agents/skills)" ;;
    copilot) echo "GH Copilot        (~/.copilot/skills)" ;;
  esac
}

usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Install Mist AI MCP skills for your AI application.

Options:
  -a, --app APP     Install for a specific app: claude, goose, trae, gemini, copilot
  -d, --dest DIR    Install to a custom directory
  -l, --list        List available skills
  -u, --uninstall   Remove installed skills
  -h, --help        Show this help

If no option is given, an interactive menu is shown.

Examples:
  $0                      # Interactive menu
  $0 -a claude            # Install for Claude Code
  $0 -a goose             # Install for Goose
  $0 -d /path/to/skills   # Install to custom path
  $0 -u -a claude         # Uninstall from Claude Code
EOF
}

list_skills() {
  echo "Available skills:"
  for skill in $SKILLS; do
    desc=$(sed -n 's/^name: *//p' "$SCRIPT_DIR/skills/$skill/SKILL.md")
    echo "  $skill"
  done
}

install_skills() {
  local dest="$1"
  mkdir -p "$dest"
  local count=0
  for skill in $SKILLS; do
    local src="$SCRIPT_DIR/skills/$skill"
    if [ ! -d "$src" ]; then
      echo "  SKIP  $skill (not found)"
      continue
    fi
    cp -r "$src" "$dest/"
    echo "  OK    $skill"
    count=$((count + 1))
  done
  echo ""
  echo "Installed $count skills to $dest"
}

uninstall_skills() {
  local dest="$1"
  local count=0
  for skill in $SKILLS; do
    if [ -d "$dest/$skill" ]; then
      rm -rf "$dest/$skill"
      echo "  DEL   $skill"
      count=$((count + 1))
    fi
  done
  if [ "$count" -eq 0 ]; then
    echo "  No skills found in $dest"
  else
    echo ""
    echo "Removed $count skills from $dest"
  fi
}

interactive_menu() {
  echo "Mist AI MCP Skills Installer"
  echo ""
  echo "Select target application:"
  echo ""
  local i=1
  for app in $APP_NAMES; do
    echo "  $i) $(get_app_label "$app")"
    i=$((i + 1))
  done
  echo "  $i) Custom path"
  echo ""
  read -rp "Choice [1-$i]: " choice

  if [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -le "$APP_COUNT" ] 2>/dev/null; then
    local j=1
    for app in $APP_NAMES; do
      if [ "$j" -eq "$choice" ]; then
        local dest
        dest=$(get_app_path "$app")
        echo ""
        install_skills "$dest"
        return
      fi
      j=$((j + 1))
    done
  elif [ "$choice" -eq "$((APP_COUNT + 1))" ] 2>/dev/null; then
    read -rp "Enter path: " custom_path
    custom_path="${custom_path/#\~/$HOME}"
    echo ""
    install_skills "$custom_path"
  else
    echo "Invalid choice."
    exit 1
  fi
}

# Parse arguments
UNINSTALL=false
APP=""
DEST=""

while [ $# -gt 0 ]; do
  case "$1" in
    -a|--app)
      APP="$2"; shift 2 ;;
    -d|--dest)
      DEST="$2"; shift 2 ;;
    -l|--list)
      list_skills; exit 0 ;;
    -u|--uninstall)
      UNINSTALL=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

# Resolve destination
if [ -n "$DEST" ]; then
  TARGET="$DEST"
elif [ -n "$APP" ]; then
  TARGET=$(get_app_path "$APP") || { echo "Unknown app: $APP"; echo "Available: $APP_NAMES"; exit 1; }
else
  if [ "$UNINSTALL" = true ]; then
    echo "Specify --app or --dest for uninstall."
    exit 1
  fi
  interactive_menu
  exit 0
fi

# Execute
if [ "$UNINSTALL" = true ]; then
  uninstall_skills "$TARGET"
else
  install_skills "$TARGET"
fi
