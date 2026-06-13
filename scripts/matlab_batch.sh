#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
    cat <<'USAGE'
Usage: scripts/matlab_batch.sh MATLAB_COMMAND

Finds MATLAB, changes to the LabKit repository root, and runs MATLAB_COMMAND
with MATLAB -batch.

Examples:
  scripts/matlab_batch.sh "buildtool test"
  scripts/matlab_batch.sh "buildtool testProject"
  scripts/matlab_batch.sh "buildtool listTasks"

Environment:
  MATLAB_CMD Optional path or command name for MATLAB.
USAGE
}

if [[ $# -ne 1 || "$1" == "-h" || "$1" == "--help" ]]; then
    usage
    if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
        exit 0
    fi
    exit 2
fi

find_matlab() {
    if [[ -n "${MATLAB_CMD:-}" ]]; then
        printf '%s\n' "$MATLAB_CMD"
        return 0
    fi

    if command -v matlab >/dev/null 2>&1; then
        command -v matlab
        return 0
    fi

    local candidate
    for candidate in /Applications/MATLAB_*.app/bin/matlab; do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

matlab_literal() {
    local value="$1"
    value="${value//\'/\'\'}"
    printf "'%s'" "$value"
}

MATLAB_BIN="$(find_matlab || true)"
if [[ -z "$MATLAB_BIN" ]]; then
    echo "MATLAB executable not found. Set MATLAB_CMD=/path/to/matlab." >&2
    exit 127
fi

exec "$MATLAB_BIN" -batch "cd($(matlab_literal "$ROOT_DIR")); $1;"
