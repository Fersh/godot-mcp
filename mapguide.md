# Procedural Map Tileset Guide

This document outlines all tile categories needed to create procedurally generated maps. When providing a new tileset, specify the tile coordinates for each category below.

## Tileset Format

All tile coordinates use the format: `(column, row)` where each tile is **32x32 pixels**.
- Example: `(6, 4)` means column 6, row 4 = pixel position `(192, 128)`
- To convert: `pixel_x = column * 32`, `pixel_y = row * 32`

---

## 1. FLOOR TILES (Required)

Main walkable ground tiles. Provide **2-6 variations** for visual variety.

**Purpose:** The base terrain players and enemies walk on.

```
floor_tiles:
  - (column, row)  # Variation 1
  - (column, row)  # Variation 2
  - (column, row)  # Variation 3 (optional)
  - (column, row)  # Variation 4 (optional)
  - (column, row)  # Variation 5 (optional)
  - (column, row)  # Variation 6 (optional)
```

**Current (forest_tileset.png):**
- `(6, 4)`, `(6, 14)`, `(7, 14)`, `(8, 14)`, `(6, 15)`, `(7, 15)`

---

## 2. OUTER EDGE TILES (Required)

Border tiles that define the arena boundary. Need **8 tiles** for all edge cases.

**Purpose:** Creates the visual border around the playable area.

```
outer_edges:
  top:          (column, row)  # Top edge (horizontal)
  bottom:       (column, row)  # Bottom edge (horizontal)
  left:         (column, row)  # Left edge (vertical)
  right:        (column, row)  # Right edge (vertical)
  top_left:     (column, row)  # Top-left corner
  top_right:    (column, row)  # Top-right corner
  bottom_left:  (column, row)  # Bottom-left corner
  bottom_right: (column, row)  # Bottom-right corner
```

**Current (forest_tileset.png):**
- top: `(3, 6)`, bottom: `(3, 8)`, left: `(2, 7)`, right: `(4, 7)`
- top_left: `(2, 6)`, top_right: `(4, 6)`, bottom_left: `(2, 8)`, bottom_right: `(4, 8)`

---

## 3. WATER/HAZARD TILES (Required)

Liquid or hazard tiles (water, lava, acid, void). Need **9 tiles** for center + all edges.

**Purpose:** Creates pools/lakes that block player movement.

```
water_tiles:
  center:       (column, row)  # Center (fully surrounded by water)
  top:          (column, row)  # Top edge
  bottom:       (column, row)  # Bottom edge
  left:         (column, row)  # Left edge
  right:        (column, row)  # Right edge
  top_left:     (column, row)  # Top-left corner
  top_right:    (column, row)  # Top-right corner
  bottom_left:  (column, row)  # Bottom-left corner
  bottom_right: (column, row)  # Bottom-right corner
```

**Current (forest_tileset.png):**
- center: `(6, 7)`
- top: `(6, 6)`, bottom: `(6, 8)`, left: `(5, 7)`, right: `(7, 7)`
- top_left: `(5, 6)`, top_right: `(7, 6)`, bottom_left: `(5, 8)`, bottom_right: `(7, 8)`

---

## 4. PATH/ROAD TILES (Optional)

Dirt paths or roads through the map. Need **9 tiles** for center + all edges.

**Purpose:** Creates walkable paths connecting different areas.

```
path_tiles:
  center:       (column, row)  # Center (fully surrounded by path)
  top:          (column, row)  # Top edge (path to grass transition)
  bottom:       (column, row)  # Bottom edge
  left:         (column, row)  # Left edge
  right:        (column, row)  # Right edge
  top_left:     (column, row)  # Top-left corner
  top_right:    (column, row)  # Top-right corner
  bottom_left:  (column, row)  # Bottom-left corner
  bottom_right: (column, row)  # Bottom-right corner
```

**Current (forest_tileset.png):**
- center: `(6, 1)`
- top: `(6, 0)`, bottom: `(6, 2)`, left: `(5, 1)`, right: `(7, 1)`
- top_left: `(5, 0)`, top_right: `(7, 0)`, bottom_left: `(5, 2)`, bottom_right: `(7, 2)`

---

## 5. TOP BORDER EXTENSION (Required)

Tiles that extend above the playable area (prevents camera from showing void).

**Purpose:** Fills the area above the map that the camera might see.

```
top_border:
  edge_row:    (column, row)  # First row above arena
  fill_row:    (column, row)  # Additional rows above (can be same tile)
```

**Current (forest_tileset.png):**
- edge_row: `(2, 11)`, fill_row: `(2, 10)`

---

## 6. SMALL DECORATIONS (Optional)

Scattered ground decorations. Provide **3-6 variations**.

**Purpose:** Visual variety on the floor (flowers, rocks, bones, etc.)

```
decorations:
  - tile: (column, row)
    type: "small"  # small, log, bones, etc.
  - tile: (column, row)
    type: "small"
  - tile: (column, row)
    type: "log"
```

**Current (forest_tileset.png):**
- small: `(6, 19)`, `(7, 19)`, `(8, 19)`
- log: `(7, 22)`, `(8, 22)`, `(9, 22)`

---

## 7. TALL GRASS/FOLIAGE (Optional)

Clustered vegetation that can overlay on characters. Need **9 tiles** per variant.

**Purpose:** Creates grass clusters that provide visual depth.

