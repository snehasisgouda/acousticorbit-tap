# acousticorbit-tap

The system-audio tap that ships inside [Acoustic Orbit](https://acousticorbit.com/),
a macOS app that plays the speakers you already own as one array. The tap is a
CoreAudio HAL driver: it appears as the audio device **"Acoustic Orbit"**, the app
reads what the Mac plays from it, and video players read a published latency
from it so the picture waits for the sound.

It is a modified version of **BlackHole**, © 2019 Existential Audio Inc.,
https://github.com/ExistentialAudio/BlackHole, used under the GNU General
Public License, version 3. It is not BlackHole, does not use the BlackHole
name for its device, and is not made or endorsed by Existential Audio Inc.
The list of modifications, with dates, is in [NOTICE](NOTICE); the licence
is [LICENSE](LICENSE).

## What is here

| File | Role |
| --- | --- |
| `LCRTap.c` | the driver (BlackHole's `BlackHole.c`, modified; the original header is kept) |
| `Info.plist` | the bundle's plist; `CFBundleVersion` is the driver version the app compares |
| `build.sh` | builds `AcousticOrbitTap.driver` with the production defines |
| `readlayout.swift` | a small instrument that prints the channel layout the installed driver serves |
| `NOTICE`, `LICENSE` | origin, modifications, licence |

## Build

Apple silicon or Intel Mac with the command-line tools (Xcode's SDK is used when
installed; the Command Line Tools 27.0 SDK fails at link time):

```sh
sh build.sh
```

This produces `AcousticOrbitTap.driver`. Installing it by hand needs root and
restarts the system audio daemon, which pauses all sound for a moment and stops
AirPlay:

```sh
sudo cp -R AcousticOrbitTap.driver /Library/Audio/Plug-Ins/HAL/
sudo chown -R root:wheel /Library/Audio/Plug-Ins/HAL/AcousticOrbitTap.driver
sudo killall coreaudiod
```

Acoustic Orbit's Setup does the same with one administrator prompt, and
Engineer › Setup extras removes it again.

## Same source, two places

This repository mirrors the `tools/tap` folder of the app's private repository;
the app bundles these files next to the compiled driver. Changes land here with
every driver version the app ships.

## Contact

hello@acousticorbit.com
