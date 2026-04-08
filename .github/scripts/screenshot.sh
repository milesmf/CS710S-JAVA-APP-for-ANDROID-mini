#!/usr/bin/env bash
#
# Capture screenshots of cs710aquickstart on the booted emulator.
# Invoked by the screenshots job in .github/workflows/build.yml.
#
# Expects:
#   - emulator already booted (handled by reactivecircus/android-emulator-runner)
#   - APK downloaded to ./apk/ (handled by actions/download-artifact)
#
set -euo pipefail

PKG="com.csl.cs710aquickstart"
SHOTS_DIR="screenshots"

mkdir -p "$SHOTS_DIR"

echo "=== APK location ==="
ls -la apk/ || { echo "ERROR: apk/ directory missing"; exit 1; }

APK=$(find apk/ -type f -name "*.apk" | head -1)
if [ -z "$APK" ]; then
  echo "ERROR: No .apk file found under apk/"
  exit 1
fi
echo "Installing $APK"
adb install -r -t "$APK"

echo "=== Granting runtime permissions ==="
# Non-fatal — some perms may not exist on every API level
adb shell pm grant "$PKG" android.permission.BLUETOOTH_SCAN     || true
adb shell pm grant "$PKG" android.permission.BLUETOOTH_CONNECT  || true
adb shell pm grant "$PKG" android.permission.ACCESS_FINE_LOCATION   || true
adb shell pm grant "$PKG" android.permission.ACCESS_COARSE_LOCATION || true

# Capture one activity, tolerating launch failures so the rest still run.
capture() {
  local label="$1"
  local activity="$2"
  echo "--- Capturing $label ($activity) ---"
  if adb shell am start -n "$PKG/$activity"; then
    sleep 5
    if adb exec-out screencap -p > "$SHOTS_DIR/$label.png"; then
      echo "  saved $SHOTS_DIR/$label.png"
    else
      echo "  WARN: screencap failed for $label"
    fi
  else
    echo "  WARN: failed to launch $activity"
  fi
}

capture "01_main"      ".MainActivity"
capture "02_scan"      ".ScanActivity"
capture "03_inventory" ".InventoryActivity"
capture "04_geiger"    ".GeigerSearchActivity"

echo "=== Screenshot results ==="
ls -lh "$SHOTS_DIR/" || true
