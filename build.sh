#!/bin/sh
# Build the system-audio tap HAL driver with the PRODUCTION defines.
#
# 20 Oct 2026, version 4 (the rebrand, docs/rebrand-spec-2026-10-20.md,
# section 2 — the owner's ruling: identities too): driver name
# AcousticOrbitTap (the UID root: AcousticOrbitTap_UID,
# AcousticOrbitTap_2_UID, AcousticOrbitTap_ModelUID), device
# "Acoustic Orbit", hidden mirror "Acoustic Orbit Mirror", manufacturer
# "Acoustic Orbit", bundle id com.acousticorbit.tap (Info.plist says the
# same: LCRTap.c finds its own bundle by this id), bundle
# AcousticOrbitTap.driver with executable AcousticOrbitTap, 16 channels,
# the descriptions layout of version 3. Until version 3 the identity was
# "Speaker LCR" / SpeakerLCRTap_UID / com.snehasis.speakerlcr.tap in
# SpeakerLCRTap.driver; Setup's install removes that bundle in the same
# root step (TapInstaller.shellScript), and the app accepts both names
# and both UIDs until every Mac runs version 4 (TapPreference).
#
# 1 Oct 2026 (install story A): the bundle is assembled here from
# tracked sources — tools/tap/Info.plist is the driver's plist (the
# bundle directory itself is gitignored). Its CFBundleVersion is the
# version the app compares (bundled copy vs the one installed in
# /Library/Audio/Plug-Ins/HAL) to offer "Update the tap": BUMP IT
# (an integer, 1 → 2 → …) WITH EVERY CHANGE TO LCRTap.c that should
# reach installed Macs. ship.sh runs this script whenever LCRTap.c,
# Info.plist or this script is newer than the built binary, then
# copies the bundle into the app at Contents/Resources/driver/.
#
# Install: the app's Setup does it ("Install the system-audio tap",
# TapInstaller.swift — one administrator prompt: copy, chown
# root:wheel, restart coreaudiod). By hand (needs sudo; the coreaudiod
# restart blips ALL system audio):
#   sudo rm -rf /Library/Audio/Plug-Ins/HAL/SpeakerLCRTap.driver   (version 3 and older)
#   sudo cp -R AcousticOrbitTap.driver /Library/Audio/Plug-Ins/HAL/
#   sudo chown -R root:wheel /Library/Audio/Plug-Ins/HAL/AcousticOrbitTap.driver
#   sudo killall coreaudiod
set -e
cd "$(dirname "$0")"
# 1 Oct 2026: the Command Line Tools 27.0 SDK fails at link time
# (its Accelerate.tbd), the same toolchain break ship.sh guards against
# for SwiftUI macros. Prefer Xcode's SDK when it is installed; an
# SDKROOT already in the environment wins.
if [ -z "$SDKROOT" ]; then
  if [ -z "$DEVELOPER_DIR" ] && [ -d /Applications/Xcode.app/Contents/Developer ]; then
    export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
  fi
  SDKROOT=$(xcrun --sdk macosx --show-sdk-path 2>/dev/null) && export SDKROOT
fi
DRV=AcousticOrbitTap.driver
# The bundle id and the executable name are said twice (Info.plist and
# the defines below); a mismatch would build a driver that cannot find
# its own bundle, so stop before compiling.
PB=/usr/libexec/PlistBuddy
[ "$($PB -c 'Print :CFBundleIdentifier' Info.plist)" = "com.acousticorbit.tap" ] \
  || { echo "Info.plist CFBundleIdentifier is not com.acousticorbit.tap" >&2; exit 1; }
[ "$($PB -c 'Print :CFBundleExecutable' Info.plist)" = "AcousticOrbitTap" ] \
  || { echo "Info.plist CFBundleExecutable is not AcousticOrbitTap" >&2; exit 1; }
mkdir -p "$DRV/Contents/MacOS"
cp Info.plist "$DRV/Contents/Info.plist"
clang -bundle -o "$DRV/Contents/MacOS/AcousticOrbitTap" \
  -DkDriver_Name='"AcousticOrbitTap"' \
  -DkHas_Driver_Name_Format=false \
  -DkDevice_Name='"Acoustic Orbit"' \
  -DkDevice2_Name='"Acoustic Orbit Mirror"' \
  -DkManufacturer_Name='"Acoustic Orbit"' \
  -DkNumber_Of_Channels=16 \
  -DkPlugIn_BundleID='"com.acousticorbit.tap"' \
  -DkPlugIn_Icon='""' \
  LCRTap.c \
  -framework CoreAudio -framework CoreFoundation -framework Accelerate \
  -O2
codesign --force --sign - "$DRV"
echo "built: $DRV (CFBundleVersion $($PB -c 'Print :CFBundleVersion' Info.plist))"
