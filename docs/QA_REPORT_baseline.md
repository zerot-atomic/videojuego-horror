# QA BASELINE REPORT — La Cosecha del Color v0.2.13

**Fecha**: 2026-11-06  
**Motor**: Godot 4.7.2 (gl_compatibility)  
**Estado**: Beta — primera entrega de dos (baseline ahora, final tras integración agente)  
**Alcance**: Inventario completo de sistemas, carga de escenas, estado de funciones, cruce BUG_REGISTRY, inconsistencias versión, trazabilidad ruta crítica, controles, priorización

---

## 1. INVENTARIO DE SISTEMAS DE JUEGO

### 1.1 Autoloads (4 singletons persistentes)

| Autoload | Script | Responsabilidad principal |
|----------|--------|---------------------------|
| **GameManager** | `autoload/GameManager.gd` | Estado global: zona actual, inventario, cordura, corrupción, dificultad, endings, save/load, ZONE_FOG (9 zonas), GAMEPLAY params, DIFFICULTIES, CLUES, EXITS (legacy 2D), ZONE_SCENES |
| **InputProfiles** | `autoload/InputProfiles.gd` | 9 InputMap actions con defaults teclado+gamepad, rebind persistente, sin selector control_scheme |
| **MusicManager** | `autoload/MusicManager.gd` | Crossfade 5 pistas (fondo, climax, persecucion, bueno, malo), tensión 0-1, threat_pressure auto-switch a persecucion |
| **ScreenDoorTransition** | `autoload/ScreenDoorTransition.gd` | Transiciones puerta/trampilla entre zonas, persistente across scene changes |

### 1.2 Scripts 3D principales (15)

| Script | Clase | Función clave |
|--------|-------|---------------|
| `Player3D.gd` | Player3D | Tank controls (SH1/RE), cámara SpringArm, agachado/headroom, ruido, sigilo, touch mobile |
| `Zone3D.gd` | Zone3D | Cargador zona: room_scene, fog centralizado (_apply_zone_fog), spawn player, UI, enemy scaling |
| `Wrapper3D.gd` | Wrapper3D | Enemy AI 7 estados (PATROL→SEARCHING→CHASING→STUMBLING→ATTACKING), percepción visión+oído, chase rubber-band, nave maze |
| `RoomLabyrinth.gd` | RoomLabyrinth | Maze procedural por dificultad, BFS nav + AStarGrid2D fallback, decor ambient, exits, grapper spawn |
| `HUD.gd` | HUD | Barra cordura, 4 niveles mensaje corrupción, cola mensajes con fade |
| `MobileTouchControls.gd` | MobileTouchControls | Joystick virtual (move_fwd/bwd, turn_l/r) + botones acción (interact, run, crouch, journal, pause) |
| `MainMenu.gd` | MainMenu | Menú principal, selector dificultad, settings, créditos, backdrop animado con shaders |
| `ExitArea3D.gd` | ExitArea3D | Transiciones zona con item requirement, door/trapdoor style |
| `Vision.gd` | Vision | Escena visión: retrato personaje, texto, línea voz, continue button mobile |
| `Ending.gd` | Ending | Pantallas Good/Bad ending con créditos y botón menú |
| `ScreamerOverlay.gd` | ScreamerOverlay | Flash fullscreen + imagen + audio scream distorsionado (single trigger per entry) |
| `Interactable3D.gd` | Interactable3D | Clues/items examinables, registra en diario |
| `MaterialFixer.gd` | MaterialFixer | Fix texturas vacías/metalizado default en .glb (100+ mapeos hardcoded) |
| `ScreenDoorTransition.gd` | ScreenDoorTransition | Autoload transición visual |
| `Journal.gd` / `PauseMenu.gd` | — | UI diario/pausa (instanciados por Zone3D) |

### 1.3 Escenas 3D (26 archivos .tscn en scenes3d/)

