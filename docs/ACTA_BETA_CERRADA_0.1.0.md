# Acta de Beta Cerrada 0.1.0

**Corte de revisión:** 27 de octubre de 2026  
**Motor:** Godot 4.7.2  
**Build:** `dist/La_Cosecha_Beta_Cerrada_0.1.0.exe`  
**Destino:** Windows Desktop x86_64  
**Tipo:** beta cerrada de evaluación; no es una versión pública ni una certificación de lanzamiento.

## Qué quedó listo

- Se agregó un selector de dificultad antes de empezar partida. “Cargar partida” conserva el modo guardado; las partidas antiguas sin campo de dificultad cargan como Normal.
- La dificultad se guarda con el progreso y se vuelve a aplicar al cargar.
- La exportación de Windows está configurada con versión `0.1.0-beta.1`, nombre identificable y escenas/dependencias seleccionadas. El ejecutable final incluye recursos dinámicos usados por el juego y pesa aproximadamente 225 MiB; el tamaño exacto y su SHA-256 están en el manifiesto.
- Se normalizó a minúsculas el nombre de carpeta `textures` del paquete HorrorPackFBX y se actualizaron las referencias del código/metadatos. La importación posterior ya no reportó diferencias de mayúsculas/minúsculas.
- Se incluyeron explícitamente scripts GDScript, recursos `.tres`, texturas e imágenes, así como audio dinámico requerido por clases, configuraciones y cargas en tiempo de ejecución que el filtro de escenas no detecta como dependencias.
- Durante la primera ejecución del binario se detectaron dos recursos no incluidos por el filtro de escenas: el entorno global y `SettingsMenu`. El preset incorpora ahora los globs de scripts, recursos, imágenes y audio; las 14 escenas principales del paquete pasaron la comprobación en el paquete anterior a esta exportación final.
- Se documentaron los controles, perfiles, limitaciones conocidas y formulario de reporte para testers en `dist/LEEME_BETA.md`.

## Perfiles de dificultad

| Dificultad | Caída de cordura | Límite de corrupción | Terror/cámara | Presión de Grapper |
|---|---:|---:|---:|---:|
| Modo Historia | 0.35× | 30 min | 0.65× | 0.78× |
| Normal | 1.00× | 15 min | 1.00× | 1.00× |
| Difícil | 1.35× | 12 min | 1.30× | 1.06× |
| Lovecraft | 1.80× | 10 min | 1.65× | 1.10× |

La caída de cordura aplica a todas las fuentes que llaman `GameManager.drain_sanity`, incluida la carrera en corrupción y los ataques. La presión del perseguidor ajusta velocidad, daño y detección en las escenas con Grapper. El modo Lovecraft intensifica la inestabilidad y reduce mucho el margen de error, conservando una diferencia limitada de velocidad para que las rutas y decisiones todavía permitan escapar; la dificultad se centra en sobrevivir y administrar cordura/tiempo, no en una condición secreta imposible.

## Validación ejecutada

- **16/16 escenas del proyecto** cargaron en modo headless sin errores de parser, scripts ni escenas ausentes: menú, créditos, ambos finales, wrapper y prueba, screamer y nueve zonas.
- **14/14 escenas principales** cargaron desde el ejecutable exportado, incluidas las nueve zonas, los dos finales, menú, créditos y screamer.
- **4/4 perfiles** pasaron comprobación de parámetros y escala de pérdida de cordura.
- **Exportación final de Windows:** terminó con código 0 y generó el ejecutable de beta.
- **Arranque headless del ejecutable:** terminó con código 0 en la validación anterior; la exportación final recompila el mismo preset con el código actual.
- El tamaño y SHA-256 del ejecutable y la copia de fuentes están registrados en `dist/MANIFIESTO_BETA.txt`.
- No se verificó una partida completa usando teclado en una sesión visual; las pruebas anteriores no confirman que todas las interacciones y transiciones se sientan bien en juego.

## Hallazgos y conteo

