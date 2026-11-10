# REGISTRO DE BUGS — La Cosecha del Color
**Versión**: 1.0  
**Fecha**: 2026-11-05  
**Fase**: QA Revisión Final (20/11/2026) → Gold Master (30/11/2026)

---

## CLASIFICACIÓN DE SEVERIDAD

| Nivel | Definición | SLA Fix |
|-------|------------|---------|
| **CRITICAL** | Bloquea completabilidad, crash, data loss, buen final inalcanzable | Inmediato (Code Freeze) |
| **HIGH** | Gameplay roto, mecanica principal falla, performance < 30 FPS | Antes de Gold Master |
| **MEDIUM** | Bug visible, workaround existe, parámetros descentralizados | Backlog post-launch |
| **LOW** | Cosmético, magic constants, code smell, warnings | Tech debt |

---

## BUGS CRITICAL (Bloquean Gold Master)

### BUG-001: Buen final INALCANZABLE en HARD y LOVECRAFT
- **Severidad**: CRITICAL
- **Archivo**: `autoload/GameManager.gd` líneas 28-48 (DIFFICULTIES), `autoload/GameManager.gd` línea 25 `corruption_time_limit`
- **Escenario**: Playthrough modo HARD (12 min) o LOVECRAFT (10 min) ruta dorada completa
- **Pasos reproducción**:
  1. Nueva partida → Difficulty: HARD
  2. Seguir ruta crítica completa (ver COMPLETABILITY_PLAYTHROUGH.md)
  3. Tiempo estimado ruta dorada: ~15 min
  4. Límite corrupción HARD: 720s (12 min)
  5. Límite corrupción LOVECRAFT: 600s (10 min)
- **Resultado actual**: `corruption_time_elapsed >= corruption_time_limit` → `trigger_ending(false)` ANTES de llegar al pozo
- **Resultado esperado**: Buen final alcanzable en TODOS los modos (descripción: "Siempre es posible sobrevivir")
- **Fix propuesto**: 
  - Opción A: Aumentar `time_limit` en DIFFICULTIES HARD a 900s, LOVECRAFT a 900s
  - Opción B: Reducir requisito visiones a 2 en HARD/LOVECRAFT
  - Opción C: Añadir atajo (llave_oxidada también en casa_principal)

### BUG-002: RoomLabyrinth._build_environment() crea fog que NUNCA se usa
- **Severidad**: CRITICAL (código muerto confuso, maintenance burden)
- **Archivo**: `scripts3d/RoomLabyrinth.gd` líneas 39-67
- **Escenario**: Carga zona laberinto
- **Pasos reproducción**:
  1. Entrar a laberinto
  2. Zone3D._apply_zone_fog() elimina WorldEnvironment de room (línea 53-55)
  3. RoomLabyrinth._build_environment() creó uno que se destruye inmediatamente
- **Resultado actual**: Fog hardcoded en RoomLabyrinth (light_color=0.15,0.12,0.18, depth_begin=3, depth_end=20) se descarta
- **Resultado esperado**: RoomLabyrinth NO debe crear fog; Zone3D es única fuente (ZONE_FOG)
- **Fix propuesto**: Eliminar `_build_environment()` o renombrar a `_build_lighting_only()` y solo crear luces/suelo

---

## BUGS HIGH (Gameplay roto / Performance)

### BUG-003: AStarGrid2D recreado cada 0.55s en Wrapper3D (performance)
- **Severidad**: HIGH
- **Archivo**: `scripts3d/Wrapper3D.gd` líneas 384-407 (`_maze_waypoint_toward`)
- **Escenario**: Persecución en laberinto (estado CHASING)
- **Pasos reproducción**:
  1. Entrar laberinto → enemigo inicia chase
  2. Cada 0.55s (`_maze_nav_timer`) se crea NUEVO AStarGrid2D
  3. Double loop `for z in range(-half_extent, half_extent): for x...` = ~400 iteraciones
  4. Cada iteración: `intersect_shape()` physics query
- **Resultado actual**: Spike CPU cada 0.55s en chase, posible frame drop
- **Resultado esperado**: AStarGrid2D member variable, `update()` incremental, region fija
- **Fix propuesto**: Mover grid a member `_astar_grid`, inicializar en `_ready()`, solo `set_point_solid()` + `update()` en timer

