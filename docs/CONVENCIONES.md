# Convenciones Compartidas — La Cosecha del Color

**Versión**: 1.0  
**Fecha**: 2026-11-06  
**Autor**: Agente 1 (primeros 15 min)

---

## 1. Convención de "Adelante" (Forward)

| Sistema | Convención |
|---------|------------|
| **Código (Player3D, Wrapper3D, RoomLabyrinth, Zone3D)** | **+Z local = adelante** |
| **Modelo (inspector.glb, estándar Godot glTF)** | **-Z local = adelante** (mirando hacia -Z) |
| **Cámara** | Detrás del personaje: posición relativa **-Z** respecto al cuerpo |

**Regla**: El código usa **+Z = forward**. El modelo nativo mira a **-Z**. Para alinear: **rotar modelo 180° en Y** (rotation_degrees.y = 180). **No usar escala negativa en Z**.

**Verificación**: En Player3D.gd línea 297: `forward_dir := Vector3(sin(facing_angle), 0.0, cos(facing_angle))` → facing_angle=0 ⇒ forward = (0,0,1) = **+Z**.

---

## 2. Origen del Jugador (Pies en el Suelo)

| Elemento | Valor | Notas |
|----------|-------|-------|
| **Suelo de toda zona** | Cara superior en **y = 0** (World) | Zona scenes: floor mesh en y=0 |
| **Spawns** | Pies apoyados en y=0, sin flotar ni hundirse | Zone3D._spawn_player() usa global_position.y = 0.1 (spawn_offset) solo para evitar "stuck" inicial |
| **Cápsula de colisión (stand)** | Altura 1.8 m, centro en **y = 0.9**, base en **y = 0** | GAMEPLAY.player.stand_capsule_height = 1.8, collision_y_offset = 0.04 |
| **ModelPivot.position.y** | Calculado: **-min_y_mesh * escala** | min_y_mesh ≈ -0.349 (AABB inspector.glb), escala = 1.8 / 0.6985 = 2.5766 ⇒ **0.9007** |

**Regla**: El origen del CharacterBody3D (Player3D) está a **nivel de pies (y=0)**. La cápsula y el modelo se posicionan para que sus pies queden en y=0.

---

## 3. Orientación de Spawns

| Zona | Spawn mirando hacia | facing_angle (rad) | Comentario |
|------|---------------------|---------------------|------------|
| camino_entrada | Hacia la casa (centro zona) | 0 (hacia +Z) | |
| casa_principal | Hacia el centro de la sala | 0 | |
| campo_cultivo | Hacia el pozo / centro | 0 | |
| pozo | Hacia la manivela / decisión | 0 | |
| crater_meteorito | Hacia el camino de vuelta | 0 | |
| establo | Hacia el ganado / puerta | 0 | |
| atico | Hacia la ventana / diario | 0 | |
| bosque | Hacia el sendero / laberinto | 0 | |
| laberinto | Hacia la primera celda / centro | 0 | |

**Regla**: `facing_angle = 0` = mirando hacia **+Z mundial**. Zone3D._spawn_player() llama a `player.set_facing(0)` por defecto. Si una zona necesita otra orientación, pasa el ángulo en radianes.

---

## 4. Controles Tipo Tanque (Único Esquema)

| Acción | Teclado | Mando (Left Stick) | Joystick Táctil |
|--------|---------|---------------------|-----------------|
| Avanzar (W) | W / Flecha Arriba | Eje Y negativo (arriba) | Stick arriba |
| Retroceder (S) | S / Flecha Abajo | Eje Y positivo (abajo) | Stick abajo |
| Girar Izquierda (A) | A / Flecha Izquierda | Eje X negativo (izquierda) | Stick izquierda |
| Girar Derecha (D) | D / Flecha Derecha | Eje X positivo (derecha) | Stick derecha |
| Correr | Shift Izq/Der | L3 (pulsar stick izq.) | Botón "CORRER" (hold) |
| Agacharse | C | Botón B / Círculo | Botón "AGACHARSE" |
| Interactuar | E | Botón A / Cruz | Botón "USAR" |
| Diario | Tab | Botón Y / Triángulo | Botón "DIARIO" |
| Pausa | Esc | Botón Start / Menú | Botón "PAUSA" |

**Regla**: **No existe selector de esquema**. Solo tanque. `control_scheme` en GameManager y menú de ajustes → **eliminar**.

---

## 5. Cámara

