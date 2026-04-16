#!/bin/bash
# Wrapper script: use this instead of bare `flutter` commands.
# Automatically ensures the build symlink is correct before every flutter invocation.
# Usage: ./flutter_run.sh [flutter args...]
#   ./flutter_run.sh run -d "3B088CFD-27B0-45A7-A06B-6BCE421FDDA6"
#   ./flutter_run.sh clean
#   ./flutter_run.sh build ios

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/ensure_build_symlink.sh"

flutter "$@"

# Re-ensure symlink after commands like `flutter clean` that delete build/
"$SCRIPT_DIR/ensure_build_symlink.sh"