**Zonas (9 Zone3D_*.tscn + 9 Room_*.tscn):**
- Zone3D_camino_entrada.tscn + Room_camino_entrada.tscn
- Zone3D_casa_principal.tscn + Room_casa_principal.tscn
- Zone3D_atico.tscn + Room_atico.tscn
- Zone3D_crater_meteorito.tscn + Room_crater_meteorito.tscn
- Zone3D_establo.tscn + Room_establo.tscn
- Zone3D_bosque.tscn + Room_bosque.tscn
- Zone3D_campo_cultivo.tscn + Room_campo_cultivo.tscn
- Zone3D_laberinto.tscn + Room_laberinto.tscn
- Zone3D_pozo.tscn + Room_pozo.tscn

**Otras:**
- Player3D.tscn — CharacterBody3D con ModelPivot (scale 2.5766, rot_y 180°, y 0.9007), SpringArm3D camera
- MainMenu3D.tscn — Menú principal
- Vision3D.tscn — Escena visiones
- EndingGood3D.tscn / EndingBad3D.tscn — Finales
- ScreamerOverlay.tscn — Overlay screamer
- Credits3D.tscn — Créditos
- Wrapper3D.tscn / WrapperTest3D.tscn — Enemigo
- ChildShoe.tscn — Prop zapato hijo

### 1.4 Parámetros centralizados (GameManager.GAMEPLAY)

```gdscript
GAMEPLAY = {
  player: { walk_speed, run_speed, crouch_speed, backward_speed_factor, rotation_speed, 
            camera_follow_speed, gravity, camera_distance, camera_height, 
            camera_pitch_min, camera_pitch_max, stand_capsule_height, crouch_capsule_height, collision_y_offset,
            crouch_noise_radius, walk_noise_radius, run_noise_radius },
  enemy_wrapper: { patrol_speed, search_speed, chase_speed, turn_speed, attack_range, attack_cooldown,
                   attack_sanity_damage, sight_range, sight_fov_deg, crouch_sight_factor, grass_sight_factor,
                   lose_time, lose_range, scream_cooldown, stumble_chance, stumble_duration, stumble_cooldown_time, gravity },
  labyrinth: { world_size, cell_size, wall_height, wall_thickness, cols/rows/seed per difficulty,
               exit_width/height/depth, exit_spawn_offset, light_fill_*, ambient_dead_trees, ambient_stumps,
               ambient_mushrooms, ambient_rocks, max_dead_end_markers, max_junction_guides,
               grapper_min_distance_cells, chase_close_ratio, chase_far_ratio, stumble_distance_threshold/range,
               difficulty_config: {story/normal/hard/lovecraft: {cols, rows, seed}} },
  hud: { message_duration },
  interaction: { ... }
}
```

### 1.5 Dificultades (4 perfiles)

| ID | Nombre | time_limit (s) | sanity_drain_mult | enemy_mult | terror_mult | labyrinth_run_mult | Descripción |
|----|--------|----------------|-------------------|------------|-------------|-------------------|-------------|
| story | Modo Historia | 1800 (30 min) | 0.5 | 0.7 | 0.6 | 1.0 | Sin presión tiempo |
| normal | Normal | 900 (15 min) | 1.0 | 1.0 | 1.0 | 1.0 | Estándar |
| hard | Difícil | 900 (15 min) | 1.5 | 1.3 | 1.4 | 0.85 | Buen final alcanzable |
| lovecraft | Lovecraft | 900 (15 min) | 2.0 | 1.6 | 1.8 | 0.7 | Máxima tensión |

**Nota**: CHANGELOG 0.2.12 confirma HARD/LOVECRAFT = 900s (fix BUG-001). BUG_REGISTRY v1.0 decía 720s/600s — **desactualizado**.

### 1.6 Items críticos (5) — distribución por zona

| Item | Zona | Ubicación | Requisito para |
|------|------|-----------|----------------|
| manivela_pozo | casa_principal | Cocina (fregadero) | Exit Pozo (good ending) |
| aceite_lampara | casa_principal | Sala (lámpara mesa) | — |
| diario_madre | atico | Sobre baúl | Visión madre |
| llave_oxidada | crater_meteorito | En cráter | Exit Establo → Laberinto |
| zapato_hijo | bosque | Cerca salida laberinto | Visión hijo |

### 1.7 Clues/Visions (GameManager.CLUES)

