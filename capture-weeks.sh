#!/bin/bash
# Marketing capture driver. WeekShotsTests shoots each week's detail view in
# portrait and the full-screen viewer in landscape.
#
#   ./capture-weeks.sh "iPhone 17 Pro Max" "1,5,52,66" landscape 1
#
# args: device, weeks, SHOT (portrait|landscape|both), HIDE_CHROME (0|1)
#
# HIDE_CHROME=1 opens the full-screen viewer bare, for store slides that carry
# a composed caption instead of the app's own title bar.
set -euo pipefail

DEVICE="${1:-iPhone 17 Pro Max}"
WEEKS="${2:-1}"
SHOT="${3:-both}"
HIDE="${4:-0}"

SLUG=$(echo "$DEVICE" | tr '[:upper:] ' '[:lower:]-')
OUT="build/captures/weekshots/$SLUG"
RESULT="build/captures/$SLUG.xcresult"
rm -rf "$RESULT" "$OUT"
mkdir -p "$OUT"

# TEST_RUNNER_* must be in xcodebuild's OWN environment. Passing them as
# `KEY=value` arguments sets build settings instead, which the test process
# never sees — and the run still passes, silently using every default. That is
# how a request for seven weeks quietly captured one.
export TEST_RUNNER_WEEKS="$WEEKS"
export TEST_RUNNER_HIDE_CHROME="$HIDE"
if [ "$SHOT" != "both" ]; then
  export TEST_RUNNER_SHOT="$SHOT"
else
  unset TEST_RUNNER_SHOT
fi

xcodebuild test -scheme Burfords -derivedDataPath build/dd \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -only-testing:BurfordsUITests/WeekShotsTests/testCaptureWeeks \
  -resultBundlePath "$RESULT" 2>&1 \
  | grep -E "Executed [0-9]+ test|error:|XCTAssert" | head -5 || true

xcrun xcresulttool export attachments --path "$RESULT" --output-path "$OUT" >/dev/null
python3 scripts/name-attachments.py "$OUT"
python3 scripts/check-orientation.py "$OUT"
