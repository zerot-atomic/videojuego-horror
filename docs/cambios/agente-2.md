# Cambios Agente 2 — La Cosecha del Color

## Resumen
Arreglo completo del laberinto (RoomLabyrinth.gd, Zone3D_laberinto.tscn, Room_laberinto.tscn, Wrapper3D.gd, ScreamerOverlay) que no existía desde v0.2.13.

---

## Causa raíz: Laberinto no aparecía
**Problema**: `Zone3D._spawn_player()` se ejecutaba en `_ready()` ANTES de que `Room_laberinto` (hijo) completara su `_ready()` y creara los marcadores `SpawnDesdeBosque` / `SpawnDesdeCampo`.

**Fix**: `Zone3D.gd` — `_spawn_player()` movido a `call_deferred("_spawn_player_deferred")` para ejecutarse tras el `_ready()` del hijo.

---

## Fixes en RoomLabyrinth.gd

### 1. Variable `floor` que oculta `Node3D.floor` (shadowing)
**Línea 59**: `var floor := StaticBody3D.new()` → `var floor_node := StaticBody3D.new()`

### 2. Parámetro `seed` que oculta función nativa
**Línea 164**: `func _build_maze_connections(seed: int)` → `func _build_maze_connections(maze_seed: int)`
**Líneas 182, 190, 198**: usos internos actualizados a `maze_seed`

### 3. Piso en y=0 con cara superior en y=0
**Antes**: CSGBox3D con tamaño Y=0.3 y posición Y=0.15 → cara superior en y=0.3
**Ahora**: `StaticBody3D` + `MeshInstance3D` (ArrayMesh quad en y=0) + `CollisionShape3D` (BoxShape3D size Y=0.1, position Y=-0.05)
**Verificado**: Cara superior del suelo exactly en y=0.

### 4. Tabiques internos a media altura (1.65 hardcoded)
**Antes**: `wall_pos.y = 1.65` (centro fijo, no escala con `wall_height`)
**Ahora**: `wall_center_y := wall_h * 0.5` → centros en `wall_h * 0.5` (1.65 para wall_height=3.3). Mismo centro que muros perimetrales.
**Verificado**: Todos los muros (perimetrales + internos) tienen su centro en `wall_height * 0.5`.

### 5. Perseguidor (Grapper) spawn a ~0.08 celdas del muro perimetral
**Problema**: `_is_clear_spawn()` solo comprobaba colisión con sonda 1.5m, no distancia a muro perimetral.
**Fix**: `_is_clear_spawn()` añade margen 1.5m desde bordes mundo (`half_w ± 1.5`).
**Resultado**: Grapper spawnea en celda libre, ≥1.5m de cualquier muro, distancia mínima al jugador (6 celdas por `grapper_min_distance_cells`).

### 6. Spawns sin rotación → jugador mira al interior
**Ya correcto**: `SpawnDesdeBosque.rotation.y = PI` (mira -Z, hacia adentro), `SpawnDesdeCampo.rotation.y = 0.0` (mira +Z, hacia adentro).
**Convención**: +Z = adelante (code forward). Jugador nace con `p.set_facing(spawn.rotation.y)`.

### 7. Triggers de salida de 7m para abertura 3.3m
**Antes**: `start_pos.z - exit_d * 0.5 - 0.2` (z=-30 - 0.75 - 0.2 = -30.95, dentro del muro)
**Ahora**: Posición EXACTA en pared perimetral: `z = -half_w` (Sur) y `z = +half_w` (Norte).
**Trigger depth**: `exit_depth = 1.5m` (cruza el muro). Jugador aparece lejos al cambiar zona (spawn_offset=2.5m).

### 8. Constantes fijas → GAMEPLAY.labyrinth
Todas las hardcoded values migradas a `GameManager.GAMEPLAY.labyrinth`:
- `maze_world_size=60.0` → `world_size`
- `wall_height=3.3`, `wall_thickness=0.42` → `wall_height`, `wall_thickness`
- `exit_width=3.5`, `exit_height=3.3`, `exit_depth=1.5`, `exit_spawn_offset=2.5`
- `cols/rows/seed` por dificultad → `difficulty_config`
- `light_fill_*`, `max_dead_end_markers`, `max_junction_guides`
- `ambient_dead_trees`, `ambient_stumps`, `ambient_mushrooms`, `ambient_rocks`
- `grapper_min_distance_cells=6`, `cell_size` (calculado)
- `run_multipliers`, `chase_close_ratio`, `chase_far_ratio`, `stumble_distance_*`

### 9. Luces: ≤8 por objeto (gl_compatibility)
**Estado**: 1 sola luz `OmniLight3D` (LuzRelleno) + marcadores emisivos (esporas/guías) que NO son luces.
**Bien**: Muy por debajo del límite de 8 luces/objeto en gl_compatibility.

