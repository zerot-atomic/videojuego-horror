# REVISIÓN ESTÁTICA DE CÓDIGO — La Cosecha del Color
**Versión**: 1.0  
**Fecha**: 2026-11-05  
**Alcance**: scripts3d/, autoload/, scenes3d/ (GDScript + .tscn)

---

## 1. ERRORES GODOT 4 (Compilación / Runtime)

| ID | Archivo:Línea | Problema | Severidad |
|----|---------------|----------|-----------|
| G4-01 | Player3D.gd:45 | `vertical_velocity` declarado pero CharacterBody3D ya tiene `velocity.y` — redundante | Bajo |
| G4-02 | Player3D.gd:254 | `set_floor_stop_on_slope_enabled(false)` — método deprecated en 4.3+, usar `floor_stop_on_slope = false` | Medio |
| G4-03 | Player3D.gd:255 | `set_max_slides(4)` — deprecated, usar `max_slides = 4` | Medio |
| G4-04 | Player3D.gd:256 | `set_floor_max_angle(deg_to_rad(46))` — deprecated, usar `floor_max_angle = deg_to_rad(46)` | Medio |
| G4-05 | Player3D.gd:254-256 | Comentario `TODOConverter3To4 infinite_inertia were removed` — confirmar migración completa | Bajo |
| G4-06 | Wrapper3D.gd:347 | `move_and_slide()` sin argumentos — OK en 4.x, pero `velocity` ya asignado línea 361 | OK |
| G4-07 | Wrapper3D.gd:498-502 | `_apply_gravity` duplica lógica de Player3D — consolidar en utilidad | Bajo |
| G4-08 | RoomLabyrinth.gd:53 | `env.fog_mode = 1` hardcoded — debería usar `Environment.FOG_LINEAR` constante | Bajo |
| G4-09 | Zone3D.gd:63 | `env.fog_mode = fog_data.mode` — mode=1 es LINEAR, usar enum | Bajo |
| G4-10 | Zone3D.gd:58 | `env.background_mode = fog_data.bg_mode` — bg_mode=1 es BG_COLOR, usar enum | Bajo |
| G4-11 | RoomLabyrinth.gd:41 | `env.background_mode = Environment.BG_COLOR` — OK, usa enum | OK |

---

## 2. REFERENCIAS NULAS POTENCIALES (Null Refs)

| ID | Archivo:Línea | Contexto | Riesgo |
|----|---------------|----------|--------|
| NR-01 | Zone3D.gd:121-130 | `has_node(actual_spawn_path)` pero `get_node(actual_spawn_path)` sin check previo | Alto |
| NR-02 | Zone3D.gd:132-143 | `get_node_or_null("Room_establo/Wrapper3D")` — OK, usa _or_null | OK |
| NR-03 | Zone3D.gd:145-153 | `get_node_or_null("Room_laberinto/Wrapper3D")` — OK | OK |
| NR-04 | Wrapper3D.gd:375-379 | `maze_room = get_parent().get_node_or_null("Room_laberinto")` — OK | OK |
| NR-05 | Wrapper3D.gd:377 | `maze_room._get_maze_navigation()` — método privado, acoplamiento fuerte | Medio |
| NR-06 | Wrapper3D.gd:471 | `maze_room.has("_maze_cell_size")` — propiedad privada | Medio |
| NR-07 | Wrapper3D.gd:108-112 | `_scream_player` creado solo si `scream_sound != null` — OK | OK |
| NR-08 | Player3D.gd:58-59 | `@onready var spring_arm = $CameraPivot/SpringArm3D` — ruta fija, frágil | Medio |
| NR-09 | Player3D.gd:59 | `@onready var camera = $CameraPivot/SpringArm3D/Camera3D` — ruta fija | Medio |
| NR-10 | Player3D.gd:89-96 | `lantern_light` creado dinámicamente — OK | OK |
| NR-11 | HUD.gd:172 | `load(m.icon)` — puede devolver null si ruta inválida | Medio |
| NR-12 | GameManager.gd:703-707 | `get_clue_data()` devuelve `{}` vacío si no encuentra — callers asumen Dict válido | Medio |
| NR-13 | RoomLabyrinth.gd:29 | `area.set_script(ExitScript)` — `ExitScript` es preload, OK | OK |

