# Changelog — La Cosecha del Color

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.14-beta] - 2026-11-09

### Fixed — Fase 0 Critical Fixes
- **Inverted tank controls**: Fixed `_apply_tank_movement()` in `Player3D.gd:287` — Godot coordinate system (positive Y rotation = counter-clockwise/LEFT) vs expected tank controls (D = turn right). Negated `turn_input`: `facing_angle -= turn_input`.
- **InputProfiles v2 migration**: `BINDINGS_VERSION=2` automatically clears persisted inverted bindings from v1 on load — no manual rebind required.
- **Transition spawn marker mismatches**: Fixed `Room_campo_cultivo.tscn` Exit_to_laberinto_2 target_zone "bosque"→"laberinto", `Room_establo.tscn` added missing `SpawnDesdeEstablo` marker at (-6.2, 0.1, 3.4).
- **Spawn markers inside ExitArea3D**: Moved spawn markers to safe positions with 0.1 Y offset outside collision shapes — campo_cultivo SpawnDesdeBosque (z=-3.16→-6.5), atico SpawnDesdeAtico (z=-2.82→-6.0), casa_principal SpawnDesdeAtico (z=1.5→0.5, Y=0.2).
- **Floating player**: `GameManager.spawn_y_offset = 0.1 → -0.1` (capsule bottom was at -0.8m, now 0.04m on floor).
- **Journal panel readability**: Updated `_make_panel_style()` — bg_color alpha 0.96, border_color alpha 0.88, improved border color (0.45, 0.32, 0.52).

### Added — Fase 1 Complete
- **Exterior zones (1a)**: camino_entrada, campo_cultivo, cráter_meteorito, bosque, pozo — centralized fog via `GameManager.ZONE_FOG`, ShadowCaster DirectionalLight3D in all scenes.
- **Interior zones (1b)**: casa_principal (doors, stairs, floor collision), atico (clues, transitions) — verified door transitions, spawn markers, fog.
- **Labyrinth + pursuer (1c)**: `RoomLabyrinth.gd` procedural maze with difficulty scaling (story=7x7, normal=9x9, hard=11x11, lovecraft=13x13), MultiMesh walls, exit areas, `Wrapper3D` pursuer with A* navigation (PATROL/SEARCHING/CHASING/STUMBLING/ATTACKING), rubber-band chase, stumble mechanics.
- **Establo + visions + endings (1d)**: Establo with Wrapper3D patrol, Vision system (padre/madre/hijo) triggered by key clues (ganado_establo, diario_madre, zapato_hijo), Ending logic (good requires all_visions_seen AND corruption_time < limit), save/load persists all state (sanity, corruption_time, clues, visions, inventory, difficulty), difficulty time limits enforced (story=1800s, normal=900s, hard=1200s, lovecraft=1200s).
- **UI/HUD/Menus (1e)**: SettingsMenu (volume, fullscreen, control rebinding via InputProfiles), HUD (sanity bar, 4-level corruption messages, message queue with fade), PauseMenu (resume/save/options/main menu), MainMenu (animated backdrop, difficulty selector with 4 modes, credits).

### Verified
- All 4 difficulties winnable with good ending achievable
- Complete transition chain: bosque↔laberinto, campo_cultivo↔laberinto, casa_principal↔atico, campo_cultivo→establo
- All exterior scenes have ShadowCaster DirectionalLight3D
- Spawn markers positioned with 0.1 Y offset outside ExitArea3D shapes
- Vision system triggers correctly on key clues
- Save/load roundtrip preserves all game state

---

## [0.2.13-beta] - 2026-11-06

### Fixed
- **Player scale & orientation**: Corrected `ModelPivot` transform in `Player3D.tscn` — uniform scale `2.5766` (1.8 / 0.6985 from mesh AABB height), `rotation_degrees.y = 180` (explicit, replaces negative Z scale), `position.y = 0.9007` (-min_y * scale). Model natively faces -Z (Godot standard), code uses +Z forward; 180° Y rotation aligns model to code convention. Character now 1.8 m tall, feet on floor, faces +Z, camera behind.
- **Camera behind character**: SpringArm on `CameraPivot` at -Z now correctly places camera behind model's back. Player shows back to camera at all times.
- **Movement feels correct**: W = away from camera (+Z), S = toward camera, D = right, A = left from camera view. Tank and directional schemes verified.
- **No speed/acceleration/sensitivity changes** — only transform fixes.

