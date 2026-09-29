# Broken Banjo – graybox demo (Chapter 1: The Postcard)

Press **F5** in Godot (main scene = `scenes/UI/TitleScreen.tscn`).

## Controls
- **Left click** floor: walk. **Left click** a thing: walk there and use / talk / pick up.
- **Right click** a thing: Dave looks at it.
- **Inventory bar** (bottom): left click an item to hold it on the cursor, then left click
  something in the room to use it on that, or another item to combine them.
  Right click an item to look at it. Right click anywhere drops the held item.
- During cutscenes, left click skips the current line.

## Walkthrough
1. Apartment: pick up the **Postcard** by the door, open the **Desk** (UV torch),
   search the **Bookshelf** (passport). Hold the UV torch and click the postcard in the
   bar → *Decoded postcard*. Leave by the **Front door**.
2. Street:
   - Good ending: pick up **Something in the gutter** (boarding pass), then use it on
     **Rosa** (or talk to her and pick "Found this in the gutter..."). She tips Dave off.
   - Take the **Taxi to the airport** (needs the passport).
3. Airport: click the **Check-in desk** (plane ticket).
   - Tipped off: use the **Decoded postcard** on the **Man with newspaper** (or the **Bin**
     next to him). He reads the fake Reykjavik message and leaves. Click **Gate 7** → GOOD ENDING.
   - Not tipped off: click **Gate 7** → OMINOUS ENDING ("He's on the plane.").

## How the pieces fit
| File | What it does |
|---|---|
| `core/autoload/game_state.gd` | **GameState** autoload: inventory, flags, current room, spawn point, signals. |
| `core/autoload/room_changer.gd` | **RoomChanger** autoload: fade out → change scene → fade in. |
| `scenes/UI/Hud.tscn` + `hud.gd` | **Hud** autoload: inventory bar, hover name, held item, combining. |
| `core/systems/item_db.gd` | All items (name, colour, look text) and item+item combinations. |
| `core/systems/hotspot.gd` | **Hotspot** (Area2D): name, look/use text, pickups, dialogue, flag visibility. |
| `core/systems/exit_hotspot.gd` | **ExitHotspot**: door to another room + optional required items/flags. |
| `core/systems/room.gd` | **Room** base: clicks, hover, walk-then-act, `say()`, `start_dialogue()`, `go_to_room()`. |
| `core/systems/speech_label.gd` | Floating speech text with auto-hide (Dave and NPCs). |
| `scenes/rooms/Room_*.tscn/.gd` | The three rooms. Puzzle logic lives in each room's `on_interact` / `on_use_item`. |
| `dialogue/rosa.dialogue` | Rosa's conversation (Dialogue Manager). |
| `scenes/UI/DialogueBalloon.tscn` | Our dialogue balloon (set in Project Settings → Dialogue Manager → Runtime). |
| `tests/TestWalkthrough.tscn` | Headless test of both endings. |
| `tests/ScreenshotRooms.tscn` | Saves a screenshot of every screen to `user://screenshots`. |

### Adding a new hotspot
1. In a room, right click `Hotspots` → Add Child Node → **Hotspot** (or ExitHotspot).
2. Give it a **CollisionPolygon2D** child (draw the clickable area) and a **Marker2D** child named `WalkTo`.
3. Fill in *Display Name* and *Look Text* in the Inspector. For an item, set *Pickup Item* to an id from `item_db.gd`.
4. Need special behaviour? Add a case to the room script's `on_interact()` / `on_use_item()`.

### Running the tests (PowerShell, in the project folder)
```
& "C:\Users\andre\Desktop\Godot_v4.7.2-stable_win64.exe" --headless res://tests/TestWalkthrough.tscn | Out-String
```
