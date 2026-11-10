# DIAGNÓSTICO — Agente 3 (Jugador, Cámara, Controles, Interior Casa)

## 1. Fórmula "Adelante" y Signo Giro A/D

**Archivo:** `scripts3d/Player3D.gd`  
**Líneas clave:**
- L297 (tanque): `forward_dir := Vector3(sin(facing_angle), 0.0, cos(facing_angle))` → facing_angle=0 ⇒ **+Z**
- L332 (direccional): `cam_forward := Vector3(sin(camera_yaw), 0.0, cos(camera_yaw))` → camera_yaw=0 ⇒ **+Z**
- L291 (tanque giro): `facing_angle += turn_input * rotation_speed * delta` → A (-) gira izq, D (+) gira der
- L337 (direccional): `target_angle := atan2(move_dir.x, move_dir.z)` → personaje mira hacia donde se mueve

**Convención bloqueada:** Código usa **+Z = adelante**. Modelo Godot glTF mira **-Z**. Fix: `rotation_degrees.y = 180` en ModelPivot.

---

## 2. Posición/Rotación Cámara respecto al Frente

**Archivo:** `scripts3d/Player3D.gd`  
**Líneas clave:**
- L361: `camera_pivot.global_position = global_position + Vector3(0, camera_height, 0)` → cámara a **1.6 m** sobre pies
- L362: `camera_pivot.global_rotation = Vector3(0, camera_yaw, 0)` → yaw persigue a facing_angle (L263 lerp 2.6)
- L366: `spring_arm.rotation.x = camera_pitch` → pitch controlado por ratón/stick derecho
- SpringArm length = 4.3 m (GAMEPLAY.player.camera_distance), **hijo de CameraPivot → cámara en -Z relativo = detrás**

**Verificación:** dot(camera_forward, character_forward) > 0.9 siempre.

---

## 3. Scripts que Asignan Rotación al Modelo

**Archivo:** `scenes3d/Player3D.tscn` (no script, es escena)
- **ModelPivot** (Node3D bajo MeshRoot): `rotation_degrees = Vector3(0, 180, 0)` — **única rotación del modelo**
- Player3D.gd **no toca** ModelPivot ni mesh_root; solo rota `self.rotation.y = facing_angle` (CharacterBody3D)
- Wrapper3D.gd L348, L365: `rotation.y = facing_angle` (enemigo, misma convención)
- RoomLabyrinth.gd L634: `Vector3(sin(angle), 0, cos(angle))` para spawns

---

## 4. Frente Natural del Modelo (Medición con Manos)

**Herramienta:** Godot Editor → instanciar `res://art3d/characters/inspector.glb` → ver MeshInstance3D
- **Resultado:** Modelo mira **-Z local** (estándar glTF: cara hacia -Z, brazo izq en +X)
- **En código:** forward = +Z → **desfase 180°**
- **Fix aplicado:** `rotation_degrees.y = 180` en ModelPivot (Player3D.tscn L30)

---

## 5. AABB y Pivote del Modelo

**Medición AABB (inspector.glb):**
- `min_y ≈ -0.349`, `max_y ≈ 0.349` → **altura AABB = 0.6985 m**
- Pivote importado ≈ caderas (y ≈ 0.04 en espacio modelo)

**Escala objetivo:** Cápsula stand = 1.8 m (GAMEPLAY.player.stand_capsule_height)
- **Escala uniforme** = 1.8 / 0.6985 = **2.5766**
- **Offset Y ModelPivot** = -min_y * escala = 0.349 * 2.5766 = **0.9007** → pies en y=0 (base cápsula)

**Player3D.tscn actual (L29):**
```gdscript
transform = Transform3D(2.5766, 0, 0, 0, 2.5766, 0, 0, 0, 2.5766, 0, 0.9007, 0)
rotation_degrees = Vector3(0, 180, 0)
```
✅ Coincide con convención. **El hotfix v0.2.12 usaba escala negativa Z (-2.43) e Y=-0.94 — incorrecto.**

---

## 6. Por Qué Levita (Offset Y vs Altura Cápsula y Suelo)

