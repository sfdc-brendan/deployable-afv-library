#!/usr/bin/env bash
#
# Agentforce Vibes Library installer
#
# Installs every skill in this repository into Claude Code, Codex, and Cursor
# at the user-global scope using the `skills` CLI (https://agentskills.io).
#
# Quick install:
#   curl -fsSL https://raw.githubusercontent.com/sfdc-brendan/deployable-afv-library/main/scripts/install.sh | bash
#
# Options (via env vars when piping, or flags when running locally):
#   TOOLS="claude-code,codex,cursor"   # which agents to install into (default: all three)
#   SOURCE="sfdc-brendan/deployable-afv-library"  # skills source repo (default)
#   --uninstall                        # remove the skills instead of installing
#   --dry-run                          # print the commands without executing
#   --help                             # show this help text

set -euo pipefail

DEFAULT_TOOLS="claude-code,codex,cursor"
DEFAULT_SOURCE="sfdc-brendan/deployable-afv-library"

TOOLS="${TOOLS:-$DEFAULT_TOOLS}"
SOURCE="${SOURCE:-$DEFAULT_SOURCE}"
ACTION="install"
DRY_RUN="false"

print_help() {
  sed -n '/^# Agentforce Vibes Library installer/,/show this help text/p' "$0" \
    | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tools)        TOOLS="$2"; shift 2 ;;
    --tools=*)      TOOLS="${1#*=}"; shift ;;
    --source)       SOURCE="$2"; shift 2 ;;
    --source=*)     SOURCE="${1#*=}"; shift ;;
    --uninstall)    ACTION="uninstall"; shift ;;
    --dry-run)      DRY_RUN="true"; shift ;;
    -h|--help)      print_help; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      print_help >&2
      exit 1
      ;;
  esac
done

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    red "Required command not found: $1"
    case "$1" in
      node|npx) echo "Install Node.js 18+ from https://nodejs.org or via your package manager." ;;
    esac
    exit 1
  fi
}

require_cmd node
require_cmd npx

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    yellow "[dry-run] $*"
  else
    eval "$@"
  fi
}

bold "Agentforce Vibes Library — ${ACTION}"
echo "  Source: $SOURCE"
echo "  Tools:  $TOOLS"
echo

IFS=',' read -ra TOOL_ARR <<< "$TOOLS"
AGENT_FLAGS=""
for t in "${TOOL_ARR[@]}"; do
  t="${t#"${t%%[![:space:]]*}"}"
  t="${t%"${t##*[![:space:]]}"}"
  [[ -z "$t" ]] && continue
  AGENT_FLAGS+=" --agent '$t'"
done

if [[ "$ACTION" == "install" ]]; then
  run "npx --yes skills add '$SOURCE' --global$AGENT_FLAGS --skill '*' --yes"
  green "Done. Restart your AI tool to load the new skills."
else
  run "npx --yes skills remove --global$AGENT_FLAGS --skill '*' --yes"
  green "Removed AFV skills from: $TOOLS"
fi