Conteo de esta revisión, sin mezclar avisos de portabilidad con fallos que impidan iniciar la build:

- **0 errores de carga de escena** en las escenas verificadas.
- **0 fallos en las cuatro pruebas de dificultad.**
- **0 errores de exportación en la exportación final.** La primera pasada con filtro de escenas no traía la lista `export_files`; se completó el preset y la exportación final pasó.
- **0 avisos de mayúsculas/minúsculas** después de normalizar la carpeta y reimportar los ocho recursos. La build se puede mover a un filesystem sensible a mayúsculas sin esa incompatibilidad conocida.
- Se encontraron y cerraron **2 dependencias faltantes** del primer paquete (entorno y Opciones), más **14 referencias con uso de mayúsculas inconsistente** en HorrorPackFBX. No quedan errores abiertos de carga en las escenas verificadas.
- Los procesos headless que se cierran de inmediato tras iniciar música reportan referencias OGG vivas al apagarse. Se asocia al cierre abrupto usado por la prueba; no se midió una salida normal desde el menú y se debe confirmar con testers.
- No se encontró un repositorio Git en la carpeta. Se creó `dist/La_Cosecha_Fuentes_Beta_Cerrada_0.1.0.zip` como copia de respaldo recuperable, excluyendo caché `.godot` y el propio directorio `dist`.

## Pendientes que pueden reportar los testers

1. Recorrer el camino, bosque, campo, establo, casa, ático, cráter, pozo y laberinto en un orden normal.
2. Probar en particular agacharse/levantarse, retroceder agachado, escaleras, trampilla y todas las puertas; observar si el jugador despega del suelo o si el control queda bloqueado.
3. Confirmar la lectura de la dificultad seleccionada, pérdida de cordura, aparición/intensidad de Grapper y si el laberinto permite escapar.
4. Completar pistas, inventario, visiones y ambos finales; cerrar y volver a cargar para comprobar progreso.
5. Revisar música, voz y efectos con audífonos y altavoces; notificar cualquier corte, volumen excesivo o sonido desfasado.
6. Salir normalmente desde el menú y reportar si el proceso permanece abierto.

## Seguridad y distribución

La clave de ElevenLabs compartida anteriormente no aparece dentro del proyecto ni en esta build. Para entregar la beta a personas externas, revocarla y crear una nueva sigue siendo una acción pendiente en la cuenta del autor; la nueva clave debe quedar solo en una variable de entorno local.

Comparte el ejecutable de `dist/` y conserva esta acta. No distribuyas los ZIP de recursos ni la carpeta de desarrollo como parte de la beta. Cualquier error bloqueante debe detener la ronda de testers y generar una nueva build numerada.

## Decisión

**Build 0.1.0 lista para una beta cerrada de evaluación en Windows x86_64**, con las reservas indicadas: no es una partida certificada de principio a fin y quedan pendientes la rotación de la clave compartida y la comprobación de salida normal.

## Anexo de cambios de escenas — 28 de octubre de 2026

Después del corte de la build 0.1.0 se corrigieron detalles de arte y colocación: se aplicó el tile `grass_01.png` al suelo del campo y se limitaron ahí los elementos procedurales; se reemplazó el frente superpuesto del establo del patio por un granero texturizado con portones corredizos, dejando el del camino cerrado; se retiraron los nueve bloques morados del cráter; y se movió el Grapper desde el muro central del laberinto al primer corredor detrás del jugador. La referencia de sala principal y la de establo están registradas en `REVISION_VISUAL_CASA.md`.

Godot 4.7.2 cargó en modo headless las zonas de campo, camino, laberinto y cráter sin errores de parser/recursos. Las advertencias de referencias vivas al terminar de inmediato se describen en la sección anterior. **La build y el ZIP 0.1.0 ya exportados no incluyen este anexo de cambios:** volver a exportarlos con una versión/build nueva y repetir la revisión visual antes de entregar esos cambios a testers. La persecución del Grapper y el aspecto de las escenas requieren verificación en una partida con ventana; no se marcaron como probados aquí.