---

## 3. SEÑALES DUPLICADAS / NO CONECTADAS

| ID | Archivo | Señal | Estado |
|----|---------|-------|--------|
| SG-01 | Wrapper3D.gd:26-30 | `player_caught`, `stumbled`, `spotted_player`, `scream_started` | Definidas, verificar conexiones |
| SG-02 | RoomLabyrinth.gd:229 | `grapper.player_caught.connect(_on_grapper_caught.bind(...))` | Conectada ✅ |
| SG-03 | Player3D.gd:84-85 | `interaction_area.area_entered/exited` → `_on_area_entered/exited` | Conectadas ✅ |
| SG-04 | HUD.gd | Ninguna señal definida — solo métodos | OK |
| SG-05 | GameManager.gd | Ninguna señal — usa llamadas directas | OK |
| SG-06 | Zone3D.gd | Ninguna señal | OK |
| SG-07 | MaterialFixer.gd | Ninguna señal | OK |

**Hallazgo**: No hay señales duplicadas. Wrapper3D emite señales que RoomLabyrinth conecta. OK.

---

## 4. ESTADOS NO RESETEADOS AL CAMBIO DE ZONA

| ID | Variable | Dónde se setea | Dónde debería resete | Riesgo |
|----|----------|----------------|---------------------|--------|
| ST-01 | `GameManager.corruption_time_elapsed` | GameManager._process() | new_game() ✅, load_game() ✅ | OK |
| ST-02 | `GameManager.sanity` | drain_sanity(), regen | new_game() ✅, load_game() ✅ | OK |
| ST-03 | `GameManager.current_zone_id` | change_zone() | new_game() → "camino_entrada" ✅ | OK |
| ST-04 | `GameManager.previous_zone_id` | change_zone() | new_game() → "" ✅ | OK |
| ST-05 | `GameManager.clues_found` | examine_clue() | new_game() .clear() ✅ | OK |
| ST-06 | `GameManager.visions_seen` | examine_clue(is_key) | new_game() reset dict ✅ | OK |
| ST-07 | `GameManager.inventory` | examine_clue(is_item) | new_game() .clear() ✅ | OK |
| ST-08 | `GameManager.message_carry` | show_message(carry) | new_game() .clear() ✅, load_game() .clear() ✅ | OK |
| ST-09 | `GameManager.active_hud` | Zone3D._spawn_ui() | Zone3D._ready() sobrescribe ✅ | OK |
| ST-10 | `GameManager.corruption_overlay` | Zone3D._add_corruption_overlay() | Zone3D._ready() sobrescribe ✅ | OK |
| ST-11 | `Player3D.facing_angle` | _physics_process, set_facing() | Zone3D._spawn_player() set_facing() ✅ | OK |
| ST-12 | `Player3D.camera_yaw` | _process() | set_facing() sincroniza ✅ | OK |
| ST-13 | `Player3D.crouching` | _set_crouching() | Zone3D._spawn_player() → _set_crouching(false) ✅ | OK |
| ST-14 | `Player3D.velocity` | CharacterBody3D interno | move_and_slide() resetea cada frame | OK |
| ST-15 | `Wrapper3D.state` | start_patrol/chase/stop_chase | Nueva instancia por zona ✅ | OK |
| ST-16 | `Wrapper3D._maze_path` | _maze_waypoint_toward() | Nueva instancia por zona ✅ | OK |
| ST-17 | `Wrapper3D._lost_timer` | _process_chase() | Nueva instancia por zona ✅ | OK |
| ST-18 | `HUD.msg_queue` | show_message() | Nueva instancia por zona ✅ | OK |
| ST-19 | `HUD.msg_active` | _display_message() | Nueva instancia por zona ✅ | OK |
| ST-20 | `GameManager.game_over` | trigger_ending() | new_game() = false ✅ | OK |