### BUG-004: Magic constants NO centralizadas (58 valores hardcoded)
- **Severidad**: HIGH (maintenance, balancing imposible sin recompilar)
- **Archivo**: Múltiples (ver STATIC_CODE_REVIEW.md sección 7)
- **Ejemplos críticos**:
  - Player3D: acceleration=72, deceleration=84, fov=66, floor_snap=0.35, threat_range=24
  - Wrapper3D: waypoint_reach=1.4, patrol_pause=2-4.5, search_reach=1.6, steer_angles=[35,70,110]
  - Zone3D: fallback_light_energy=0.6, spawn_offset=0.1, laberinto chase_factor=1.05
  - RoomLabyrinth: maze_world_size=60, wall_dims, spore_positions, guide_positions
- **Fix propuesto**: Extender `GAMEPLAY` dict con secciones `player_movement`, `enemy_patrol`, `enemy_chase`, `labyrinth_geometry`, `zone_fallback`, `hud_ui`

### BUG-005: GameManager.control_scheme dead code
- **Severidad**: HIGH (confusión, variable expuesta en settings pero ignorada)
- **Archivo**: `autoload/GameManager.gd` línea 15, `autoload/InputProfiles.gd` línea 4
- **Escenario**: Usuario cambia control_scheme en settings → no afecta gameplay
- **Fix propuesto**: Eliminar `control_scheme` de GameManager y settings, o implementar selector real

### BUG-006: Wrapper3D._compute_maze_path duplica RoomLabyrinth._maze_route_cells
- **Severidad**: HIGH (duplicación lógica crítica pathfinding)
- **Archivo**: `scripts3d/Wrapper3D.gd` líneas 419-464 vs `scripts3d/RoomLabyrinth.gd` líneas 192-215
- **Fix propuesto**: Wrapper3D usar `_get_maze_navigation()` + BFS compartido (ya hace en líneas 376-382), eliminar fallback BFS duplicado

### BUG-007: player_run_speed vía `call()` reflexión en Wrapper3D (lento)
- **Severidad**: HIGH (se ejecuta cada frame en chase)
- **Archivo**: `scripts3d/Wrapper3D.gd` línea 262
- **Fix propuesto**: Cachear `target.get_effective_run_speed` en `_ready()` o pasar como parámetro

### BUG-008: Métodos deprecated set_floor_stop_on_slope / set_max_slides / set_floor_max_angle
- **Severidad**: HIGH (Godot 4.3+ warnings, futuro breaking)
- **Archivo**: `scripts3d/Player3D.gd` líneas 254-256
- **Fix propuesto**: Cambiar a propiedades `floor_stop_on_slope = false`, `max_slides = 4`, `floor_max_angle = deg_to_rad(46)`

### BUG-009: Zone3D fallback light SIN shadow_enabled=false
- **Severidad**: HIGH (sombras activadas por defecto en OmniLight3D = performance hit)
- **Archivo**: `scripts3d/Zone3D.gd` líneas 98-102
- **Fix propuesto**: Añadir `light.shadow_enabled = false`

---

## BUGS MEDIUM (Visible, workaround existe)

### BUG-010: RoomLabyrinth fog usa constantes numéricas no enums
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/RoomLabyrinth.gd` línea 53 `env.fog_mode = 1`, línea 41 `env.background_mode = Environment.BG_COLOR`
- **Fix**: Usar `Environment.FOG_LINEAR`, `Environment.BG_COLOR`

### BUG-011: Zone3D fog usa constantes numéricas no enums
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/Zone3D.gd` línea 63 `env.fog_mode = fog_data.mode`, línea 58 `env.background_mode = fog_data.bg_mode`
- **Fix**: ZONE_FOG almacenar enums o convertir al aplicar

### BUG-012: MaterialFixer 100+ mapeos hardcoded en GDScript
- **Severidad**: MEDIUM (maintenance nightmare, añadir material = editar código)
- **Archivo**: `scripts3d/MaterialFixer.gd`
- **Fix propuesto**: Mover mapeos a `material_fixes.json` externo, cargar en `_ready()`

### BUG-013: EXITS en GameManager usa coordenadas 2D legacy (1672x941)
- **Severidad**: MEDIUM (confusión, no usado en 3D)
- **Archivo**: `autoload/GameManager.gd` líneas 261-295
- **Fix**: Documentar como legacy 2D, o migrar a ExitArea3D en scenes3d (ya hecho)

