#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INCLUDE_GUI=0

usage() {
    cat <<'USAGE'
Usage: scripts/run_matlab_tests.sh [--gui]

Runs the default pure-function MATLAB tests.

Options:
  --gui   Also run optional noninteractive GUI launch smoke tests.
          This mode requires MATLAB graphics/uifigure support and does not use
          the default headless -nojvm/-nodisplay/-noFigureWindows flags.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --gui)
            INCLUDE_GUI=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

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

MATLAB_BIN="$(find_matlab || true)"
if [[ -z "$MATLAB_BIN" ]]; then
    echo "MATLAB executable not found. Set MATLAB_CMD=/path/to/matlab and retry." >&2
    exit 127
fi

echo "Using MATLAB: $MATLAB_BIN"
echo "Project root: $ROOT_DIR"

LOG_FILE="${MATLAB_TEST_LOG:-$ROOT_DIR/matlab_test.log}"
if [[ "$INCLUDE_GUI" -eq 1 ]]; then
    MATLAB_FLAGS="${MATLAB_GUI_FLAGS:-}"
    TEST_EXPR="run_all_tests(true);"
else
    MATLAB_FLAGS="${MATLAB_FLAGS:--nojvm -nodisplay -noFigureWindows}"
    TEST_EXPR="run_all_tests(false);"
fi
MATLAB_FLAG_ARGS=()
if [[ -n "$MATLAB_FLAGS" ]]; then
    read -r -a MATLAB_FLAG_ARGS <<< "$MATLAB_FLAGS"
fi
rm -f "$LOG_FILE"

set +e
if [[ ${#MATLAB_FLAG_ARGS[@]} -gt 0 ]]; then
    "$MATLAB_BIN" "${MATLAB_FLAG_ARGS[@]}" -logfile "$LOG_FILE" -batch "cd('$ROOT_DIR'); addpath(fullfile(pwd, 'tests')); $TEST_EXPR"
else
    "$MATLAB_BIN" -logfile "$LOG_FILE" -batch "cd('$ROOT_DIR'); addpath(fullfile(pwd, 'tests')); $TEST_EXPR"
fi
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
    echo "MATLAB tests completed successfully. Log: $LOG_FILE"
elif [[ -f "$LOG_FILE" ]]; then
    cat "$LOG_FILE"
else
    echo "MATLAB did not create log file: $LOG_FILE" >&2
fi

exit "$status"
