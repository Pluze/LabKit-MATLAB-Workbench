#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INCLUDE_GUI=0
SUITES=()
TESTS=()

usage() {
    cat <<'USAGE'
Usage: scripts/run_matlab_tests.sh [--gui] [--suite NAME] [--test NAME]

Runs the default pure-function MATLAB tests.

Options:
  --gui         Also include optional noninteractive GUI launch/layout tests.
                This mode requires MATLAB graphics/uifigure support and does not
                use the default headless -nojvm/-nodisplay/-noFigureWindows flags.
  --suite NAME  Run only a suite target, for example labkit/dta or apps/electrochem. Repeatable.
                Suite targets are directories under tests/suites; selecting a
                parent target such as labkit or apps includes child suites.
                The special gui target selects all GUI tests.
  --test NAME   Run only a test function, for example test_gui_layout_ui_anchor_curve_editor.
                Repeatable. test_gui_* automatically uses GUI MATLAB flags.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --gui)
            INCLUDE_GUI=1
            shift
            ;;
        --suite)
            if [[ $# -lt 2 ]]; then
                echo "--suite requires a value." >&2
                usage >&2
                exit 2
            fi
            SUITES+=("$2")
            if [[ "$2" == "gui" ]]; then
                INCLUDE_GUI=1
            fi
            shift 2
            ;;
        --test)
            if [[ $# -lt 2 ]]; then
                echo "--test requires a value." >&2
                usage >&2
                exit 2
            fi
            TESTS+=("$2")
            if [[ "$2" == test_gui_* ]]; then
                INCLUDE_GUI=1
            fi
            shift 2
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

matlab_cell() {
    if [[ $# -eq 0 ]]; then
        printf '{}'
        return 0
    fi

    local out="{"
    local value
    for value in "$@"; do
        value="${value//\'/\'\'}"
        out+="'$value',"
    done
    out="${out%,}}"
    printf '%s' "$out"
}

LOG_FILE="${MATLAB_TEST_LOG:-$ROOT_DIR/matlab_test.log}"
if [[ ${#SUITES[@]} -gt 0 ]]; then
    SUITE_CELL="$(matlab_cell "${SUITES[@]}")"
else
    SUITE_CELL="$(matlab_cell)"
fi
if [[ ${#TESTS[@]} -gt 0 ]]; then
    TEST_CELL="$(matlab_cell "${TESTS[@]}")"
else
    TEST_CELL="$(matlab_cell)"
fi
if [[ "$INCLUDE_GUI" -eq 1 ]]; then
    MATLAB_FLAGS="${MATLAB_GUI_FLAGS:-}"
    TEST_EXPR="runLabKitTests('IncludeGui', true, 'Suites', $SUITE_CELL, 'Tests', $TEST_CELL, 'IncludeLegacy', true, 'FailIfNoTests', false);"
else
    MATLAB_FLAGS="${MATLAB_FLAGS:--nojvm -nodisplay -noFigureWindows}"
    TEST_EXPR="runLabKitTests('IncludeGui', false, 'Suites', $SUITE_CELL, 'Tests', $TEST_CELL, 'IncludeLegacy', true, 'FailIfNoTests', false);"
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
