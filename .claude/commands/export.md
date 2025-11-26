Export the Godot project for iOS.

Run the following command to export the project:

```bash
mkdir -p ~/Downloads/Godot && /Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/mark/Downloads/devloc/rogue-2/godot-mcp/game --export-debug "iOS" ~/Downloads/Godot/RogueArena.xcodeproj
```

After running, inform the user:
1. The exported Xcode project location: ~/Downloads/Godot/RogueArena.xcodeproj
2. Next steps: Open in Xcode, select their team for signing, connect their iPhone, and click Run

If the export fails due to missing export templates, tell the user to:
1. Download templates from: https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_export_templates.tpz
2. In Godot: Editor → Manage Export Templates → Install from File