```
tall_grass_yellow:
  center: (column, row)      # Tall center piece
  base_tiles:                # 8 surrounding base tiles
    - (column, row)  # top-left
    - (column, row)  # top
    - (column, row)  # top-right
    - (column, row)  # left
    - (column, row)  # right
    - (column, row)  # bottom-left
    - (column, row)  # bottom
    - (column, row)  # bottom-right

tall_grass_green:
  center: (column, row)
  base_tiles:
    - (column, row)  # (same 8-tile pattern)
```

**Current (forest_tileset.png):**
- Yellow: center `(4, 18)`, base around `(3-5, 17-19)`
- Green: center `(1, 24)`, base around `(0-2, 23-25)`

---

## 8. OBSTACLE TEXTURES (Separate PNGs)

Large obstacles like trees, rocks, pillars. Provide **full PNG paths**.

**Purpose:** Destructible or solid obstacles that block movement.

```
trees:
  - "res://assets/enviro/[tileset]/Trees/Tree1.png"
  - "res://assets/enviro/[tileset]/Trees/Tree2.png"
  - "res://assets/enviro/[tileset]/Trees/Tree3.png"

rocks:
  - "res://assets/enviro/[tileset]/Rocks/Rock1.png"
  - "res://assets/enviro/[tileset]/Rocks/Rock2.png"
```

**Current:** `res://assets/enviro/gowl/Trees/Tree1.png`, `Tree2.png`, `Tree3.png`

---

## 9. LIGHTING FIXTURES (Separate PNG)

Light sources like lamps, torches, braziers.

**Purpose:** Ambient lighting and destructible light sources.

```
lamp: "res://assets/enviro/[tileset]/Lamp.png"
torch: "res://assets/enviro/[tileset]/Torch.png"

light_settings:
  color: Color(1.0, 0.85, 0.6)  # Warm orange
  energy: 0.5
  scale: 2.5
```

**Current:** `res://assets/enviro/gowl/Wooden/Lamp.png`

---

## 10. TREASURE CHEST (Separate PNGs)

Animated chest with 3 frames (closed, opening, open).

**Purpose:** Loot container that spawns once per map.

```
chest_frames:
  - "res://assets/enviro/[tileset]/Chest/1.png"  # Closed
  - "res://assets/enviro/[tileset]/Chest/2.png"  # Opening
  - "res://assets/enviro/[tileset]/Chest/3.png"  # Open
```

**Current:** `res://assets/enviro/gowl/Rocks and Chest/Chest/IronChest/1.png`, `2.png`, `3.png`

---

## MAP CONFIGURATION SETTINGS

```
map_settings:
  tile_scale: 2.0              # Scale multiplier for tiles
  arena_width_tiles: 48        # Width in tiles
  arena_height_tiles: 36       # Height in tiles
  border_thickness: 4          # Edge border width

  water_pool_count: 2          # Number of water pools
  water_pool_min_size: 2       # Minimum pool radius
  water_pool_max_size: 4       # Maximum pool radius

  tree_count: 20               # Number of trees
  tree_scale: 2.5              # Tree size multiplier
  tree_size_variation: [1.0, 2.0]  # Random scale range

  lamp_count: 8                # Number of lamps
  lamp_scale: 2.0              # Lamp size multiplier

  road_width: 2                # Road width in tiles
  decoration_density: 0.04     # Chance per tile (0.0-1.0)
```

---

## TEMPLATE FOR NEW TILESET

Copy and fill this out when adding a new tileset:

```yaml
tileset_name: "[Name]"
tileset_path: "res://assets/enviro/[folder]/tileset.png"
theme: "forest/dungeon/cave/desert/etc"

# Required Tiles
floor_tiles:
  - (?, ?)
  - (?, ?)

outer_edges:
  top: (?, ?)
  bottom: (?, ?)
  left: (?, ?)
  right: (?, ?)
  top_left: (?, ?)
  top_right: (?, ?)
  bottom_left: (?, ?)
  bottom_right: (?, ?)

water_tiles:
  center: (?, ?)
  top: (?, ?)
  bottom: (?, ?)
  left: (?, ?)
  right: (?, ?)
  top_left: (?, ?)
  top_right: (?, ?)
  bottom_left: (?, ?)
  bottom_right: (?, ?)

top_border:
  edge_row: (?, ?)
  fill_row: (?, ?)

# Optional Tiles
path_tiles:
  center: (?, ?)
  top: (?, ?)
  bottom: (?, ?)
  left: (?, ?)
  right: (?, ?)
  top_left: (?, ?)
  top_right: (?, ?)
  bottom_left: (?, ?)
  bottom_right: (?, ?)

decorations:
  - tile: (?, ?)
    type: "small"

# Separate Assets
trees:
  - "res://assets/enviro/[folder]/tree1.png"

lamp: "res://assets/enviro/[folder]/lamp.png"

chest_frames:
  - "res://assets/enviro/[folder]/chest_closed.png"
  - "res://assets/enviro/[folder]/chest_opening.png"
  - "res://assets/enviro/[folder]/chest_open.png"

# Theme-specific colors
light_color: Color(1.0, 0.85, 0.6)  # Warm for torches, blue for crystals, etc.
```

---

## NOTES

1. **Tile coordinates** are 0-indexed from top-left of tileset
2. **Edge tiles** should seamlessly connect to floor tiles
3. **Water edges** face OUTWARD (top edge = water on bottom, grass on top)
4. **Trees/obstacles** should have transparent backgrounds
5. **Chest frames** animate: closed (0.1s) -> opening (0.15s) -> open (0.2s)
6. **Lamps** need a clear "light source" point for PointLight2D placement