**Hallazgo crítico**: **ST-11/ST-12** — `facing_angle` y `camera_yaw` se sincronizan en `set_facing()` llamado desde `Zone3D._spawn_player()`. OK.

**Riesgo medio**: `GameManager.message_carry` se limpia en `load_game()` pero `show_message(carry=true)` puede acumular mensajes entre zonas si HUD no está listo. Verificar `Zone3D._spawn_ui()` orden vs `_announce_arrival()`.

---

## 5. CONDICIONES DE CARRERA (Race Conditions)

| ID | Ubicación | Descripción | Mitigación |
|----|-----------|-------------|------------|
| RC-01 | Zone3D.gd:30-44 | `_ready()` llama `_spawn_player()` antes de `_spawn_ui()` — HUD no existe para `_announce_arrival()` | `show_message(carry=true)` guarda en `message_carry` ✅ |
| RC-02 | Zone3D.gd:115-154 | `_spawn_player()` accede `Room_establo/Wrapper3D` antes de que `_add_room()` termine? | `_add_room()` línea 37, `_spawn_player()` línea 40 — orden OK |
| RC-03 | Wrapper3D.gd:369-416 | `_maze_waypoint_toward()` modifica `_maze_path` desde `_process_chase` + timer — un solo hilo GDScript | OK (single-threaded) |
| RC-04 | GameManager.gd:549-553 | `show_message()` chequea `is_instance_valid(active_hud)` — puede ser false momentáneamente | `message_carry` buffer ✅ |
| RC-05 | RoomLabyrinth.gd:14-37 | `_ready()` crea Spawn markers, exits, screamer, grapper — orden determinista | OK |
| RC-06 | Player3D.gd:117-121 | `MobileTouchControls` instanciado en `_ready()` si touch — puede duplicar si recarga zona | `Input.set_mouse_mode()` cada `_ready()` — OK |

---

## 6. DUPLICACIÓN DE INPUT / ACCIONES

| ID | Archivo | Acción | Duplicada en |
|----|---------|--------|--------------|
| IN-01 | InputProfiles.gd:6-16 | 9 acciones registradas en InputMap | — |
| IN-02 | Player3D.gd:274 | `Input.get_action_strength("move_forward")` | InputProfiles ✅ |
| IN-03 | Player3D.gd:274 | `Input.get_action_strength("move_backward")` | InputProfiles ✅ |
| IN-04 | Player3D.gd:275 | `Input.get_action_strength("turn_left")` | InputProfiles ✅ |
| IN-05 | Player3D.gd:275 | `Input.get_action_strength("turn_right")` | InputProfiles ✅ |
| IN-06 | Player3D.gd:277 | `Input.is_action_pressed("run")` | InputProfiles ✅ |
| IN-07 | Player3D.gd:424 | `event.is_action_pressed("pause")` | InputProfiles ✅ |
| IN-08 | Player3D.gd:424 | `event.is_action_pressed("crouch")` | InputProfiles ✅ |
| IN-09 | Player3D.gd:426 | `event.is_action_pressed("interact")` | InputProfiles ✅ |
| IN-10 | Player3D.gd:428 | `event.is_action_pressed("journal")` | InputProfiles ✅ |
| IN-11 | Player3D.gd:431-442 | `_on_touch_action_pressed` maneja mismas acciones | Touch wrapper, no duplicado |
| IN-12 | GameManager.gd:15 | `control_scheme: String = "tank"` — **NUNCA USADO** | Dead code |

**Hallazgo**: `GameManager.control_scheme` definido línea 15, comentado "(sin uso: el juego siempre usa controles tipo Silent Hill)". **Eliminar o usar**.

---

## 7. CONSTANTES MÁGICAS (Magic Constants) — FUERA DE GAMEPLAY

