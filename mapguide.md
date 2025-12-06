# Map Configuration Guide

Each map uses a `.tres` resource file. Just tell me the tile coordinates and I'll update the file.

## Files

```
game/resources/maps/
├── map_endless.tres      # Endless mode (forest - already configured)
├── map_challenge_1.tres  # Challenge 1 (empty - needs config)
├── map_challenge_2.tres  # Challenge 2
├── map_challenge_3.tres  # Challenge 3
├── map_challenge_4.tres  # Challenge 4
└── map_challenge_5.tres  # Challenge 5
```

---

## What to Tell Me

When you have a new tileset, provide:

### 1. Tileset Path
```
tileset: "res://assets/enviro/your_tileset.png"
```

### 2. Floor Tiles (2-6 variations)
```
floor: (6,4), (6,14), (7,14), (8,14)
```

### 3. Edge Tiles (arena border - 8 tiles)
```
edges:
  top: (3,6)
  bottom: (3,8)
  left: (2,7)
  right: (4,7)
  corners: (2,6), (4,6), (2,8), (4,8)  # TL, TR, BL, BR
```

### 4. Water/Hazard Tiles (9 tiles)
```
water:
  center: (6,7)
  top: (6,6), bottom: (6,8), left: (5,7), right: (7,7)
  corners: (5,6), (7,6), (5,8), (7,8)  # TL, TR, BL, BR
```

### 5. Path/Road Tiles (9 tiles)
```
path:
  center: (6,1)
  top: (6,0), bottom: (6,2), left: (5,1), right: (7,1)
  corners: (5,0), (7,0), (5,2), (7,2)  # TL, TR, BL, BR
```

### 6. Top Border (2 tiles)
```
border: edge (2,11), fill (2,10)
```

### 7. Decorations (optional)
```
decorations: (6,19), (7,19), (8,19)
```

### 8. Assets (PNG paths)
```
obstacles:
  - "res://assets/enviro/folder/tree1.png"
  - "res://assets/enviro/folder/tree2.png"

lamp: "res://assets/enviro/folder/lamp.png"

chest:
  - "res://assets/enviro/folder/chest_closed.png"
  - "res://assets/enviro/folder/chest_opening.png"
  - "res://assets/enviro/folder/chest_open.png"
```

### 9. Light Color (optional)
```
light: warm orange (1.0, 0.85, 0.6)
       or blue crystal (0.4, 0.6, 1.0)
       or green poison (0.4, 1.0, 0.5)
```

---

## Example Message

```
Configure challenge_1:

tileset: "res://assets/enviro/dungeon_tileset.png"

floor: (2,3), (3,3), (4,3)

edges: top (5,0), bottom (5,2), left (4,1), right (6,1)
       corners: (4,0), (6,0), (4,2), (6,2)

water: center (8,4)
       top (8,3), bottom (8,5), left (7,4), right (9,4)
       corners: (7,3), (9,3), (7,5), (9,5)

path: center (1,1)
      top (1,0), bottom (1,2), left (0,1), right (2,1)
      corners: (0,0), (2,0), (0,2), (2,2)

border: edge (0,5), fill (0,6)

decorations: (10,2), (11,2), (12,2)

obstacles: "res://assets/enviro/dungeon/pillar1.png", "res://assets/enviro/dungeon/pillar2.png"
lamp: "res://assets/enviro/dungeon/torch.png"
chest: "res://assets/enviro/dungeon/chest1.png", "res://assets/enviro/dungeon/chest2.png", "res://assets/enviro/dungeon/chest3.png"

light: red/orange (1.0, 0.5, 0.3)
```

I'll update the .tres file with those values.
