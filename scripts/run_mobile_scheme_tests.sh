#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="MatrixMaster.xcworkspace"
SCHEME="MatrixMasterMobile"
IPHONE_DESTINATION='platform=iOS Simulator,name=iPhone 17'
IPAD_DESTINATION='platform=iOS Simulator,name=iPad (A16)'
IPHONE_SIMULATOR_NAME='iPhone 17'
IPAD_SIMULATOR_NAME='iPad (A16)'
LOG_ROOT="${TMPDIR:-/tmp}/matrixmaster-mobile-tests"
mkdir -p "$LOG_ROOT"

IPHONE_LOG="$LOG_ROOT/iphone17.log"
IPHONE_RETRY_LOG="$LOG_ROOT/iphone17-retry.log"
IPAD_LOG="$LOG_ROOT/ipad-a16.log"
IPAD_RETRY_LOG="$LOG_ROOT/ipad-a16-retry.log"

run_xcodebuild_test() {
    local destination="$1"
    local output_log="$2"

    set +e
    xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -destination "$destination" test | tee "$output_log"
    local status=${PIPESTATUS[0]}
    set -e

    return "$status"
}

is_transient_launch_failure() {
    local output_log="$1"
    rg -a -q \
        -e "Application failed preflight checks" \
        -e "Simulator device failed to launch com\\.matrixmaster\\.mobile" \
        -e "Restarting after unexpected exit, crash, or test timeout" \
        -e "Unable to monitor animations" \
        -e "Unable to monitor event loop" \
        "$output_log"
}

reset_simulator() {
    local simulator_name="$1"
    xcrun simctl shutdown "$simulator_name" >/dev/null 2>&1 || true
    xcrun simctl erase "$simulator_name"
    xcrun simctl boot "$simulator_name"
    xcrun simctl bootstatus "$simulator_name" -b
}

run_destination_with_retry() {
    local simulator_name="$1"
    local destination="$2"
    local output_log="$3"
    local retry_log="$4"

    echo "Running MatrixMasterMobile tests on $simulator_name..."
    if run_xcodebuild_test "$destination" "$output_log"; then
        echo "$simulator_name tests passed."
        return 0
    fi

    if is_transient_launch_failure "$output_log"; then
        echo "Detected transient launch/test-runner failure on $simulator_name. Resetting simulator and retrying once..."
        reset_simulator "$simulator_name"
        if run_xcodebuild_test "$destination" "$retry_log"; then
            echo "$simulator_name tests passed after simulator reset retry."
            return 0
        fi
        echo "$simulator_name tests failed after simulator reset retry. See: $retry_log"
        return 1
    fi

    echo "$simulator_name tests failed for a non-transient reason. See: $output_log"
    return 1
}

run_destination_with_retry "$IPHONE_SIMULATOR_NAME" "$IPHONE_DESTINATION" "$IPHONE_LOG" "$IPHONE_RETRY_LOG"
run_destination_with_retry "$IPAD_SIMULATOR_NAME" "$IPAD_DESTINATION" "$IPAD_LOG" "$IPAD_RETRY_LOG"