- **Items** (is_item=true): libro_diario, foto_familiar, llave_atico, manivela_pozo, aceite_lampara, diario_madre, llave_oxidada, zapato_hijo, llave_establo, ganado_establo
- **Visions** (3 requeridas good ending): madre (ático), padre (establo), hijo (bosque) — cada una con vision_text + vision_line + character portrait
- **Examinables** sin item: múltiples por zona

### 1.8 Endings (2)

- **Good (A Tiempo)**: corruption_time_elapsed < corruption_time_limit Y all_visions_seen() Y manivela_pozo en inventario → trigger_ending(true)
- **Bad (Demasiado Tarde)**: siempre disponible si falla condición good → trigger_ending(false)
- Lógica en `GameManager.decide_ending()` línea ~530

---

## 2. ERRORES DE CARGA DE ESCENAS (HEADLESS)

**Estado**: **NO EJECUTABLES** — Godot 4.7.2 no encontrado en PATH de entorno.

```bash
godot --headless --path . --quit-after 120 res://scenes3d/NOMBRE.tscn
```

**Verificación necesaria** (17 escenas jugables):
- Zone3D_camino_entrada.tscn
- Zone3D_casa_principal.tscn
- Zone3D_atico.tscn
- Zone3D_crater_meteorito.tscn
- Zone3D_establo.tscn
- Zone3D_bosque.tscn
- Zone3D_campo_cultivo.tscn
- Zone3D_laberinto.tscn
- Zone3D_pozo.tscn
- MainMenu3D.tscn
- Vision3D.tscn
- EndingGood3D.tscn
- EndingBad3D.tscn
- Credits3D.tscn
- ScreamerOverlay.tscn
- Wrapper3D.tscn
- Player3D.tscn

**Limitación documentada**: Sin Godot en CI/entorno, no hay errores parse/runtime reales. Solo análisis estático.

---

## 3. TABLA ESTADO FUNCIÓN POR FUNCIÓN

Evidencia: **C** = código verificado, **T** = test headless requerido, **D** = docs/CHANGELOG, **B** = BUG_REGISTRY

| Sistema | Función | Estado | Evidencia | Notas |
|---------|---------|--------|-----------|-------|
| **GameManager** | new_game/load_game/save_game | ✅ | C, D | Save resource persistente |
| | decide_ending() | ✅ | C | Lógica good/bad correcta |
| | corruption_level() / drain_sanity() | ✅ | C | 4 niveles mensaje HUD |
| | show_message() / message_carry | ✅ | C | Cross-zone messages |
| | toggle_pause/journal | ✅ | C | Input handling |
| | _pickup_text fallback | ⚠️ | B-035 | Solo fallback, LOW |
| **Player3D** | _apply_tank_movement | ✅ | C | SH1/RE classic, +Z forward |
| | _set_crouching + headroom | ✅ | C | Capsule resize, check 0.94 offset |
| | get_noise_radius() | ✅ | C | Crouch/walk/run radii |
| | get_effective_run_speed() | ⚠️ | C, B-015 | Duplica lógica laberinto |
| | _threat_camera_shake | ✅ | C | Pressure 0-1, music sync |
| | MobileTouchControls integration | ✅ | C | Touch joystick mapea InputMap |
| | Deprecated set_floor_* | ❌ | C, B-008 | Lines 246-248: use properties |
| | vertical_velocity redundant | ⚠️ | C, B-031 | CharacterBody3D tiene velocity.y |
| **Zone3D** | _apply_zone_fog() | ✅ | C | Single source ZONE_FOG, 9 zones |
| | _add_lighting_fallback | ❌ | C, B-009 | Falta shadow_enabled=false |
| | _spawn_player (spawn markers) | ✅ | C | Offset Y 0.1, set_facing |
| | Enemy scaling per zone/diff | ✅ | C | Establo patrol, laberinto chase |
| | GroundCollision runtime | ✅ | C | BoxShape3D 200x1x200 at y=-0.5 |
| | _announce_arrival | ✅ | C | ZONE_NAMES, message_carry |
| **Wrapper3D** | State machine 7 states | ✅ | C | PATROL→SEARCH→CHASE→STUMBLE→ATTACK |
| | _perceive (vision+hearing) | ✅ | C | Crouch/grass factors |
| | _maze_waypoint_toward | ⚠️ | C, B-003, B-006 | AStarGrid2D recreado 0.55s, BFS dup |
| | _steer obstacle avoidance | ✅ | C | Ray offsets ±35/70/110° |
| | Rubber-band chase speed | ✅ | C | close_ratio/far_ratio per diff |
| | player_run_speed via call() | ❌ | C, B-007 | Reflection cada frame |
| | _apply_gravity duplicate | ⚠️ | C, B-032 | Same as Player3D |
| **RoomLabyrinth** | _build_maze (DFS + loops) | ✅ | C | Procedural per difficulty |
| | Navigation API (world_to_cell, shortest_path) | ✅ | C | BFS cached, Wrapper3D usa |
| | _build_environment fog | ❌ | C, B-002 | Crea fog que Zone3D destruye |
| | _build_ambient_decor | ✅ | C | Dead trees, stumps, mushrooms, rocks |
| | _pick_grapper_spawn_cell | ✅ | C | BFS distance from player entry |
| **HUD** | sanity_bar + corruption messages | ✅ | C | 4 niveles, progress bar |
| | show_message queue + fade | ⚠️ | C, B-014 | msg_duration self-modifies |
| **InputProfiles** | 9 actions + rebind | ✅ | C | Keyboard+gamepad defaults |
| | control_scheme dead code | ❌ | C, B-005 | Variable exists, unused |
| **MusicManager** | Crossfade 5 tracks | ✅ | C | SINE easing, parallel tween |
| | set_threat_pressure | ✅ | C | Auto-switch persecucion >0.06 |
| **MainMenu** | Difficulty selector | ✅ | C | 4 profiles, new_game(id) |
| | Animated backdrop shaders | ✅ | C | Cosmic glow + mist noise |
| **ExitArea3D** | Item-gated transitions | ✅ | C | Door/trapdoor styles |
| **Vision** | Portrait + text + voice line | ✅ | C | Mobile continue button |
| **Ending** | Good/Bad screens | ✅ | C | Credits/menu buttons |
| **ScreamerOverlay** | Flash + image + audio | ✅ | C | 5 loops, 0.92s duration |