### BUG-014: HUD message_duration se modifica a sí mismo (self-referential)
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/HUD.gd` línea 192 `msg_duration = msg_duration - min(msg_queue.size(), 2) * 0.5`
- **Fix**: Usar variable local `var dur = msg_duration - ...`

### BUG-015: Player3D.get_effective_run_speed() duplica lógica _apply_tank_movement()
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/Player3D.gd` líneas 168-172 vs 280-284
- **Fix**: Extraer método privado `_get_labyrinth_multiplier()`

### BUG-016: Headroom check offset 0.94 hardcoded en Player3D
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/Player3D.gd` línea 184 `Vector3(0, 0.94, 0)`
- **Fix**: GAMEPLAY.player.headroom_check_offset

### BUG-017: Wrapper3D steer ray length usa cell_size (6.67) — muy largo para esquiva
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/Wrapper3D.gd` línea 490 `GameManager.GAMEPLAY.labyrinth.cell_size`
- **Fix**: GAMEPLAY.enemy_wrapper.steer_ray_length (ej. 2.0)

### BUG-018: Zone3D establo patrol points hardcoded
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/Zone3D.gd` líneas 136-143
- **Fix**: GAMEPLAY.zone.establo_patrol_points o leer de Markers en room_scene

### BUG-019: Zone3D laberinto chase_speed usa 6.0 hardcoded en vez de GAMEPLAY.player.run_speed
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/Zone3D.gd` línea 148
- **Fix**: `var player_sprint := GameManager.GAMEPLAY.player.run_speed * multiplier`

### BUG-020: Zone3D laberinto attack_sanity_damage = 24.0 magic
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/Zone3D.gd` línea 150
- **Fix**: GAMEPLAY.enemy_wrapper.labyrinth_attack_damage

### BUG-021: Zone3D laberinto lose_time = 3.0 magic
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/Zone3D.gd` línea 152
- **Fix**: GAMEPLAY.enemy_wrapper.labyrinth_lose_time

### BUG-022: RoomLabyrinth maze_world_size = 60.0 hardcoded (3 lugares)
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/RoomLabyrinth.gd` líneas 9, 55, 91
- **Fix**: GAMEPLAY.labyrinth.maze_world_size

### BUG-023: RoomLabyrinth difficulty config hardcoded (cols/rows/seed)
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/RoomLabyrinth.gd` líneas 75-87
- **Fix**: GAMEPLAY.labyrinth.difficulty_config dict

### BUG-024: RoomLabyrinth wall dimensions hardcoded (perimeter, internal, boundary)
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/RoomLabyrinth.gd` líneas 97-122
- **Fix**: GAMEPLAY.labyrinth.wall_dims

### BUG-025: RoomLabyrinth spore/guide positions hardcoded
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/RoomLabyrinth.gd` líneas 125-141
- **Fix**: GAMEPLAY.labyrinth.spore_positions, guide_positions

### BUG-026: RoomLabyrinth exit positions/collision hardcoded
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/RoomLabyrinth.gd` líneas 308-322
- **Fix**: GAMEPLAY.labyrinth.exit_positions, exit_collision_size

### BUG-027: HUD msg_size, msg_scale, msg_fade hardcoded
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/HUD.gd` líneas 25-28
- **Fix**: GAMEPLAY.hud.message_size, message_scale, message_fade

### BUG-028: HUD sanity_bar size hardcoded
- **Severidad**: MEDIUM
- **Archivo**: `scripts3d/HUD.gd` línea 68
- **Fix**: GAMEPLAY.hud.sanity_bar_size

### BUG-029: GameManager DIFFICULTIES dict claves string vs const
- **Severidad**: MEDIUM (typos no detectados)
- **Archivo**: `autoload/GameManager.gd` líneas 28-48
- **Fix**: Usar enum Difficulty { STORY, NORMAL, HARD, LOVECRAFT }

### BUG-030: Player3D camera far=150.0 vs fog_depth_end max=40.0 (casa_principal)
- **Severidad**: MEDIUM (overdraw, render más allá de niebla)
- **Archivo**: `scripts3d/Player3D.gd` línea 100
- **Fix**: GAMEPLAY.player.camera_far = max(ZONE_FOG.*.depth_end) + margin

