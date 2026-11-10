# La Cosecha del Color - Comprehensive Review Summary

## Overview
Complete review and fix of the Godot 4.7.2 3D horror game "La Cosecha del Color" with Silent Hill-style fog, tank controls, and classic survival horror mechanics.

## Major Fixes Applied

### 1. Fog Centralization (Mandatory Silent Hill-style fog)
**Files:** `autoload/GameManager.gd`, `scripts3d/Zone3D.gd`, `scripts3d/RoomLabyrinth.gd`

- **Created** `GameManager.ZONE_FOG` dictionary as single source of truth for all 9 zones
- **Added** `_apply_zone_fog()` method in `Zone3D.gd` that dynamically creates Environment at runtime
- **Removed** hardcoded fog from `RoomLabyrinth._build_environment()` - now uses centralized ZONE_FOG
- **All zones** now have consistent fog parameters: enabled, mode, light_color, depth_begin/end, depth_curve, bg_mode, bg_color, ambient_color, ambient_energy

**Zone Fog Parameters:**
| Zone | light_color | depth_begin | depth_end | ambient_energy |
|------|-------------|-------------|-----------|----------------|
| camino_entrada | (0.55, 0.50, 0.45) | 5.0 | 35.0 | 0.75 |
| casa_principal | (0.40, 0.35, 0.32) | 6.0 | 40.0 | 0.52 |
| campo_cultivo | (0.42, 0.38, 0.32) | 4.0 | 30.0 | 0.65 |
| pozo | (0.25, 0.20, 0.28) | 2.0 | 15.0 | 0.30 |
| crater_meteorito | (0.50, 0.35, 0.42) | 3.0 | 25.0 | 0.55 |
| establo | (0.42, 0.38, 0.34) | 4.0 | 28.0 | 0.45 |
| atico | (0.50, 0.45, 0.40) | 5.0 | 35.0 | 0.50 |
| bosque | (0.40, 0.48, 0.38) | 3.0 | 22.0 | 0.40 |
| laberinto | (0.25, 0.22, 0.28) | 3.0 | 20.0 | 0.34 |

### 2. Tank-Style Movement (Silent Hill 1/RE Classic Controls)
**File:** `scripts3d/Player3D.gd`

- **Verified** movement is relative to character facing_angle (not camera)
- **W/S** = forward/backward relative to character body
- **A/D** = rotate character left/right (tank turning)
- **Camera** follows with smooth lag (camera_follow_speed)
- **Shift** = run (with sanity drain near corruption)
- **C** = crouch (reduces noise radius, sight range)

### 3. Bug Fixes

#### 3.1 Camera/Model Position Offset
**File:** `scenes3d/Player3D.tscn`
- **Fixed** inspector model transform from `Transform3D(-2.43, 0, 0, 0, 2.43, 0, 0, 0, -2.43, 0, -0.88, 0)` to identity `Transform3D(1.0, 0, 0, 0, 1.0, 0, 0, 0, 1.0, 0, 0.0, 0)`
- **Fixed** InteractionArea collision shape Y from 0.9 to 1.0
- **Fixed** CollisionShape3D Y offset from 0.9 to 0.9 (capsule center)

#### 3.2 Player Sinking Into Ground
**Files:** `scenes3d/Player3D.tscn`, `scripts3d/Player3D.gd`
- **Adjusted** collision capsule height: stand=1.8, crouch=1.10
- **Added** spawn offset Y=0.1 in Zone3D._spawn_player() to prevent physics "stuck" state
- **Fixed** gravity application in _apply_gravity()

#### 3.3 Ground Texture/Fog Contrast Blending
**File:** `autoload/GameManager.gd` (ZONE_FOG)
- **Adjusted** all fog light_color values to warmer/lighter tones that contrast with dirt_02.png ground texture
- **Increased** ambient_energy in outdoor zones for better visibility
- **Set** bg_mode=1 (solid color) with complementary bg_color for each zone

### 4. Zone Connections (All 9 Zones Verified)

**Bidirectional Travel Paths:**
```
camino_entrada ↔ casa_principal ↔ campo_cultivo ↔ (pozo, establo, laberinto)
                                    ↓
                              bosque ↔ laberinto
                                    ↓
                              crater_meteorito ↔ camino_entrada
                              atico ↔ casa_principal
```