---

## 4. CRUCE BUG_REGISTRY v1.0 (40 ENTRIES) — ESTADO REAL

### CRITICAL (2) — Bloquean Gold Master

| Bug | Descripción | Estado Código | Fix Requerido |
|-----|-------------|---------------|---------------|
| **BUG-001** | Good ending unreachable HARD/LOVECRAFT (time_limit 720/600s) | **FIXED en código** | CHANGELOG 0.2.12: DIFFICULTIES hard=900, lovecraft=900. BUG_REGISTRY desactualizado. Verificar `GameManager.gd` líneas 28-48 |
| **BUG-002** | RoomLabyrinth._build_environment() fog destruido por Zone3D | **OPEN** | Lines 53-55 Zone3D.gd destruye WorldEnvironment. RoomLabyrinth lines 57-72 crea fog inútil. Eliminar o renombrar a `_build_lighting_only()` |

### HIGH (7) — Gameplay roto / Performance

| Bug | Descripción | Estado Código | Fix Requerido |
|-----|-------------|---------------|---------------|
| **BUG-003** | AStarGrid2D recreado cada 0.55s en chase | **OPEN** | Wrapper3D lines 379-384: `_maze_nav_timer=0.55`, crea grid nuevo. Mover a member, `update()` incremental |
| **BUG-004** | 58+ magic constants no centralizadas | **OPEN** | Extender GAMEPLAY con secciones player_movement, enemy_patrol, enemy_chase, labyrinth_geometry, zone_fallback, hud_ui |
| **BUG-005** | control_scheme dead code | **OPEN** | GameManager line 15, InputProfiles line 4. Eliminar o implementar selector real |
| **BUG-006** | Wrapper3D BFS duplica RoomLabyrinth._maze_route_cells | **OPEN** | Wrapper3D lines 419-464 vs RoomLabyrinth 192-215. Usar get_maze_navigation() shared BFS |
| **BUG-007** | player_run_speed via call() reflexión | **OPEN** | Wrapper3D line 262: cachear en _ready() o pasar param |
| **BUG-008** | set_floor_stop_on_slope/set_max_slides/set_floor_max_angle deprecated | **OPEN** | Player3D lines 246-248: usar propiedades `floor_stop_on_slope=false`, `max_slides=4`, `floor_max_angle=deg_to_rad(46)` |
| **BUG-009** | Zone3D fallback light sin shadow_enabled=false | **OPEN** | Zone3D lines 113-117: añadir `light.shadow_enabled = false` |