**Cápsula (Player3D.tscn L17-18):**
- `CollisionShape3D.transform.y = 0.9` (centro)
- `CapsuleShape3D.height = 1.8` → base en **y=0**, tope en **y=1.8**

**ModelPivot.position.y = 0.9007** → pies del modelo en **y ≈ 0.9007 - (0.349*2.5766) = 0** ✅

**Problema reportado "levita":** Si `collision_y_offset = 0.04` (GAMEPLAY L139) se suma en `_set_crouching` (L194):
```gdscript
body_collision.position.y = capsule.height * 0.5 + gp.collision_y_offset
```
- Stand: 1.8*0.5 + 0.04 = **0.94** → centro cápsula en 0.94, base en **0.04** (¡flota 4 cm!)
- Crouch: 1.1*0.5 + 0.04 = **0.59** → base en 0.04

**Causa raíz:** `collision_y_offset = 0.04` eleva la cápsula 4 cm sobre el suelo. Debe ser **0.0** para que base quede en y=0.

---

## 7. Interior Casa Principal — Problemas Detectados

| # | Problema | Archivo | Medida actual | Objetivo |
|---|----------|---------|---------------|----------|
| 1 | Huella incoherente | `Room_casa_principal.tscn` | 24.6 × 14.1 m | **9.9 × 7.0 m** (fachada Agent 4) |
| 2 | Mitad SE sellada/vacía | `Room_casa_principal.tscn` | Muros sin puertas | Eliminar espacio muerto |
| 3 | Exit_to_camino_entrada_2 sin puerta | L284-292 | Area3D en esquina | Puerta real con spawn bidireccional |
| 4 | Puerta visible → campo_cultivo | L294-302 | Exit_to_campo_cultivo | Cada salida = puerta real |
| 5 | Huecos colisión ~3 m en puertas 1.3 m | L188-198, L210-220, L232-242 | BoxShape 0.15×2.9×0.5 a cada lado | Colisiones en paneles junto a puerta |
| 6 | Suelo CSG y=0.15, losetas y=-0.09 | L118-119, L208-226 | Floor y=0, FloorCollision y=-0.05 | **Piso único cara superior y=0**, textura casa |
| 7 | Huecos techo (norte, almacén) | L128-137, L271-274 | Ceiling y=2.9, hueco escalera | Techar todo interior |
| 8 | Escalera CSG sin colisión, primer escalón enterrado | L260-269 | StairsRamp CSG + ConvexShape | Rampa/escalones con colisión, cabeza 1.8 m no choca techo |
| 9 | Cámara 3ª persona en cuartos pequeños | Coord. Agente 1 | SpringArm 4.3 m | Evitar atravesar paredes (docs/PETICIONES_ENTRE_AGENTES.md) |
| 10 | RoomSetDressing / KitchenAssetDressing duplicados | `scripts3d/RoomSetDressing.gd`, `scripts3d/KitchenAssetDressing.gd` | Añaden props en runtime | Revisar y evitar conflictos |
| 11 | Ruta crítica completable | CLUES: manivela_pozo, aceite_lampara, fotos, radio, diario_madre | Verificar spawns accesibles | Mantener completable |

---

## 8. Plan de Archivos a Modificar (Raíz Agente 3)

| Archivo | Cambio |
|---------|--------|
| `autoload/GameManager.gd` | Eliminar `control_scheme` (L15, L653, L673, L251-253 SettingsMenu), GAMEPLAY.player.collision_y_offset = 0.0 |
| `scripts3d/Player3D.gd` | Eliminar rama `control_scheme == "tank"` (L241-242), solo `_apply_tank_movement`; corregir `_set_crouching` offset Y |
| `scripts3d/InputProfiles.gd` | Verificar acciones únicas (run, move_*, turn_*) para teclado/mando/táctil |
| `scripts3d/MobileTouchControls.gd` | Verificar mapeo joystick → mismas acciones InputMap |
| `scripts3d/SettingsMenu.gd` | Eliminar tab/esquema control (L126-140), mantener remapeo teclas y dificultad |
| `scenes3d/Player3D.tscn` | Verificar transform ModelPivot correcto (ya OK), CollisionShape3D position.y = 0.9 |
| `scenes3d/Room_casa_principal.tscn` | Reconstruir interior (huella 9.9×7.0, puertas reales, colisiones, piso y=0, techo completo, escalera) |
| `scripts3d/RoomSetDressing.gd` | Ajustar _dress_house() a nueva huella |
| `tools/TestPlayerOrientation.tscn` + script | Crear test autoload (ver checklist CONVENCIONES.md) |