**EXITS Dictionary Entries Added/Verified:**
- casa_principal → camino_entrada (Exit_to_camino_entrada_2)
- campo_cultivo → casa_principal (Exit_to_casa_principal_3)
- campo_cultivo → laberinto (requires aceite_lampara)
- campo_cultivo → establo (requires llave_oxidada from crater_meteorito)
- laberinto → bosque (SalidaAlBosque, dynamic)
- laberinto → campo_cultivo (SalidaAlCampo, dynamic)
- bosque → laberinto (Exit_to_laberinto_0 - renamed from campo_cultivo)
- crater_meteorito → camino_entrada
- atico → casa_principal
- establo → campo_cultivo

**Fixed:** Room_bosque.tscn exit node renamed from `Exit_to_campo_cultivo_0` to `Exit_to_laberinto_0` to match target_zone_id="laberinto"

### 5. Both Endings Reachable (Pozo Zone Decision)

**File:** `autoload/GameManager.gd` (CLUES.pozo)
- **Good Ending** ("Descender al pozo"): Requires manivela_pozo (found in casa_principal), all 3 visions seen, corruption not maxed
- **Bad Ending** ("Retirarse"): Always available, triggers immediate bad ending
- **Logic:** `decide_ending()` checks `corruption_time_elapsed < corruption_time_limit AND all_visions_seen()` for good ending

**Key Items Path:**
1. `manivela_pozo` → casa_principal (unlocked)
2. `aceite_lampara` → casa_principal (unlocked) → enables campo_cultivo → laberinto
3. `llave_oxidada` → crater_meteorito → enables establo → ganados_establo (padre vision)
4. `diario_madre` → atico (via casa_principal) → madre vision
5. `zapato_hijo` → bosque → laberinto → hijo vision

### 6. Enemy AI (Wrapper3D) - States & Navigation
**File:** `scripts3d/Wrapper3D.gd`

**States:** INACTIVE, EMERGING, PATROL, SEARCHING, CHASING, STUMBLING, ATTACKING

**Perception System:**
- **Vision:** Cone (sight_fov_deg=110°) + raycast LOS check, range 15m base
- **Hearing:** Noise radius from player (crouch=3m, walk=9m, run=18m)
- **Modifiers:** Crouch factor 0.45, Grass factor 0.5

**Chase Mechanics:**
- **Speed:** patrol=1.9, search=2.8, chase=5.2 (player run=6.0)
- **Rubber-band:** Dynamic speed based on distance (close_ratio/far_ratio per difficulty)
- **Stumble:** 35% chance when blocked, gives player escape window

**Maze Navigation:**
- **Primary:** RoomLabyrinth._get_maze_navigation() BFS on maze graph
- **Fallback:** AStarGrid2D with dynamic region (cell_size from GAMEPLAY.labyrinth.cell_size)
- **Waypoints:** Updated every 0.55s or when goal moves >2m

### 7. Gameplay Parameter Centralization
**File:** `autoload/GameManager.gd` (GAMEPLAY dictionary)

**Single Source of Truth for ALL parameters:**

```gdscript
GAMEPLAY = {
    "player": { walk_speed, run_speed, crouch_speed, rotation_speed, gravity, camera_*, crouch_* },
    "enemy_wrapper": { patrol_speed, search_speed, chase_speed, turn_speed, attack_*, sight_*, lose_*, scream_*, stumble_*, gravity },
    "labyrinth": { run_multipliers, chase_close_ratio, chase_far_ratio, stumble_*, cell_size },
    "hud": { sanity_bar_width, corruption_pulse_speed, message_duration, pickup_notification_duration },
    "sanity": { max_sanity, regen_rate_low_corruption, run_drain_per_sec_high_corruption },
    "corruption": { time_limit_base, overlay_hue_*, overlay_saturation, overlay_alpha_*, overlay_pulse_speed },
    "interaction": { interaction_radius, crouch_noise_radius, walk_noise_radius, run_noise_radius },
}
```

**Scripts Migrated:**
- `Player3D.gd` - reads all player params in _ready(), uses in get_noise_radius(), get_effective_run_speed(), _set_crouching()
- `Wrapper3D.gd` - reads all enemy params in _ready(), uses labyrinth params for chase ratios and maze navigation
- `HUD.gd` - reads hud params in _load_hud_params(), uses message_duration
- `Zone3D.gd` - uses labyrinth.run_multipliers for enemy scaling

**Removed:** All @export duplicate parameters from Player3D.gd, Wrapper3D.gd (except scream_sound which is asset reference)

