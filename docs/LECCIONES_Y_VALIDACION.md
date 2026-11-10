# Lecciones de la revisión de cámara y jugador

Este documento registra errores reales cometidos al reparar la beta. Debe leerse antes de editar `Player3D.gd`, `Player3D.tscn`, `Zone3D.gd` o exportar una beta.

## Qué salió mal

1. Se trató una vista defectuosa como un problema de posición visual sin comprobar primero si el script del jugador cargaba.
2. Se desplazó `MeshRoot` 0.85 m hacia arriba basándose en el AABB sin validar la pose esquelética del inspector en la escena. El personaje quedó flotando. Ese desplazamiento se revirtió; no volver a introducirlo sin una medición visual y de colisión en ejecución.
3. Un error de inferencia (`movement_yaw` sin tipo explícito) impedía compilar `Player3D.gd`. El escaneo del editor no lo detectó; al cargar directamente `Zone3D_camino_entrada.tscn`, Godot informó el error. La anotación `float` corrige el parseo sin cambiar la fórmula de movimiento.
4. Se confundió “exportó” con “funciona”. La exportación no valida por sí sola la cámara, la pose, el spawn ni el control del jugador.
5. Se generaron varias copias con sufijos como `REVISADA` y `CORREGIDA`, lo que ocultó cuál era la beta que debía probarse. La versión debe conservar la etiqueta que eligió el usuario y el manifiesto debe identificar un único paquete final.

## Comportamiento que se debe preservar

- El cuerpo físico nace en el marcador de spawn con su cápsula apoyada en el suelo.
- La cámara de referencia guardada en `Downloads/LaCosechaDelColor_porte_Godot4.zip` usa `CameraPivot.set_as_top_level(true)`, sigue la posición global del jugador, aplica yaw `camera_yaw + PI` y suaviza `camera_yaw` hacia `facing_angle`. En el estado actual sus valores son distancia 4.3 m, altura 1.6 m y pitch -0.17. Preservar esa conducta; no ajustar cámara para compensar el modelo.
- WASD, mando y joystick táctil mantienen el mismo marco direccional relativo a la cámara. No reescribir esta lógica al solucionar una pose o un error visual.
- El modelo visual debe alinearse a partir de su pose real importada; el root del jugador y la cápsula no se mueven para “arreglar” el render.

## Comprobaciones antes de entregar

1. Cargar la escena jugable directamente con Godot y corregir todo error de parseo o método inexistente.
2. Iniciar la partida desde el menú y observar al jugador en el primer spawn: cámara a distancia normal, pies sobre el suelo, cuerpo completo encuadrado.
3. Probar caminar, girar, diagonal, retroceder, correr y agacharse; comprobar que la cámara acompaña y no curva la trayectoria involuntariamente.
4. Revisar al menos una transición entre zonas y confirmar que el spawn de destino también queda sobre el suelo.
5. Si el escritorio no permite una verificación visual, distinguirla de una prueba headless y dejarla pendiente; no afirmar que la beta es aceptable visualmente.
6. Exportar PC y Android después de validar ejecución. Verificar versión, firma, nombre del paquete, tamaño y hashes; generar un único manifiesto final.

En la revisión 0.1.8 se cargaron las nueve zonas, se simuló un segundo de avance (3.20 m) y se generó una captura renderizada de Camino de Entrada. Estas pruebas comprueban carga, movimiento y encuadre inicial; no sustituyen el recorrido manual completo desde el menú ni la instalación en un teléfono.

## Regla de versiones

La beta 0.1.7b se definió como hotfix por un fallo grave de la 0.1.7. No debe convertirse en una sucesión de `REVISADA`, `CORREGIDA` y variantes sin prueba. El usuario pidió expresamente 0.1.8B como revisión asistida de balance; su motivo y sus comprobaciones están en `docs/REVISION_0.1.8B_JUGABILIDAD.md`.

La cordura aprobada en revisiones anteriores y el comportamiento de la cámara no se reajustan para compensar el balance del perseguidor. Si una medición demuestra que esos sistemas impiden terminar, hay que señalar el conflicto y no ocultarlo con una afirmación de “finalizable”.