| Parámetro | Valor | Fuente |
|-----------|-------|--------|
| Distancia (SpringArm.length) | 4.3 m | GAMEPLAY.player.camera_distance |
| Altura (CameraPivot offset Y) | 1.6 m | GAMEPLAY.player.camera_height |
| Pitch mínimo | -0.5 rad (≈ -28.6°) | GAMEPLAY.player.camera_pitch_min |
| Pitch máximo | 0.6 rad (≈ 34.4°) | GAMEPLAY.player.camera_pitch_max |
| Seguimiento yaw (lerp) | 2.6 | GAMEPLAY.player.camera_follow_speed |
| Top-level | Sí (CameraPivot.set_as_top_level(true)) | Player3D._ready() |

**Regla**: CameraPivot es top-level; su posición/rotación son mundiales. SpringArm hijo de CameraPivot coloca la cámara a **-Z relativo** (detrás del personaje).

---

## 6. Escalado del Modelo

| Parámetro | Valor | Cálculo |
|-----------|-------|---------|
| Altura objetivo (cápsula) | 1.8 m | GAMEPLAY.player.stand_capsule_height |
| Altura AABB mesh (inspector.glb) | 0.6985 m | Medido: max_y - min_y |
| Escala uniforme | **2.5766** | 1.8 / 0.6985 |
| Rotation Y | **180°** | Alinea -Z (modelo) → +Z (código) |
| Position Y (ModelPivot) | **0.9007** | -min_y * escala = 0.349 * 2.5766 |

**Regla**: Escala **siempre positiva y uniforme**. Rotación explícita con `rotation_degrees.y = 180`. Nada de `scale.z = -1`.

---

## 7. Niebla (Silent Hill Style)

- **Única fuente de verdad**: `GameManager.ZONE_FOG` (dict con 9 zonas)
- **Aplicación**: `Zone3D._apply_zone_fog()` crea Environment en runtime
- **Modo**: `Environment.FOG_MODE_DEPTH` (lineal)
- **Nunca desactivar ni hacer invisible**. Parámetros por zona en ZONE_FOG.

---

## 8. Parámetros Centralizados

- **Toda velocidad, sensibilidad, tiempo, daño** → `GameManager.GAMEPLAY` (dict anidado)
- Scripts leen en `_ready()`: `var gp := GameManager.GAMEPLAY.player` etc.
- **No duplicar @export** en Player3D, Wrapper3D, HUD, RoomLabyrinth, Zone3D.

---

## 9. Dificultad

- 4 perfiles: `story`, `normal`, `hard`, `lovecraft`
- Se guarda en `GameManager.difficulty_id` y persiste en savegame
- **No tocar selector de dificultad** (solo control_scheme se elimina)

---

## 10. Guardados (Compatibilidad)

- `settings.json` tiene `control_scheme` legacy → al cargar, **ignorar** o mapear a "tank"
- `savegame.json` no guarda control_scheme
- Guardados viejos **no deben romper**: al cargar settings, si falta control_scheme o vale "directional", tratar como "tank"

---

## Resumen de Valores Clave (para verificación rápida)

```gdscript
# Player3D.tscn - ModelPivot
transform = Transform3D(2.5766, 0, 0, 0, 2.5766, 0, 0, 0, 2.5766, 0, 0.9007, 0)
rotation_degrees = Vector3(0, 180, 0)

# Player3D.tscn - CollisionShape3D (cápsula stand)
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.9, 0)  # centro en y=0.9
shape.height = 1.8  # base en y=0, tope en y=1.8

# GAMEPLAY.player
stand_capsule_height = 1.8
crouch_capsule_height = 1.10
collision_y_offset = 0.04
camera_distance = 4.3
camera_height = 1.6
walk_speed = 3.2
run_speed = 6.0
rotation_speed = 2.0
```

---

## Checklist de Verificación (2 min jugando)

1. [ ] W mueve **alejándose de la cámara** (+Z visual)
2. [ ] S mueve **hacia la cámara**
3. [ ] A gira **izquierda** (desde vista cámara), D gira **derecha**
3. [ ] Cámara **siempre detrás** (dot product camera_forward · character_forward > 0.9)
4. [ ] Altura visual ≈ **1.8 m** (comparar con puertas/muros de 2m)
5. [ ] **Pies en el suelo** (no flotan, no se hunden)
6. [ ] Correr (Shift/L3/Botón CORRER) funciona en teclado, mando, táctil
7. [ ] Niebla visible en **todas las zonas**
8. [ ] Menú ajustes: **no hay selector de esquema de control**