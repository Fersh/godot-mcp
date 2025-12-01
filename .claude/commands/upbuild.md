# Increment Build Number

Increment the build number by 1 across all version/build files in the project.

## Files to Update (all paths relative to game/)

1. **game/export_presets.cfg** (line ~36): `application/version="X"` → increment X by 1
2. **game/export_presets.cfg** (line ~304): `version/code=X` → increment X by 1
3. **game/Rogue Arena.xcodeproj/project.pbxproj**: All occurrences of `CURRENT_PROJECT_VERSION = X;` → increment X by 1
4. **game/Rogue Arena.xcarchive/Info.plist**: `<key>CFBundleVersion</key><string>X</string>` → increment X by 1
5. **game/DistributionSummary.plist**: `<key>buildNumber</key><string>X</string>` → increment X by 1

## Instructions

1. Read the current version from `game/export_presets.cfg` (iOS application/version)
2. Calculate new version (current + 1)
3. Update ALL files listed above with the new version number
4. Report which files were updated and the old → new version numbers