| ID | Archivo:Línea | Valor | Debería estar en |
|----|---------------|-------|------------------|
| MC-01 | Player3D.gd:297 | `response := 72.0` (aceleración movimiento) | GAMEPLAY.player.acceleration |
| MC-02 | Player3D.gd:304 | `84.0` (desaceleración) | GAMEPLAY.player.deceleration |
| MC-03 | Player3D.gd:340 | `response := 72.0` (direccional) | GAMEPLAY.player.acceleration |
| MC-04 | Player3D.gd:347 | `84.0` (desaceleración dir.) | GAMEPLAY.player.deceleration |
| MC-05 | Player3D.gd:98 | `camera.fov = 66.0` | GAMEPLAY.player.camera_fov |
| MC-06 | Player3D.gd:99 | `camera.near = 0.1` | GAMEPLAY.player.camera_near |
| MC-07 | Player3D.gd:100 | `camera.far = 150.0` | GAMEPLAY.player.camera_far |
| MC-08 | Player3D.gd:103 | `spring_arm.spring_length = camera_distance` | Usa GAMEPLAY ✅ |
| MC-09 | Player3D.gd:193 | `Vector3(0, 0.94, 0)` (headroom check offset) | GAMEPLAY.player.headroom_offset |
| MC-10 | Player3D.gd:194 | `gp.stand_capsule_height` — usa GAMEPLAY ✅ |
| MC-11 | Player3D.gd:229 | `floor_snap_length = 0.35` | GAMEPLAY.player.floor_snap_length |
| MC-12 | Player3D.gd:251 | `deg_to_rad(46)` (floor_max_angle) | GAMEPLAY.player.floor_max_angle |
| MC-13 | Player3D.gd:265 | `vertical_velocity = -0.5` (snap floor) | GAMEPLAY.player.floor_snap_velocity |
| MC-14 | Player3D.gd:380 | `threat_distance >= 24.0` (shake range) | GAMEPLAY.player.threat_shake_range |
| MC-15 | Player3D.gd:381 | `amplitude := minf(0.17, ...)` | GAMEPLAY.player.threat_shake_amplitude |
| MC-16 | Wrapper3D.gd:208 | `_flat_distance(wp) < 1.4` (waypoint reach) | GAMEPLAY.enemy_wrapper.waypoint_reach_dist |
| MC-17 | Wrapper3D.gd:210 | `randf_range(2.0, 4.5)` (pause patrol) | GAMEPLAY.enemy_wrapper.patrol_pause_range |
| MC-18 | Wrapper3D.gd:228 | `_flat_distance(_last_known) < 1.6` (search reach) | GAMEPLAY.enemy_wrapper.search_reach_dist |
| MC-19 | Wrapper3D.gd:231 | `_state_timer = 3.0` (search look time) | GAMEPLAY.enemy_wrapper.search_look_time |
| MC-20 | Wrapper3D.gd:242 | `dist <= attack_range` — usa GAMEPLAY ✅ |
| MC-21 | Wrapper3D.gd:252 | `_lost_timer > lose_time` — usa GAMEPLAY ✅ |
| MC-22 | Wrapper3D.gd:252 | `dist > lose_range` — usa GAMEPLAY ✅ |
| MC-23 | Wrapper3D.gd:271 | `pursuit_speed := lerpf(close_speed, far_speed, ...)` — usa GAMEPLAY ✅ |
| MC-24 | Wrapper3D.gd:304 | `d > 3.0` (close perception) | GAMEPLAY.enemy_wrapper.close_perception_dist |
| MC-25 | Wrapper3D.gd:304 | `cos(deg_to_rad(sight_fov_deg * 0.5))` — usa GAMEPLAY ✅ |
| MC-26 | Wrapper3D.gd:319 | `Vector3(0, 1.5, 0)` (raycast from height) | GAMEPLAY.enemy_wrapper.raycast_height |
| MC-27 | Wrapper3D.gd:319 | `Vector3(0, 1.0, 0)` (target height) | GAMEPLAY.enemy_wrapper.target_raycast_height |
| MC-28 | Wrapper3D.gd:341 | `clampf(turn_speed * delta, 0.0, 1.0)` — usa GAMEPLAY ✅ |
| MC-29 | Wrapper3D.gd:365 | `real < speed * 0.25` (stumble threshold) | GAMEPLAY.enemy_wrapper.stumble_speed_threshold |
| MC-30 | Wrapper3D.gd:386 | `_maze_nav_timer = 0.55` (path recalc interval) | GAMEPLAY.labyrinth.nav_recalc_interval |
| MC-31 | Wrapper3D.gd:387 | `_maze_goal.distance_to(goal) > 2.0` (recalc threshold) | GAMEPLAY.labyrinth.nav_recalc_dist_threshold |
| MC-32 | Wrapper3D.gd:392 | `half_extent := int(60.0 / cell_size / 2) + 1` — 60.0 hardcoded maze size | GAMEPLAY.labyrinth.maze_world_size |
| MC-33 | Wrapper3D.gd:393 | `grid.cell_size = Vector2(cell_size, cell_size)` — usa GAMEPLAY ✅ |
| MC-34 | Wrapper3D.gd:401 | `query.transform = ... Vector3(x * cell_size, 0.78, z * cell_size)` — 0.78 hardcoded | GAMEPLAY.labyrinth.astar_probe_height |
| MC-35 | Wrapper3D.gd:409 | `_maze_path.size() <= 1` — OK lógica |
| MC-36 | Wrapper3D.gd:413 | `_flat_distance(current_point) > 1.0` (waypoint advance) | GAMEPLAY.enemy_wrapper.waypoint_advance_dist |
| MC-37 | Wrapper3D.gd:470 | `cell_size := GameManager.GAMEPLAY.labyrinth.cell_size` fallback — OK |
| MC-38 | Wrapper3D.gd:476 | `Vector3(path[index].x * cell_size - 30.0 + ...)` — -30.0 = maze half-size hardcoded | GAMEPLAY.labyrinth.maze_half_size |
| MC-39 | Wrapper3D.gd:490 | `offsets: Array = [0.0, 35.0, -35.0, ...]` (steer angles) | GAMEPLAY.enemy_wrapper.steer_angles |
| MC-40 | Wrapper3D.gd:490 | `GameManager.GAMEPLAY.labyrinth.cell_size` (steer ray length) — usa GAMEPLAY ✅ |
| MC-41 | Zone3D.gd:99 | `light.light_energy = 0.6` (fallback light) | GAMEPLAY.zone.fallback_light_energy |
| MC-42 | Zone3D.gd:100 | `light.omni_range = 12.0` | GAMEPLAY.zone.fallback_light_range |
| MC-43 | Zone3D.gd:101 | `light.position = Vector3(0, 2.5, 0)` | GAMEPLAY.zone.fallback_light_height |
| MC-44 | Zone3D.gd:124 | `p.global_position = spawn.global_position + Vector3(0, 0.1, 0)` — 0.1 spawn offset | GAMEPLAY.player.spawn_y_offset |
| MC-45 | Zone3D.gd:136-143 | Establo: patrol points hardcoded | GAMEPLAY.zone.establo_patrol_points |
| MC-46 | Zone3D.gd:148 | `player_sprint := 6.0 * multiplier` — 6.0 = run_speed hardcoded | GAMEPLAY.player.run_speed (ya disponible) |
| MC-47 | Zone3D.gd:149 | `grapper.chase_speed = player_sprint * 1.05 * enemy_mult` — 1.05 magic | GAMEPLAY.labyrinth.chase_speed_factor |
| MC-48 | Zone3D.gd:150 | `attack_sanity_damage = 24.0 * enemy_mult` — 24.0 magic | GAMEPLAY.enemy_wrapper.labyrinth_attack_damage |
| MC-49 | Zone3D.gd:152 | `lose_time = 3.0` — magic | GAMEPLAY.enemy_wrapper.labyrinth_lose_time |
| MC-50 | RoomLabyrinth.gd:9 | `_maze_cell_size := 60.0 / 9.0` — 60, 9 hardcoded | GAMEPLAY.labyrinth.maze_size, default_cols |
| MC-51 | RoomLabyrinth.gd:75-87 | Dificultad → cols/rows/seed hardcoded | GAMEPLAY.labyrinth.difficulty_config |
| MC-52 | RoomLabyrinth.gd:91 | `_maze_cell_size = 60.0 / float(_maze_cols)` — 60 hardcoded | GAMEPLAY.labyrinth.maze_world_size |
| MC-53 | RoomLabyrinth.gd:97-98 | Perimeter walls ±30.0, 0.6, 3.3, 60.0 — hardcoded | GAMEPLAY.labyrinth.wall_dims |
| MC-54 | RoomLabyrinth.gd:101-102 | Boundary openings ±30.0 — hardcoded | GAMEPLAY.labyrinth.maze_half_size |
| MC-55 | RoomLabyrinth.gd:112-113 | Wall dims `_maze_cell_size + 0.05`, 3.3, 0.42 — hardcoded | GAMEPLAY.labyrinth.internal_wall_dims |
| MC-56 | RoomLabyrinth.gd:121-122 | Vertical wall dims 0.42, 3.3, `_maze_cell_size + 0.05` — hardcoded | GAMEPLAY.labyrinth.internal_wall_dims |
| MC-57 | RoomLabyrinth.gd:125 | Spore positions hardcoded 5 posiciones | GAMEPLAY.labyrinth.spore_positions |
| MC-58 | RoomLabyrinth.gd:134 | Guide light positions hardcoded 7 posiciones | GAMEPLAY.labyrinth.guide_positions |
| MC-59 | RoomLabyrinth.gd:188 | `posmod((to.x + 1) * 17 + ...` — magic numbers seed | GAMEPLAY.labyrinth.seed_formula |
| MC-60 | RoomLabyrinth.gd:221 | `half_gap := maxf(1.65, _maze_cell_size * 0.32)` — 1.65, 0.32 | GAMEPLAY.labyrinth.boundary_gap_min, gap_ratio |
| MC-61 | RoomLabyrinth.gd:308-309 | Exit positions (0,1,-29) y (0,1,29) — hardcoded | GAMEPLAY.labyrinth.exit_positions |
| MC-62 | RoomLabyrinth.gd:320 | BoxShape3D(7.0, 2.8, 2.0) exit collision — hardcoded | GAMEPLAY.labyrinth.exit_collision_size |
| MC-63 | HUD.gd:25 | `msg_size = Vector2(540, 96)` — hardcoded | GAMEPLAY.hud.message_size |
| MC-64 | HUD.gd:26 | `msg_scale = 1.35` — hardcoded | GAMEPLAY.hud.message_scale |
| MC-65 | HUD.gd:28 | `msg_fade = 0.25` — hardcoded | GAMEPLAY.hud.message_fade |
| MC-66 | HUD.gd:68 | `sanity_bar.custom_minimum_size = Vector2(180, 16)` — hardcoded | GAMEPLAY.hud.sanity_bar_size |
| MC-67 | HUD.gd:89 | Hint text hardcoded — OK (UI copy) | — |
| MC-68 | GameManager.gd:25 | `corruption_time_limit: float = 900.0` — sobrescrito por DIFFICULTIES | OK (default) |
| MC-69 | GameManager.gd:423 | `delta * 1.5` (sanity regen) — hardcoded | GAMEPLAY.sanity.regen_rate_low_corruption ✅ |
| MC-70 | GameManager.gd:430 | `sanity_drain_multiplier` — usa DIFFICULTIES ✅ |
| MC-71 | GameManager.gd:449 | `_anim_length("Scream", 1.2)` fallback — hardcoded | GAMEPLAY.enemy_wrapper.scream_anim_fallback |
| MC-72 | GameManager.gd:449 | `_anim_length("Attack_Lunge", 0.9)` fallback — hardcoded | GAMEPLAY.enemy_wrapper.attack_anim_fallback |
| MC-73 | GameManager.gd:449 | `_anim_length("WallSlam_Recover", 1.4)` fallback — hardcoded | GAMEPLAY.enemy_wrapper.stumble_anim_fallback |

