App Store Connect screenshots for StepBeacon

The old copied screenshots from the pulse-monitor seed project were intentionally removed.
Generate fresh StepBeacon screenshots before App Store submission.

Folder "6.5-inch": final PNGs at 1284 x 2778 pixels for App Store Connect.
Folder "raw": original simulator captures before resize.

To regenerate:
1. Open Xcode project, select iPhone 17 Pro Max simulator.
2. Terminal from repo root:
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
     -project StepBeacon/StepBeacon.xcodeproj \
     -scheme StepBeacon \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' test
3. Capture the Today, Trends, and Settings screens from the simulator.
4. Save the originals in "raw" and export resized 1284 x 2778 PNGs into "6.5-inch".
