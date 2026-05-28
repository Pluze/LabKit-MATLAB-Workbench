#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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
MATLAB_FLAGS="${MATLAB_FLAGS:--nojvm -nodisplay -noFigureWindows}"
read -r -a MATLAB_FLAG_ARGS <<< "$MATLAB_FLAGS"
rm -f "$LOG_FILE"

set +e
"$MATLAB_BIN" "${MATLAB_FLAG_ARGS[@]}" -logfile "$LOG_FILE" -batch "cd('$ROOT_DIR'); addpath(fullfile(pwd, 'tests')); run_all_tests();"
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
