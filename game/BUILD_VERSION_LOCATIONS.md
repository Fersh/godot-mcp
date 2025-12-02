# Build & Version Update Locations

Reference file for updating build numbers and version strings across the project.

## Build Number Locations (8 files)

### 1. Main Menu Display
- **File:** `scripts/main_menu.gd`
- **Line:** `const BUILD = X`
- **Format:** Integer

### 2. iOS Export (Application Version)
- **File:** `export_presets.cfg`
- **Search:** `application/version=`
- **Format:** String `"X"`

### 3. Android Export (Version Code)
- **File:** `export_presets.cfg`
- **Search:** `version/code=`
- **Format:** Integer

### 4. Distribution Summary
- **File:** `DistributionSummary.plist`
- **Key:** `<key>buildNumber</key>` followed by `<string>X</string>`
- **Format:** String in XML plist

### 5. Archive Info
- **File:** `Rogue Arena.xcarchive/Info.plist`
- **Key:** `CFBundleVersion`
- **Format:** String in XML plist

### 6. dSYM Info
- **File:** `Rogue Arena.xcarchive/dSYMs/Rogue Arena.app.dSYM/Contents/Info.plist`
- **Key:** `CFBundleVersion`
- **Format:** String in XML plist

### 7. App Bundle Info (Binary Plist)
- **File:** `Rogue Arena.xcarchive/Products/Applications/Rogue Arena.app/Info.plist`
- **Key:** `CFBundleVersion`
- **Format:** Binary plist - use `plutil -replace CFBundleVersion -string "X" <file>`

### 8. Xcode Project (Debug & Release)
- **File:** `Rogue Arena.xcodeproj/project.pbxproj`
- **Key:** `CURRENT_PROJECT_VERSION = X;` (appears twice - Debug and Release configs)
- **Format:** Plain text, update both occurrences

---

## Version String Locations

When updating the version (e.g., 1.0.0 → 1.1.0):

| File | Key/Field |
|------|-----------|
| `export_presets.cfg` | `application/short_version` (iOS) |
| `export_presets.cfg` | `version/name` (Android) |
| `DistributionSummary.plist` | `versionNumber` |
| `Rogue Arena.xcarchive/Info.plist` | `CFBundleShortVersionString` |
| `Rogue Arena.xcarchive/dSYMs/.../Info.plist` | `CFBundleShortVersionString` |
| `Rogue Arena.xcarchive/Products/.../Info.plist` | `CFBundleShortVersionString` (binary) |

---

## Quick Commands

**Find all build number references:**
```bash
grep -r "BUILD\|buildNumber\|CFBundleVersion\|version/code\|application/version\|CURRENT_PROJECT_VERSION" --include="*.gd" --include="*.cfg" --include="*.plist" --include="*.pbxproj" .
```

**Update binary plist:**
```bash
plutil -replace CFBundleVersion -string "NEW_BUILD" "Rogue Arena.xcarchive/Products/Applications/Rogue Arena.app/Info.plist"
```

---

## Important Notes

- **Close Xcode before editing** `project.pbxproj` - Xcode will overwrite changes if it's open
- The `.xcarchive` files are regenerated on each archive build, so they may reset to old values
