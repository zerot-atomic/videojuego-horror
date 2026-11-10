# PLAN DE PRUEBAS — La Cosecha del Color
**Versión**: 1.0  
**Fecha**: 2026-11-05  
**Fases**: Revisión Final (20/11/2026) → Gold Master (30/11/2026)  
**Motor**: Godot 4.7.2 — Renderer: gl_compatibility  
**Build objetivo**: Windows 64-bit / Android (opcional)

---

## MATRIZ DE PRUEBAS: Escenario × Modo/Ruta × Dispositivo

| Escenario (Zona / Función) | Story | Normal | Hard | Lovecraft | Teclado | Gamepad | Touch |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **1. Movimiento tanque (WASD / stick izq)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **2. Cámara sigue al cuerpo (lag suave)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **3. Correr (Shift / L-Stick) drena cordura** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **4. Agacharse (C / B) reduce ruido/vista** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **5. Interactuar (E / A) - pistas/objetos** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **6. Diario (Tab / Y) abre/ciérra** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **7. Pausa (Esc / Start) menú** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **8. Niebla activa en TODAS las 9 zonas** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **9. Parámetros niebla por zona (ZONE_FOG)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **10. Sin sombras (shadow_enabled=false)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **11. Transición camino_entrada → casa_principal** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **12. Transición casa_principal → camino_entrada** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **13. Transición casa_principal → campo_cultivo** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **14. Transición campo_cultivo → casa_principal** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **15. Transición campo_cultivo → pozo** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **16. Transición campo_cultivo → establo (req. llave)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **17. Transición campo_cultivo → laberinto (req. aceite)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **18. Transición establo → campo_cultivo** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **19. Transición laberinto → bosque (dinámica)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **20. Transición laberinto → campo_cultivo (dinámica)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **21. Transición bosque → laberinto** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **22. Transición crater_meteorito → camino_entrada** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **23. Transición atico → casa_principal** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **24. Transición casa_principal → atico** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **25. Pozo: decisión buen final (req. manivela + 3 visiones)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **26. Pozo: decisión mal final (retirarse)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **27. Enemigo: patrulla (establo)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **28. Enemigo: persecución (laberinto)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **29. Enemigo: detección vista (cono 110° + raycast)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **30. Enemigo: detección oído (radio ruido)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **31. Enemigo: agachado reduce vista 0.45x** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **32. Enemigo: tropiezo 35% al chocar** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **33. Navegación laberinto: BFS grafo (primario)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **34. Navegación laberinto: AStarGrid2D (fallback)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **35. Escalado dificultad: velocidad enemigo** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **36. Escalado dificultad: multiplicador corrida laberinto** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **37. Escalado dificultad: tiempo corrupción** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **38. Escalado dificultad: drenaje cordura** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **39. Visión Padre (ganado establo, req. llave_oxidada)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **40. Visión Madre (diario ático)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **41. Visión Hijo (zapato bosque → laberinto)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **42. HUD: barra cordura, mensaje corrupción, avisos** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **43. Overlay corrupción (pulso HSV)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **44. Música: crossfade fondo/climax/persecución** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **45. Música: tensión por zona + presión amenaza** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **46. SFX espacial: grito Grapper (3D, 12m/80m)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **47. Screamer: flash + imagen + audio distorsionado** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **48. MaterialFixer: 100+ materiales GLB** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **49. Guardado/carga (JSON user://)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **50. FPS ≥ 30 en gl_compatibility (todas zonas)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**Leyenda**: ✅ = Prueba obligatoria | 🔄 = Repetir en regresión | ⚠️ = Riesgo conocido

---

## CASOS DE PRUEBA OBLIGATORIOS (Mínimo para Gold Master)

| ID | Título | Prioridad | Criterio de paso |
|----|--------|-----------|------------------|
| TC-01 | Movimiento tanque puro (W/S adelante/atrás, A/D girar) | Crítico | Personaje gira y avanza relativo a SU facing_angle, no a cámara |
| TC-02 | Cámara sigue con lag (camera_follow_speed=2.6) | Crítico | camera_yaw interpola a facing_angle suavemente |
| TC-03 | Niebla WorldEnvironment creada en _apply_zone_fog() | Crítico | env.fog_enabled=true, mode=1, parámetros desde ZONE_FOG |
| TC-04 | RoomLabyrinth NO usa su _build_environment() final | Crítico | Zone3D._apply_zone_fog() elimina WorldEnvironment de room |
| TC-05 | Sombras desactivadas en TODAS las luces | Crítico | OmniLight3D.shadow_enabled=false en RoomLabyrinth, Zone3D, Room_* |
| TC-06 | 9 zonas conectadas bidireccionalmente | Crítico | EXITS + ExitArea3D coinciden en ambos sentidos |
| TC-07 | Pozo: buen final requiere manivela + 3 visiones | Crítico | decide_ending() → trigger_ending(true) solo si corruption<limit Y all_visions_seen() |
| TC-08 | Pozo: mal final siempre disponible | Crítico | examine_clue("retirarse") → trigger_ending(false) sin requisitos |
| TC-09 | Enemigo laberinto usa BFS grafo RoomLabyrinth | Alto | _maze_waypoint_toward() llama _get_maze_navigation() |
| TC-10 | Fallback AStarGrid2D usa cell_size=6.67 (GAMEPLAY) | Alto | _maze_waypoint_toward() línea 385: cell_size := lm.cell_size |
| TC-11 | Parámetros centralizados: sin @export duplicados | Alto | Player3D, Wrapper3D, HUD leen de GameManager.GAMEPLAY |
| TC-12 | LABYRINTH_RUN_MULTIPLIERS unificado (3 referencias) | Alto | Player3D.get_effective_run_speed(), _apply_tank_movement(), Zone3D._spawn_player() |
| TC-13 | Modelo inspector transform=identity en Player3D.tscn | Alto | inspector transform = Transform3D(1,0,0, 0,1,0, 0,0,1, 0,0,0) |
| TC-14 | CollisionShape3D Y=0.9 (centro cápsula 1.8) | Alto | scenes3d/Player3D.tscn: transform.y = 0.9 |
| TC-15 | InteractionArea Y=1.0 | Alto | scenes3d/Player3D.tscn: transform.y = 1.0 |
| TC-16 | Spawn offset Y=0.1 en Zone3D._spawn_player() | Medio | p.global_position = spawn.global_position + Vector3(0, 0.1, 0) |
| TC-17 | Colores niebla contrastan con dirt_02.png | Medio | ZONE_FOG light_color más cálidos/claros que suelo |
| TC-18 | Room_bosque exit renombrado a Exit_to_laberinto_0 | Medio | target_zone_id="laberinto" coincide |
| TC-19 | Guardado persiste: sanity, corruption, zone, clues, visions, inventory | Medio | save_game() / load_game() JSON completo |
| TC-20 | FPS ≥ 30 en laberinto (peor caso: 13x13, luces, CSG) | Medio | Profile en Godot 4.7.2 gl_compatibility |

---

## DISPOSITIVOS DE PRUEBA REQUERIDOS

| Dispositivo | Configuración | Notas |
|-------------|---------------|-------|
| **Teclado** | WASD + Shift + C + E + Tab + Esc | Controles por defecto InputProfiles |
| **Gamepad** | Xbox/PS layout (A/B/X/Y, sticks, triggers, D-pad) | InputProfiles registra JOY_AXIS_LEFT_X/Y, JOY_BUTTON_* |
| **Touch (Android)** | MobileTouchControls (joystick virtual + botones) | Player3D._ready() instancia si OS.has_feature("android") |

---

## ENTORNO DE EJECUCIÓN

```bash
# Verificación build
godot --headless --script check_build.gd  # (script personalizado)

# Perfil FPS (ejemplo)
godot --verbose -e --main-pack build/LaCosecha.pck 2>&1 | grep -E "FPS|frame"
```

---

## CRONOGRAMA

| Hito | Fecha | Entregable |
|------|-------|------------|
| **Code Freeze** | 2026-11-15 | Sin nuevos features, solo fixes Critical/High |
| **Revisión Final (QA)** | 2026-11-20 | Este plan ejecutado, REGISTRO_DE_BUGS.md completado |
| **Fix Critical/High** | 2026-11-22 | Correcciones aplicadas, regresión pass |
| **Gold Master Candidate** | 2026-11-25 | Build candidato firmado |
| **Gold Master** | 2026-11-30 | REPORTE_FINAL.md → Go/No-Go |