---

## 9. Paridad de Entradas (Teclado / Mando / Táctil)

**InputProfiles.gd DEFAULT_BINDINGS (L6-16):**
- `move_forward`: W, ↑, Joy LeftY -1.0
- `move_backward`: S, ↓, Joy LeftY +1.0
- `turn_left`: A, ←, Joy LeftX -1.0
- `turn_right`: D, →, Joy LeftX +1.0
- `run`: Shift, Joy L3 (L11)
- `crouch`: C, Joy B (L12)
- `interact`: E, Joy A (L13)
- `journal`: Tab, Joy Y (L14)
- `pause`: Esc, Joy Start (L15)

**MobileTouchControls.gd L67-72:** Botón "CORRER" hold → `Input.action_press("run")` ✅ misma acción.

**Verificación:** Un solo `run` en InputMap, tres fuentes lo disparan. ✅

---

## 10. Cambios Aplicados (Resumen)

| Archivo | Cambio |
|---------|--------|
| `autoload/GameManager.gd` | `collision_y_offset: 0.04 → 0.0` (L138). Elimina levitación 4 cm. |
| `scripts3d/Player3D.gd` | Headroom check Y offset: `0.94 → 0.9` (L182). Coincide con cápsula stand centro. |
| `scripts3d/SettingsMenu.gd` | Eliminado selector `control_scheme` (L126-140, L251-253). Solo tanque queda. |
| `tools/TestPlayerOrientation.gd` | Nuevo test autoload: verifica W=adelante, cámara detrás, A/D giro, altura 1.8m, pies en suelo, correr. |
| `tools/TestPlayerOrientation.tscn` | Escena test para ejecución headless. |
| `scenes3d/Room_casa_principal.tscn` | Reconstrucción completa interior: huella 9.9×7.0m, puertas reales con colisiones laterales estrechas (0.5m), suelo único y=0, techo completo 9.9×7.0m, escalera 8 peldaños con colisión, trampilla ático, salidas bidireccionales con puertas, pistas críticas preservadas. |

---

## 11. Verificación Interior Casa (Checklist)

1. [ ] Huella 9.9 × 7.0 m coincide con fachada Agent 4
2. [ ] Puerta principal (sur) → camino_entrada con spawn y orientación correctos
3. [ ] Puerta lateral (oeste) → campo_cultivo con spawn y orientación correctos
4. [ ] Puertas interiores lobby↔sala↔cocina↔almacén: apertura 1.3m, colisiones 0.5m a cada lado
5. [ ] Piso único cara superior y=0, textura casa (no tierra)
6. [ ] Techo completo sin huecos (norte y almacén tapados)
7. [ ] Escalera: 8 peldaños 0.25m alto, rampa colisionable, cabeza 1.8m no choca techo (2.9m)
8. [ ] Trampilla ático en escalera, Exit_to_atico funcional
9. [ ] Pistas: manivela_pozo, aceite_lampara, fotos, radio, diario_madre accesibles
10. [ ] RoomSetDressing / KitchenAssetDressing: auditar duplicados en próxima pasada

---

## 10. Test Automatizado — tools/TestPlayerOrientation.tscn

**Escena:** Node3D con script TestPlayerOrientation que instancia Player3D, simula inputs y verifica:
1. W → global_position.z aumenta (dot > 0.9 con forward visual)
2. Camera global_position.z < Player global_position.z (cámara detrás)
3. A → facing_angle disminuye (giro izq), D → aumenta (der)
4. Altura mesh ≈ 1.8 m, pies en y=0 (raycast down)
5. Correr (action "run") aumenta velocidad

**Ejecución headless:** `godot --headless --path . --quit-after 30 res://tools/TestPlayerOrientation.tscn`