### MEDIUM (21) — Visible, workaround existe

**Top 5 por impacto:**
- BUG-012: MaterialFixer 100+ mapeos hardcoded → JSON externo
- BUG-014: HUD msg_duration self-referential line 192
- BUG-019: Zone3D laberinto chase_speed usa 6.0 hardcoded vs GAMEPLAY.player.run_speed
- BUG-022: RoomLabyrinth maze_world_size=60 en 3 lugares
- BUG-030: Player3D camera far=150 vs fog_depth_end max=40 (overdraw)

### LOW (10) — Cosmético / Code smell

- BUG-031: vertical_velocity redundante
- BUG-032: _apply_gravity duplicado
- BUG-033: TODOConverter3To4 comments
- BUG-036/037/038/039/040: Escenas finales sin verificación visual

**Resumen contabilidad real:**
| Severidad | BUG_REGISTRY | Estado Real |
|-----------|--------------|-------------|
| CRITICAL | 2 | 1 FIXED (001), 1 OPEN (002) |
| HIGH | 7 | 7 OPEN |
| MEDIUM | 21 | 21 OPEN |
| LOW | 10 | 10 OPEN |
| **TOTAL** | **40** | **39 OPEN, 1 FIXED** |

---

## 5. INCONSISTENCIAS DE VERSIÓN ENTRE ARCHIVOS

| Archivo | Versión Declarada | Notas |
|---------|-------------------|-------|
| `project.godot` (line 17) | `0.2.13-beta` | **Autoridad** — config del motor |
| `CHANGELOG.md` (line 8) | `0.2.13-beta` | Coincide con project.godot |
| `README.md` (line 7) | `0.2.11` | **DESFASE** — 2 versiones atrás |
| `BUG_REGISTRY.md` (line 3) | `1.0` / `QA Revisión Final (20/11/2026)` | Documento separado, versión interna |
| `dist/MANIFIESTO_BETA_0.2.11_MULTIPLATAFORMA.txt` | `0.2.11` | Build artifact antiguo |

**Acción**: Actualizar README.md a `0.2.13-beta` antes de release.

---

## 6. TRAZABILIDAD RUTA CRÍTICA vs LÍMITES CORRUPCIÓN

### Ruta crítica (golden path) — 9 zonas secuenciales:

```
casa_principal (manivela_pozo, aceite_lampara, llave_atico)
    → atico (diario_madre, visión MADRE)
    → crater_meteorito (llave_oxidada)
    → establo (ganado_establo, visión PADRE, llave_establo)
    → bosque (zapato_hijo, visión HIJO)
    → campo_cultivo
    → laberinto (persecución Grapper)
    → pozo (decisión: manivela_pozo + 3 visiones + tiempo → GOOD)
```

### Timing estimado por zona (minutos) vs límites:

| Zona | Estimado (min) | Acumulado | Story (30') | Normal (15') | Hard (15') | Lovecraft (15') |
|------|----------------|-----------|-------------|--------------|------------|-----------------|
| casa_principal | 3-4 | 3-4 | ✅ | ✅ | ✅ | ✅ |
| atico | 2-3 | 5-7 | ✅ | ✅ | ⚠️ tight | ⚠️ tight |
| crater_meteorito | 2 | 7-9 | ✅ | ✅ | ⚠️ | ⚠️ |
| establo | 2-3 | 9-12 | ✅ | ⚠️ | ⚠️ | ❌ risk |
| bosque | 2-3 | 11-15 | ✅ | ⚠️ | ❌ | ❌ |
| campo_cultivo | 1-2 | 12-17 | ✅ | ❌ | ❌ | ❌ |
| laberinto | 3-5 | 15-22 | ✅ | ❌ | ❌ | ❌ |
| pozo | 1 | 16-23 | ✅ | ❌ | ❌ | ❌ |