---

## BUGS LOW (Cosmético / Code Smell)

### BUG-031: Player3D vertical_velocity redundante (CharacterBody3D tiene velocity.y)
- **Severidad**: LOW
- **Archivo**: `scripts3d/Player3D.gd` línea 45
- **Fix**: Usar `velocity.y` directamente

### BUG-032: Wrapper3D _apply_gravity duplica Player3D
- **Severidad**: LOW
- **Archivo**: `scripts3d/Wrapper3D.gd` líneas 498-502
- **Fix**: Función utilitaria compartida o heredar de base común

### BUG-033: Comentarios TODOConverter3To4 en Player3D
- **Severidad**: LOW
- **Archivo**: `scripts3d/Player3D.gd` línea 254
- **Fix**: Verificar migración completa, limpiar comentario

### BUG-034: Zone3D _announce_arrival usa ZONE_NAMES pero show_message carry=true
- **Severidad**: LOW
- **Archivo**: `scripts3d/Zone3D.gd` línea 76
- **Fix**: Verificar mensaje llega tras cambio zona (message_carry funciona)

### BUG-035: GameManager _pickup_text fallback "Has examinado: " + clue.name
- **Severidad**: LOW
- **Archivo**: `autoload/GameManager.gd` línea 479
- **Fix**: OK, solo fallback

### BUG-036: Vision3D.tscn no revisado (escena de visiones)
- **Severidad**: LOW
- **Archivo**: `scenes3d/Vision3D.tscn`
- **Fix**: Verificar que muestra vision_text y vision_line correctamente

### BUG-037: EndingGood3D.tscn / EndingBad3D.tscn no revisados
- **Severidad**: LOW
- **Archivo**: `scenes3d/EndingGood3D.tscn`, `scenes3d/EndingBad3D.tscn`
- **Fix**: Verificar textos, música, botones funcionan

### BUG-038: ScreamerOverlay trigger() no verificado
- **Severidad**: LOW
- **Archivo**: `scenes3d/ScreamerOverlay.tscn`, `scripts3d/ScreamerOverlay.gd`
- **Fix**: Verificar flash + imagen + audio distorted

### BUG-039: MobileTouchControls no revisado
- **Severidad**: LOW
- **Archivo**: `scripts3d/MobileTouchControls.gd` (si existe)
- **Fix**: Verificar joystick virtual + botones mapean a InputMap actions

### BUG-040: InputProfiles rebind() no valida conflictos con ui_*
- **Severidad**: LOW
- **Archivo**: `autoload/InputProfiles.gd` línea 87
- **Fix**: Verificar no pisa ui_accept/ui_cancel

---

## RESUMEN CONTABILIDAD

| Severidad | Count | Bloquean Gold Master |
|-----------|-------|---------------------|
| CRITICAL | 2 | **SÍ (2)** |
| HIGH | 7 | **SÍ (7)** |
| MEDIUM | 21 | No (workaround) |
| LOW | 10 | No |
| **TOTAL** | **40** | **9 Critical+High** |

---

## PLAN DE FIX (Code Freeze 15/11 → Revisión Final 20/11)

### Semana 1 (15-19 Nov): Critical + High
- [ ] BUG-001: Fix time_limit HARD/LOVECRAFT ≥ 900s
- [ ] BUG-002: Eliminar RoomLabyrinth._build_environment() fog
- [ ] BUG-003: AStarGrid2D member variable + update incremental
- [ ] BUG-004: Centralizar top-20 magic constants en GAMEPLAY (movement, enemy, labyrinth)
- [ ] BUG-005: Eliminar control_scheme dead code
- [ ] BUG-006: Eliminar BFS duplicado Wrapper3D
- [ ] BUG-007: Cachear player_run_speed en Wrapper3D
- [ ] BUG-008: Migrar set_* deprecated a propiedades
- [ ] BUG-009: Zone3D fallback light shadow_enabled=false

### Semana 2 (22-24 Nov): Medium (post-Revisión Final)
- [ ] BUG-010 a BUG-030: Centralizar resto magic constants
- [ ] BUG-012: MaterialFixer → JSON externo
- [ ] BUG-014: HUD msg_duration self-ref fix

### Post-Launch: Low
- [ ] BUG-031 a BUG-040: Limpieza, verificación escenas finales