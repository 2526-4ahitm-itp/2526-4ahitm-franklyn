Franklyn Sentinel - Portable (macOS)

Requirements:
- A Mac with Apple Silicon (M1 or newer) running macOS 14 (Sonoma) or newer.

Recommended install (no browser download, no sudo):
  curl -fsSL https://franklyn.htl-leonding.ac.at/scripts/sentinel-install.sh | bash

How to run this archive directly:
- run ./bin/franklyn

Downloaded with a web browser?
macOS marks browser downloads and refuses to start this build. Remove the
mark once, from the directory you extracted the archive into:
  xattr -dr com.apple.quarantine .

Screen Recording permission:
The first time you join an exam, macOS asks whether your terminal app may
record the screen. Turn it on under System Settings > Privacy & Security >
Screen & System Audio Recording, let macOS quit and reopen the terminal, then
run the command again.

Licenses:
The license for Franklyn Sentinel can be found in LICENSE and the license for
gstreamer can be found in GSTREAMER_LICENSE.