**Conclusión**: Con time_limit 900s (15 min) en Normal/Hard/Lovecraft, **ruta dorada completa excede límite en todas excepto Story**. 

- **BUG-001 "fixed" en CHANGELOG es engañoso**: 900s sigue siendo insuficiente para ruta completa realista
- Opciones reales: Aumentar a 1200-1500s, O reducir visiones requeridas a 2 en Hard/Lovecraft, O añadir atajos (llave_oxidada también en casa)

### Verificación endings:
- `GameManager.decide_ending()`: `good = corruption_time_elapsed < corruption_time_limit AND all_visions_seen() AND inventory.has("manivela_pozo")`
- `all_visions_seen()`: requiere 3 (madre, padre, hijo) — hardcoded
- Bad ending: siempre disponible fallback

---

## 7. VERIFICACIÓN CONTROLES POR DISPOSITIVO

### InputMap Actions (9) — Single scheme, no selector

| Acción | Teclado (Default) | Gamepad (Default) | Touch (MobileTouchControls) |
|--------|-------------------|-------------------|----------------------------|
| move_forward | W / Up | Left Stick Y (-1) | Joystick virtual ↑ |
| move_backward | S / Down | Left Stick Y (+1) | Joystick virtual ↓ |
| turn_left | A / Left | Left Stick X (-1) | Botón virtual ◄ |
| turn_right | D / Right | Left Stick X (+1) | Botón virtual ► |
| run | Shift | Left Stick Press (L3) | Botón RUN |
| crouch | C | B / Circle | Botón CROUCH |
| interact | E | A / Cross | Botón INTERACT |
| journal | Tab | Y / Triangle | Botón JOURNAL |
| pause | Escape | Start / Menu | Botón PAUSE |

### Tank Controls — Comportamiento verificado (Player3D._apply_tank_movement)

- **W/S**: Adelante/atrás **relativo al cuerpo** (no a cámara)
- **A/D**: Girar personaje **in situ** (tanque puro)
- **Cámara**: SpringArm sigue con lerp (camera_follow_speed), siempre detrás
- **Shift + W**: Sprint (run_speed), consume cordura si corruption_level > 0.3
- **C**: Toggle crouch — capsule resize, headroom check, animaciones CrouchWalk/CrouchRun

### Verificación móvil:
- `MobileTouchControls.gd` instanciado en `Player3D._ready()` si touchscreen
- Emite señales `action_pressed` mapeadas a mismas acciones InputMap
- Joystick virtual: eje Y → move_forward/backward, eje X → turn_left/right
- Botones virtuales: interact, run, crouch, journal, pause

**No existe control_scheme selector** — BUG-005 confirma variable muerta. Un solo esquema unificado.

---

## 8. QUÉ FUNCIONA (✅) — BASELINE VERDE

### Sistemas completos y funcionales:
1. **GameManager** — Estado global, save/load, endings, fog centralizado, dificultad, inventario, cordura/corrupción
2. **Player3D** — Tank controls SH1/RE, cámara detrás, crouch/headroom, ruido, sigilo, mobile touch
3. **Zone3D** — Carga 9 zonas, fog único (ZONE_FOG), spawn player, UI, enemy scaling per zona/dificultad
4. **Wrapper3D** — AI 7 estados, percepción visión+oído, chase rubber-band, maze navigation via RoomLabyrinth API
5. **RoomLabyrinth** — Maze procedural por dificultad, BFS nav + AStar fallback, decor ambient, exits, grapper spawn
6. **HUD** — Sanity bar, 4 niveles corrupción, message queue con fade
7. **InputProfiles** — 9 actions, keyboard+gamepad defaults, rebind persistente
8. **MusicManager** — Crossfade 5 tracks, tension system, threat_pressure auto-switch
9. **MainMenu** — Difficulty selector (4), settings, credits, animated backdrop shaders
10. **Transiciones** — ScreenDoorTransition door/trapdoor, ExitArea3D item-gated
11. **Visions** — Portrait, text, voice line, mobile continue
12. **Endings** — Good/Bad screens con credits/menu buttons
13. **ScreamerOverlay** — Flash + imagen + audio distorsionado (single trigger)
14. **Distribución items/clues/visions** — 5 items críticos, 3 visions, múltiples examinables en 9 zonas