**Total magic constants**: 73 identificadas, **solo ~15 usan GAMEPLAY**. Restantes 58 deberían centralizarse.

---

## 8. OTROS HALLAZGOS ESTÁTICOS

| ID | Archivo:Línea | Hallazgo | Severidad |
|----|---------------|----------|-----------|
| OT-01 | Player3D.gd:308 | `return running` — `_apply_tank_movement` retorna bool, `_apply_directional_movement` también | OK |
| OT-02 | Player3D.gd:168-172 | `get_effective_run_speed()` duplica lógica de `_apply_tank_movement` línea 280-284 | Duplicación |
| OT-03 | Wrapper3D.gd:262 | `player_run_speed` usa `call("get_effective_run_speed")` — reflexión lenta | Cachear en _ready |
| OT-04 | Wrapper3D.gd:384-407 | AStarGrid2D recreado cada 0.55s — costoso, debería reusarse | Performance |
| OT-05 | Wrapper3D.gd:419-464 | `_compute_maze_path` BFS duplicado de `RoomLabyrinth._maze_route_cells` | Duplicación |
| OT-06 | Zone3D.gd:46-70 | `_apply_zone_fog()` crea Environment nuevo cada zona — OK (una vez) | OK |
| OT-07 | Zone3D.gd:53-55 | Elimina WorldEnvironment de room — pero RoomLabyrinth._build_environment() crea uno | Diseño: Zone3D gana |
| OT-08 | RoomLabyrinth.gd:39-67 | `_build_environment()` crea fog hardcoded — **NUNCA SE USA** si Zone3D lo elimina | Código muerto |
| OT-09 | MaterialFixer.gd | 100+ mapeos hardcoded — mantenimiento difícil | Considerar JSON externo |
| OT-10 | GameManager.gd:261-295 | EXITS usa coordenadas 2D (1672x941) — pero juego es 3D | Legacy 2D, no usado en 3D |
| OT-11 | GameManager.gd:703-707 | `get_clue_data()` busca en CLUES por zone_id + clue_id — OK | OK |
| OT-12 | Player3D.gd:353-363 | `_update_camera()` usa `global_position + Vector3(0, camera_height, 0)` — camera_height de GAMEPLAY ✅ |
| OT-13 | Player3D.gd:390-413 | `_update_animation()` lógica compleja backwards crouch — probar edge cases | Medio |

