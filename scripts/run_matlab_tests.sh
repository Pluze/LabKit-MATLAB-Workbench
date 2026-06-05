#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS=()

usage() {
    cat <<'USAGE'
Usage: scripts/run_matlab_tests.sh [TASK ...]

Runs LabKit MATLAB build tasks. With no TASK arguments, runs `buildtool test`.

Examples:
  scripts/run_matlab_tests.sh
  scripts/run_matlab_tests.sh checkStyle
  scripts/run_matlab_tests.sh testUnit coverage
  scripts/run_matlab_tests.sh testGuiStructural

Common tasks:
  checkStyle
  test
  testUnit
  testIntegration
  testProject
  testLabkitDta
  testLabkitBiosignal
  testLabkitUi
  testLabkitUiGui
  testAppsElectrochem
  testAppsElectrochemGui
  testAppsDicGui
  testAppsImageMeasurement
  testAppsImageMeasurementGui
  testAppsWearableGui
  testAppsGui
  testAppsSmokeGui
  testGuiStructural
  testGuiGesture
  coverage
  checkProject
  packageDryRun

Removed interface:
  --suite, --test, and --gui are no longer supported. Use build task names.

Environment:
  MATLAB_CMD      Optional path or command name for MATLAB.
  MATLAB_FLAGS    Optional MATLAB flags for every run.
  MATLAB_TEST_LOG Optional log path. Defaults to ./matlab_test.log.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "Unsupported option: $1. Use build task names such as checkStyle, test, or testGuiStructural." >&2
            usage >&2
            exit 2
            ;;
        *)
            if [[ ! "$1" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
                echo "Invalid build task name: $1" >&2
                usage >&2
                exit 2
            fi
            TASKS+=("$1")
            shift
            ;;
    esac
done

if [[ ${#TASKS[@]} -eq 0 ]]; then
    TASKS=(test)
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
    echo "MATLAB executable not found. Set MATLAB_CMD=/path/to/matlab and retry." >&2
    exit 127
fi

LOG_FILE="${MATLAB_TEST_LOG:-$ROOT_DIR/matlab_test.log}"
TASK_TEXT="${TASKS[*]}"

echo "Using MATLAB: $MATLAB_BIN"
echo "Project root: $ROOT_DIR"
echo "Build tasks: $TASK_TEXT"
echo "MATLAB log: $LOG_FILE"

MATLAB_FLAG_ARGS=()
if [[ -n "${MATLAB_FLAGS:-}" ]]; then
    read -r -a MATLAB_FLAG_ARGS <<< "$MATLAB_FLAGS"
fi

rm -f "$LOG_FILE"

set +e
"$MATLAB_BIN" "${MATLAB_FLAG_ARGS[@]}" -logfile "$LOG_FILE" -batch "cd($(matlab_literal "$ROOT_DIR")); buildtool $TASK_TEXT;"
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
    echo "MATLAB build tasks completed successfully. Log: $LOG_FILE"
elif [[ -f "$LOG_FILE" ]]; then
    cat "$LOG_FILE"
else
    echo "MATLAB did not create log file: $LOG_FILE" >&2
fi

exit "$status"