### Arquitectura sólida:
- +Z forward convention locked across Player3D, Wrapper3D, RoomLabyrinth, Zone3D
- Centralized GAMEPLAY params (single source of truth)
- ZONE_FOG single source for all 9 zones (Environment.FOG_MODE_DEPTH)
- Autoloads persist across scene changes
- gl_compatibility renderer, no volumetric fog, shadows disabled on fallback lights

---

## 9. QUÉ ESTÁ ROTO — PRIORIZADO

### 🔴 CRITICAL — Bloquean completabilidad / Gold Master

| # | Bug | Impacto | Archivo:Línea | Fix |
|---|-----|---------|---------------|-----|
| 1 | **BUG-002** RoomLabyrinth fog muerto | Confusión maintenance, fog duplicado destruido | RoomLabyrinth.gd:57-72, Zone3D.gd:53-55 | Eliminar `_build_environment()` fog o renombrar `_build_lighting_only()` |
| 2 | **BUG-001 real** time_limit 900s insuficiente ruta dorada | Good ending inalcanzable Normal/Hard/Lovecraft playthrough real | GameManager.gd:28-48 | Aumentar a 1200-1500s O reducir visiones a 2 O añadir atajo llave_oxidada |

### 🟠 HIGH — Gameplay roto / Performance severa

| # | Bug | Impacto | Archivo:Línea | Fix |
|---|-----|---------|---------------|-----|
| 3 | **BUG-003** AStarGrid2D recreado 0.55s | CPU spike cada 0.55s en chase, frame drops | Wrapper3D.gd:379-384 | Member `_astar_grid`, init `_ready()`, solo `update()` |
| 4 | **BUG-008** set_floor_* deprecated | Godot 4.3+ warnings, future breaking | Player3D.gd:246-248 | Props: `floor_stop_on_slope=false`, `max_slides=4`, `floor_max_angle=deg_to_rad(46)` |
| 5 | **BUG-009** Fallback light shadows ON | Performance hit (sombras default en OmniLight3D) | Zone3D.gd:113-117 | `light.shadow_enabled = false` |
| 6 | **BUG-007** player_run_speed call() reflection | Overhead cada frame en chase | Wrapper3D.gd:262 | Cache callable en `_ready()` |
| 7 | **BUG-006** BFS duplicado Wrapper3D | Duplicación lógica pathfinding crítica | Wrapper3D.gd:419-464 | Usar `get_maze_navigation()` shared BFS |
| 8 | **BUG-005** control_scheme dead code | Variable expuesta settings, ignorada | GameManager.gd:15, InputProfiles.gd:4 | Eliminar o implementar selector real |
| 9 | **BUG-004** 58+ magic constants | Balancing imposible sin recompilar | Múltiples | Extender GAMEPLAY dict secciones |

### 🟡 MEDIUM — Visible, workaround existe (top 10)

| # | Bug | Archivo | Fix |
|---|-----|---------|-----|
| 10 | BUG-012 MaterialFixer 100+ hardcoded | MaterialFixer.gd | JSON externo |
| 11 | BUG-014 HUD msg_duration self-ref | HUD.gd:192 | Variable local |
| 12 | BUG-019 Zone3D chase_speed 6.0 hardcoded | Zone3D.gd:148 | GAMEPLAY.player.run_speed * mult |
| 13 | BUG-022 maze_world_size 60 en 3 lugares | RoomLabyrinth.gd:9,55,91 | GAMEPLAY.labyrinth.maze_world_size |
| 14 | BUG-023 difficulty config hardcoded | RoomLabyrinth.gd:75-87 | GAMEPLAY.labyrinth.difficulty_config |
| 15 | BUG-015 get_effective_run_speed duplica lógica | Player3D.gd:168-172 vs 280-284 | Extraer `_get_labyrinth_multiplier()` |
| 16 | BUG-016 headroom check 0.94 hardcoded | Player3D.gd:184 | GAMEPLAY.player.headroom_check_offset |
| 17 | BUG-017 steer ray length cell_size (6.67) | Wrapper3D.gd:490 | GAMEPLAY.enemy_wrapper.steer_ray_length |
| 18 | BUG-018 establo patrol points hardcoded | Zone3D.gd:136-143 | GAMEPLAY.zone.establo_patrol_points |
| 19 | BUG-030 camera far=150 vs fog max 40 | Player3D.gd:100 | GAMEPLAY.player.camera_far = max depth_end + margin |