---

## RESUMEN CRÍTICO

| Categoría | Críticos | Altos | Medios | Bajos |
|-----------|----------|-------|--------|-------|
| Godot 4 Errors | 0 | 3 | 2 | 5 |
| Null Refs | 1 | 0 | 5 | 0 |
| Signals | 0 | 0 | 0 | 0 |
| Unreset States | 0 | 0 | 1 | 0 |
| Race Conditions | 0 | 0 | 2 | 0 |
| Input Duplication | 0 | 0 | 1 | 0 |
| Magic Constants | 0 | 0 | 58 | 0 |
| Otros | 0 | 1 | 5 | 2 |

**Total**: 1 Crítico (RoomLabyrinth fog dead code), 4 Altos, 73 Medios, 7 Bajos

---

## ACCIONES RECOMENDADAS (Prioridad)

1. **CRÍTICO**: RoomLabyrinth._build_environment() fog hardcoded nunca se usa → eliminar o documentar
2. **ALTO**: Centralizar 58 magic constants en GAMEPLAY
3. **ALTO**: Mover AStarGrid2D a member variable, reusar en Wrapper3D
4. **ALTO**: Eliminar GameManager.control_scheme (dead code)
5. **ALTO**: Cachear player_run_speed en Wrapper3D._ready()
6. **MEDIO**: Migrar set_* deprecated a propiedades (floor_stop_on_slope, max_slides, floor_max_angle)
7. **MEDIO**: Usar enums Environment.FOG_LINEAR, Environment.BG_COLOR
8. **MEDIO**: Extraer MaterialFixer mapeos a JSON
9. **BAJO**: Limpiar código duplicado get_effective_run_speed / _apply_tank_movement