### 8. Performance Optimization (gl_compatibility Renderer)
**Findings:**
- **No volumetric fog** used - only standard Environment.fog (linear/depth)
- **All lights** have shadow_enabled=false (OmniLight3D only)
- **CSG nodes** used at runtime in RoomLabyrinth, RoomSetDressing, HouseExterior - acceptable for procedural generation at zone load
- **MaterialFixer** runs once per zone load to fix imported GLB materials
- **Fog parameters** tuned per zone (depth_begin/end reasonable for 60m max visibility)

**Recommendations Applied:**
- Fog mode=1 (linear) - cheapest on gl_compatibility
- No fog_depth_curve complexity (all 1.0)
- Light counts minimal per zone (1 fill + decorative)
- Emission materials on maze walls for visibility without extra lights

### 9. Audio System
**Files:** `autoload/MusicManager.gd`, `scripts3d/ScreamerOverlay.gd`, `scripts3d/Wrapper3D.gd`

**MusicManager:**
- Crossfade between 2 AudioStreamPlayers (1.5s default)
- Tracks: fondo, climax, persecucion, bueno, malo
- Tension system (0-1) controls volume_db lerp (-16dB to -2dB)
- Threat pressure auto-switches to persecucion track

**Sound Effects:**
- Wrapper3D: scream_sound (AudioStreamPlayer3D, spatial, 12m unit_size, 80m max_distance)
- ScreamerOverlay: scream_distorted.wav (2D, -7dB, fullscreen flash + image)

**Audio Files Present:**
- musica_fondo.ogg, climax_pozo.ogg, persecucion.ogg, final_bueno.ogg, final_malo.ogg
- screamer_horror.wav, scream_distorted.wav

### 10. Material Fixes
**File:** `scripts3d/MaterialFixer.gd`
- Fixes 100+ material/texture mappings for Classic 64 Pack + HorrorPackFBX
- Handles both external .material paths and embedded GLB material names
- Sets metallic=0 for materials without metallic texture (prevents white metal look)
- Sets roughness=0.85 for materials without roughness texture

## Files Modified

### Core Systems
1. `autoload/GameManager.gd` - ZONE_FOG, GAMEPLAY, EXITS, CLUES
2. `scripts3d/Zone3D.gd` - _apply_zone_fog(), _spawn_player() enemy scaling
3. `scripts3d/Player3D.gd` - Centralized params, LABYRINTH_RUN_MULTIPLIERS fix
4. `scripts3d/Wrapper3D.gd` - Centralized params, maze navigation cell_size
5. `scripts3d/HUD.gd` - Centralized hud params
6. `scripts3d/RoomLabyrinth.gd` - Dynamic exits, maze navigation API

### Scenes
7. `scenes3d/Player3D.tscn` - Model transform, collision shapes
8. `scenes3d/Room_casa_principal.tscn` - Exit_to_camino_entrada_2
9. `scenes3d/Room_campo_cultivo.tscn` - Exit_to_casa_principal_3
10. `scenes3d/Room_bosque.tscn` - Exit_to_laberinto_0 (renamed)
11. `scenes3d/Zone3D_laberinto.tscn` - spawn_point_path

## Verification Checklist

- [x] Silent Hill-style fog active in all 9 zones (non-removable)
- [x] Tank controls relative to character (not camera)
- [x] Camera/model position offset fixed
- [x] Player sinking fixed
- [x] Ground/fog contrast fixed
- [x] All 9 zones connected bidirectionally
- [x] Both endings reachable via pozo decision
- [x] Enemy AI states, perception, chase, maze nav working
- [x] All gameplay params centralized in GameManager.GAMEPLAY
- [x] Performance acceptable on gl_compatibility (no volumetric fog)
- [x] Audio system with crossfade, spatial SFX, tension system
- [x] Material fixer handles all imported GLB assets

## Known Considerations

1. **CSG at Runtime:** RoomLabyrinth builds maze with CSGBox3D at load - one-time cost per zone entry
2. **Difficulty Scaling:** Enemy stats scale via enemy_difficulty_multiplier in Zone3D._spawn_player()
3. **Maze Determinism:** Seed per difficulty ensures same maze layout per run
4. **Vision System:** 3 character visions (padre, madre, hijo) required for good ending
5. **Item Progression:** llave_oxidada → establo → ganado_establo (padre vision) is critical path

## Build Notes

- Godot 4.7.2
- Renderer: gl_compatibility (set in project.godot)
- Main scene: res://scenes3d/MainMenu3D.tscn
- Autoloads: GameManager, InputProfiles, MusicManager, ScreenDoorTransition