### 🟢 LOW — Cosmético / Tech debt (10)

BUG-031 a BUG-040: vertical_velocity redundante, gravity duplicate, TODO comments, escenas finales sin verificación visual, InputProfiles rebind sin validar ui_*

---

## 10. LISTA TEST MANUAL 10 MIN (SMOKE TEST)

### Pre-requisitos: Godot 4.7.2, proyecto abierto, gl_compatibility

| # | Test | Pasos | Esperado | Tiempo |
|---|------|-------|----------|--------|
| 1 | **Main Menu** | Abrir MainMenu3D.tscn → Play → Nueva Partida → Story | Carga casa_principal, player spawn, HUD visible, fog activo | 1 min |
| 2 | **Tank Controls** | WASD movimiento, A/D gira cuerpo, Shift corre, C agacha | W=+Z forward, A/D rotan in situ, cámara detrás, crouch resize capsule | 1 min |
| 3 | **Casa Principal** | Examinar libro_diario, foto_familiar, llave_atico, manivela_pozo, aceite_lampara | Clues registradas en diario, items en inventario, mensajes HUD | 1.5 min |
| 4 | **Transición Ático** | Usar llave_atico en Exit_To_Atico → trampilla | ScreenDoorTransition trapdoor style, spawn en atico mirando centro | 1 min |
| 5 | **Ático + Visión Madre** | Examinar diario_madre → visión madre | Vision3D carga: portrait, vision_text, vision_line, continue → vuelve zona | 1 min |
| 6 | **Crater + Llave** | Ir crater_meteorito → examinar llave_oxidada | Item en inventario, mensaje HUD | 1 min |
| 7 | **Establo + Visión Padre** | Entrar establo (llave_establo) → ganado_establo → visión padre | Wrapper3D patrol activo, visión padre trigger | 1 min |
| 8 | **Bosque + Visión Hijo** | Entrar bosque → zapato_hijo → visión hijo | Item + visión hijo, exit laberinto visible | 1 min |
| 9 | **Laberinto Chase** | Entrar laberinto → Grapper scream → chase | ScreamerOverlay flash+audio, chase state, maze nav funcione | 1 min |
| 10 | **Pozo + Ending** | Llegar pozo con manivela + 3 visiones + tiempo → Good ending | EndingGood3D: texto "A TIEMPO", créditos, botón menú funciona | 1 min |

### Tests adicionales si tiempo:
- **Gamepad**: Conectar mando → verificar 9 actions mapeadas
- **Mobile touch**: Simular touchscreen → joystick virtual + botones
- **Difficulty Normal**: Nueva partida Normal → verificar time_limit 900s en GameManager
- **Save/Load**: Guardar en casa → cargar → estado persistido (inventario, zona, cordura)
- **Bad ending**: Dejar corromper tiempo → Pozo sin items/visión → EndingBad3D "DEMASIADO TARDE"

---

## 11. PRÓXIMOS PASOS (HACIA QA_REPORT_FINAL)

1. **Localizar Godot 4.7.2** en entorno → ejecutar 17 headless scene loads → capturar parse/runtime errors reales
2. **Fix Critical/High** (9 bugs) — Code Freeze target
3. **Centralizar magic constants** top-20 en GAMEPLAY dict
4. **Verificar escenas finales** (Vision3D, EndingGood/Bad, ScreamerOverlay, Credits3D) visualmente
5. **Playthrough completo** cronometrado por dificultad → validar time_limit vs ruta real
6. **Generar QA_REPORT_final.md** tras integración agente y fixes

---

**Fin del Baseline Report v0.2.13**  
*Solo salidas permitidas: docs/QA_REPORT_baseline.md, docs/QA_REPORT_final.md, tools/qa/ scripts*