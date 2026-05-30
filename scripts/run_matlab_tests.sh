#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INCLUDE_GUI=0
SUITES=()
TESTS=()
PROFILES=()

usage() {
    cat <<'USAGE'
Usage: scripts/run_matlab_tests.sh [--gui] [--profile NAME] [--suite NAME] [--test NAME]

Runs the default pure-function MATLAB tests.

Options:
  --gui         Also include optional noninteractive GUI launch/layout tests.
                This mode requires MATLAB graphics/uifigure support and does not
                use the default headless -nojvm/-nodisplay/-noFigureWindows flags.
  --profile NAME
                Run a focused profile. Repeatable.
                Profiles: core, dta, apps, electrochem, dic, image_measurement, ui, gui, all.
  --suite NAME  Run only a suite key: core, dta, apps, or gui. Repeatable.
  --test NAME   Run only a test function, for example test_gui_layout_controls.
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
        --profile)
            if [[ $# -lt 2 ]]; then
                echo "--profile requires a value." >&2
                usage >&2
                exit 2
            fi
            PROFILES+=("$2")
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

append_suite() {
    SUITES+=("$1")
}

append_test() {
    TESTS+=("$1")
}

apply_profile() {
    case "$1" in
        core)
            append_suite core
            ;;
        dta)
            append_suite core
            append_suite dta
            ;;
        apps)
            append_suite apps
            ;;
        electrochem)
            INCLUDE_GUI=1
            append_test test_chronoOverlayExport
            append_test test_computeVTResistance
            append_test test_vtResistanceExport
            append_test test_computeCIC
            append_test test_cicExport
            append_test test_computeCSC
            append_test test_plotXY
            append_test test_eisOverlayExport
            append_test test_gui_layout_electrochem
            ;;
        dic)
            INCLUDE_GUI=1
            append_test test_gui_layout_dic
            ;;
        image_measurement)
            INCLUDE_GUI=1
            append_test test_imageCurvatureMeasurement
            append_test test_gui_layout_image_measurement
            ;;
        ui)
            INCLUDE_GUI=1
            append_test test_gui_layout_ui_helpers
            ;;
        gui)
            INCLUDE_GUI=1
            append_suite gui
            ;;
        all)
            INCLUDE_GUI=1
            ;;
        *)
            echo "Unknown profile: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
}

if [[ ${#PROFILES[@]} -gt 0 ]]; then
    for profile in "${PROFILES[@]}"; do
        apply_profile "$profile"
    done
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
    TEST_EXPR="run_all_tests(true, struct('suites', {$SUITE_CELL}, 'tests', {$TEST_CELL}));"
else
    MATLAB_FLAGS="${MATLAB_FLAGS:--nojvm -nodisplay -noFigureWindows}"
    TEST_EXPR="run_all_tests(false, struct('suites', {$SUITE_CELL}, 'tests', {$TEST_CELL}));"
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