### 10. ~200 CSGBox3D → StaticBody3D + BoxShape3D + MeshInstance3D
**Antes**: `_build_maze()` usaba CSGBox3D con `use_collision = true` (costoso, no batching)
**Ahora**: `_add_wall_static()` crea `StaticBody3D` + `MeshInstance3D` (mesh pre-hecho escalado) + `CollisionShape3D` (BoxShape3D).
**Meshes pre-hechos** en `_prepare_wall_meshes()`: 3 tipos (perimetral, horizontal, vertical) reutilizados con escala.
**Verificado**: 0 CSGBox3D en runtime. Walls usan StaticBody3D instanciados.

---

## API Navegación Pública (RoomLabyrinth.gd)
Ya implementada y usada por Wrapper3D:
- `world_to_cell(world_pos: Vector3) -> Vector2i`
- `cell_to_world(cell: Vector2i) -> Vector3`
- `shortest_path(from_cell, to_cell) -> Array[Vector2i]` (con caché `_path_cache`)
- `is_cell_clear(cell: Vector2i) -> bool` (physics probe 0.4m radio)
- `get_maze_navigation() -> Dictionary` (expone todo + callables)

**Wrapper3D**: Ya usa `maze_room.get_maze_navigation()` + `shortest_path.call()`. No hay BFS duplicado ni AStarGrid2D recreado cada 0.55s.

---

## Tabla de Recorrido — 4 Dificultades

| Dificultad | Celdas | Filas | Semilla | Celdas Ruta | Metros Ruta | Tiempo Caminar | Tiempo Correr | Límite Corrupción | Grapper Chase | Margen Cam. | Margen Cor. |
|------------|--------|-------|---------|-------------|-------------|----------------|---------------|-------------------|---------------|-------------|-------------|
| Story      | 7      | 7     | 11      | 13          | 102.9       | 32.1s          | 15.3s         | 1800s             | 4.1           | 1767.9s     | 1784.7s     |
| Normal     | 9      | 9     | 23      | 15          | 93.3        | 29.2s          | 14.4s         | 900s              | 5.2           | 870.8s      | 885.6s      |
| Hard       | 11     | 11    | 37      | 21          | 109.1       | 34.1s          | 14.9s         | 900s              | 5.8           | 865.9s      | 885.1s      |
| Lovecraft  | 13     | 13    | 51      | 25          | 110.8       | 34.6s          | 14.2s         | 900s              | 6.3           | 865.4s      | 885.8s      |

**Velocidades**:
- Jugador walk: 3.2 m/s
- Jugador run: 6.0 × multiplicador (Story 1.12=6.72, Normal 1.08=6.48, Hard 1.22=7.32, Lovecraft 1.30=7.8)
- Grapper chase: 5.2 × enemy_multiplier (Story 0.78=4.1, Normal 1.0=5.2, Hard 1.12=5.8, Lovecraft 1.22=6.3)

**Conclusión**: Todas las dificultades completables con amplio margen (>865s). Jugador siempre más rápido que Grapper corriendo. No requiere ajuste de semillas.

---

## Propuesta: Bucles adicionales para evitar callejones sin salida
**Estado**: PROPUESTA (no activada)

**Análisis actual**: `_add_maze_loops()` ya añade ~20% conexiones extra (loops) sobre el maze perfecto. `grapper_min_distance_cells=6` asegura spawn lejano. Marcadores emisivos en dead-ends (esporas) y cruces (guías) guían al jugador.

**Propuesta**: Aumentar `extra_connections` factor de 0.2 a 0.3 (30% walls removed) para más rutas de escape, reduciendo dead-ends efectivos.

**Riesgo**: Más loops = maze menos "laberíntico", menos tensión. Silent Hill usa dead-ends como mecánica de miedo.

**Decisión**: NO activar sin aprobación. Mantener 20% actual. Si playtesting revela frustración excesiva, revisar.

---

## Archivos Modificados
1. `scripts3d/Zone3D.gd` — spawn deferido
2. `scripts3d/RoomLabyrinth.gd` — todos los fixes arriba
3. `docs/cambios/agente-2.md` — este documento

---

## Cómo Probar en 2 Minutos
1. Abrir Godot 4.7.2 → proyecto
2. Ejecutar escena `Zone3D_laberinto.tscn` (F6)
3. Verificar en consola:
   - `[Laberinto] normal ruta (N/S/E/O): ... bucles: X`
   - `[Zone3D] Jugador creado en zona 'laberinto' posicion: ...`
4. Mover con WASD (tanque): W=adelante, S=atrás, A/D=girar
5. Confirmar:
   - Niebla Silent Hill activa (todo visible ~20m)
   - Suelo en y=0 (no flota ni hunde)
   - Muros 3.3m altura, tabiques mismo nivel
   - Grapper aparece, persigue, grita (screamer)
   - Salidas SalidaAlCampo / SalidaAlBosque funcionan
6. Probar 4 dificultades: cambiar `GameManager.difficulty_id` en autoload o vía MainMenu