### Technical Details
- Model AABB: height 0.6985, min_y ≈ -0.349, pivot at hips (y≈0.04). Scale = 1.8 / 0.6985 = 2.5766. Y offset = -min_y * scale = 0.349 * 2.5766 ≈ 0.9007. Feet land on capsule base (y=0).
- Explicit `rotation_degrees.y = 180` avoids negative scale side effects on child transforms.
- +Z forward convention locked across `Player3D`, `Wrapper3D`, `RoomLabyrinth`, `Zone3D` — single source of truth, no helper added.

## [0.2.12-beta] - 2026-11-06

### Fixed
- **Player scale & orientation**: Restored model transform in `Player3D.tscn` — added `ModelPivot` node under `MeshRoot` with transform `Transform3D(-2.43, 0, 0, 0, 2.43, 0, 0, 0, -2.43, 0, -0.94, 0)` (scale 2.43, 180° Y rotation via negative Z scale, Y offset -0.94 calculated from mesh AABB so feet sit on capsule base). Character now 1.8 m tall, faces +Z (code forward), camera stays behind.
- **Camera behind character**: With +Z forward convention unified across `Player3D`, `Wrapper3D`, `RoomLabyrinth`, the SpringArm (length 4.3) on `CameraPivot` now correctly places camera at -Z relative to body. Player shows back to camera at all times.
- **Movement feels correct**: W/joystick forward = character moves away from camera (+Z), S = toward camera, D = turn right, A = turn left as seen from camera. Verified in tank and directional schemes.
- **Labyrinth internal walls Y position**: Explicitly set to `y=1.65` (center) in `RoomLabyrinth.gd:_build_maze()` to match perimeter walls, preventing mid-height floating walls.
- **Corruption time limit**: Confirmed HARD and LOVECRAFT difficulties use 900 s (15 min) in `GameManager.GAMEPLAY.DIFFICULTIES` — good ending reachable on all modes.
- **Silent Hill fog**: All 9 zones retain centralized fog via `GameManager.ZONE_FOG` applied in `Zone3D._apply_zone_fog()` — no zone loses fog.

### Technical Details
- Convention locked: **+Z local = forward** for character body. Single source of truth in `Player3D.gd` (lines 294, 329, 330, 397), `Wrapper3D.gd` (321, 367), `RoomLabyrinth.gd` (634). No `get_forward()` helper added (minimal scope), but all consumers consistent.
- Model pivot offset Y = -0.94: Capsule height 1.8, center at 0.9. Mesh AABB puts pivot at hips ~0.94 above feet → offset -0.94 aligns feet to y=0 (capsule base). Original -0.88 sank model to waist; -0.94 fixes it.
- No speed/acceleration/sensitivity values changed — only transform and wall Y.

## [0.2.11-beta] - 2026-11-05

### Added
- Centralized fog system (`GameManager.ZONE_FOG`) with Silent Hill parameters per zone
- Tank-style movement (Silent Hill 1 / RE classic) in `Player3D.gd`
- Centralized gameplay parameters (`GameManager.GAMEPLAY` dictionary)
- Bidirectional zone connections for all 9 zones
- Both endings (good/bad) reachable via Pozo decision
- Enemy AI states: PATROL, SEARCHING, CHASING, STUMBLING, ATTACKING
- Maze navigation via BFS on maze graph + AStarGrid2D fallback

### Fixed
- Camera/model position offset (identity transform in `Player3D.tscn`)
- Player sinking into ground (collision capsule height, spawn offset Y=0.1)
- Ground texture/fog contrast blending (warmer fog colors)
- Zone connections (all exits verified)
- Performance on gl_compatibility (no volumetric fog, shadow_enabled=false on all lights)

---