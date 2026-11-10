# Revisión de preparación para beta (histórica)

**Fecha:** 27 de octubre de 2026  
**Motor:** Godot 4.7.2  
**Plataforma configurada:** Windows Desktop, x86_64  
**Estado:** reemplazada por [Acta de Beta Cerrada 0.1.0](ACTA_BETA_CERRADA_0.1.0.md), creada después de exportar y verificar la build.

## Resumen ejecutivo

El proyecto arranca en un menú 3D y contiene nueve zonas jugables, dos finales, créditos, diario, ajustes, guardado local, transiciones de puerta/trampilla y el perseguidor Grapper. En la comprobación estática y de carga descrita aquí no aparecieron errores de parser ni escenas ausentes.

Todavía no recomiendo anunciar una beta pública. Faltan pruebas de recorrido real con teclado/control, verificación del ejecutable exportado y una pasada de regresión sobre problemas que ya se reportaron durante el desarrollo: agacharse y subir escaleras, transiciones que se quedan bloqueadas, navegación del laberinto y persistencia al reiniciar. No se encontró una suite automatizada de pruebas del juego.

## Alcance y evidencia

- Se revisaron la configuración del proyecto, el preset de exportación, los autoloads, las escenas jugables y los scripts principales mediante el grafo del código.
- Se cargaron en modo headless 16 escenas: menú, créditos, finales, wrapper y escena de prueba, screamer y las nueve zonas. No aparecieron errores de parser, scripts ni escenas faltantes.
- Godot imprimió al cerrar algunos procesos headless `ObjectDB instances were leaked` y `resources still in use`. En una inspección detallada, al menos dos referencias pertenecían a la reproducción de `audio/musica_fondo.ogg` cuando el proceso se cerró inmediatamente. Esto no demuestra un fallo durante el cierre normal del juego; debe comprobarse en una salida normal.
- Se hizo una búsqueda de claves en el proyecto. No se encontró una clave literal de ElevenLabs; solo aparecen instrucciones y marcadores para usar `ELEVENLABS_API_KEY` mediante variable de entorno.
- No se exportó ni ejecutó un paquete beta. Tampoco se recorrieron todas las zonas con una partida controlada.

## Inventario funcional observado

| Área | Estado observado | Verificación que falta para beta |
|---|---|---|
| Menú, pausa, ajustes y créditos | Escenas y scripts presentes; ajustes guardan volumen, pantalla completa y esquema de control. | Probar navegación, volver al juego y persistencia de ajustes tras reinicio. |
| Zonas | Camino, casa, establo, campo, bosque, pozo, ático, cráter y laberinto; cada zona arma escenario, jugador, HUD y ambiente. | Completar el recorrido de principio a final sin usar saltos de escena del editor. |
| Casa y ático | La casa tiene recibidor, sala, cocina y almacén; la escalera conecta con el ático y la salida superior usa trampilla. | Comprobar colisiones, objetos, manivela, escalera y transición desde la posición del jugador. |
| Movimiento | Movimiento tipo tanque, carrera, agacharse y animaciones para desplazamiento agachado; la cápsula se cambia de altura alrededor de su base. | Repetir agacharse/levantarse junto a paredes, bajo techo, en suelo irregular y en escaleras; confirmar que el eje Y no deriva. |
| Puertas y carga de zona | El autoload valida el destino, congela al jugador, anima puerta o trampilla y tiene una ruta de recuperación ante error de carga. | Activar cada salida, probar entradas en ambos sentidos y comprobar una carga fallida sin bloqueo permanente. |
| Grapper | Hay estados de patrulla, persecución, búsqueda y ataque; el jugador alimenta presión de audio y vibración de cámara según distancia. | Probar línea de visión, pérdida del jugador, rutas estrechas, recuperación tras perderlo y escape del laberinto. |
| Laberinto y screamer | El laberinto se genera al cargar y hay una capa de susto a pantalla completa. | Confirmar que existe una ruta completa, que no aparece dentro de una pared y que el susto/audio se dispara una sola vez por evento. |
| Interacciones e historia | Diario, pistas, inventario, mensajes de HUD y anuncio de llegada por zona están implementados. | Revisar que cada objeto importante tenga prompt, respuesta y estado persistente; confirmar que la narración esté cerrada. |
| Guardado | Se serializan cordura, tiempo de corrupción, zona, pistas, diario, visiones e inventario en `user://`. | Guardar y cargar en cada punto relevante; probar archivo ausente, incompleto y transición mientras se guarda. |
| Audio y voces | Hay pistas de fondo, persecución, clímax y finales; el script de ElevenLabs toma la clave del entorno. | Validar mezcla en audífonos/altavoces, volumen, repetición de pistas y que la línea de inspector sea la versión aprobada. |
| Recursos y licencias | Las atribuciones y licencias integradas están listadas en `docs/ASSET_CREDITS.md`. | Revisar que cada nuevo audio/modelo que se incluya en una build figure en el inventario de licencias. |

## Bloqueos y riesgos antes de invitar testers

### P0 — clave de ElevenLabs compartida

La clave API se pegó en una conversación anterior. Aunque no apareció escrita en el proyecto durante la búsqueda, se debe revocar y generar una nueva antes de cualquier beta externa. La clave nueva debe entregarse al script solo como variable de entorno y no añadirse a Git, capturas, logs ni builds.

### P1 — regresión jugable sin cerrar

No hay evidencia registrada de un recorrido completo hecho en juego. Priorizar la secuencia exterior → establo/campo → casa → ático → pozo/cráter → laberinto → finales y ejecutar las comprobaciones de la tabla. En especial, confirmar el ajuste de altura del cuerpo al agacharse y que el control vuelve después de cada transición.

### P1 — build de beta no validada

El preset actual es Windows Desktop x86_64, con el PCK embebido y salida configurada como `../LA COSECHA.exe`. No se comprobó la exportación, instalación limpia, arranque fuera del editor ni cierre normal. Antes de distribuir, dirigir la salida a una carpeta `dist/` o a una carpeta de release dedicada, poner nombre y versión de producto, y probar el paquete desde una copia limpia sin depender de `.godot/`.

### P1 — no hay historial Git

La carpeta del proyecto no está inicializada como repositorio Git. Antes de abrir una beta se necesita una versión etiquetada y una copia de respaldo recuperable para poder reproducir y corregir reportes. No hay un commit/tag de referencia contra el que comparar regresiones.

### P2 — rutas de textura con diferencia de mayúsculas

La importación de Godot avisó que algunos recursos bajo `art3d/horror_pack/` piden `textures/` pero en disco están en `Textures/`. Windows suele tolerar esa diferencia; una plataforma con filesystem sensible a mayúsculas puede perder texturas. Corregir referencias y volver a importar antes de considerar Linux/macOS.

### P2 — referencias de audio al cerrar el smoke test

La salida inmediata del proceso headless detectó referencias aún vivas a la pista OGG. Confirmar cierre normal con la música activa y pausada; si persiste, detener y liberar los reproductores en el cierre del autoload.

### Contenido que sigue provisional

- El establo aún usa una representación provisional de animales; no se verificó un modelo definitivo de vaca.
- La línea de voz del inspector está marcada como provisional hasta cerrar la narración.
- Las capturas existentes son material de referencia y no sustituyen la comprobación visual en una build recién exportada.

## Checklist de aceptación de beta cerrada

Marcar cada punto solo después de probarlo en una build exportada, no solo al cargar la escena en el editor.

- [ ] Arranque en máquina limpia, menú, nueva partida y regreso al menú.
- [ ] Recorrer todas las salidas y verificar que cada mensaje de llegada corresponda a la zona correcta.
- [ ] Movimiento normal, giro, carrera, agacharse, gateo hacia delante/atrás, levantarse bajo techo y subir/bajar la escalera sin desplazamiento vertical inesperado.
- [ ] Interactuar con pistas, manivela, diario, inventario y elementos de progreso en el orden previsto.
- [ ] Ejecutar las transiciones de puerta y trampilla repetidamente; ninguna debe dejar pantalla negra, bloquear input o congelar al jugador indefinidamente.
- [ ] Hacer que Grapper detecte, persiga, pierda y vuelva a buscar al jugador; escapar del laberinto y verificar el screamer.
- [ ] Completar ambos finales y los créditos.
- [ ] Guardar, cerrar, volver a abrir y cargar; comprobar zona, progreso, diario, inventario, cordura y ajustes.
- [ ] Probar audio con auriculares y altavoces, con sliders bajos y altos; confirmar que música, voz y efectos sigan inteligibles.
- [ ] Cerrar desde el juego con música activa y en pausa; revisar logs y confirmar que no queda pantalla/proceso colgado.
- [ ] Exportar release x86_64 y ejecutarlo desde una copia limpia del paquete, sin el editor ni caché de importación.
- [ ] Etiquetar versión, archivar copia del proyecto y compartir a testers instrucciones de controles, cómo enviar reportes y dónde guardar logs.

## Resultado recomendado

**Decisión actual: no abrir todavía una beta pública.** El proyecto puede pasar a una beta cerrada de validación cuando se roten las claves, se complete la regresión jugable, se genere y pruebe un ejecutable independiente y se guarde una versión etiquetada con respaldo. Registrar cada bug con escena, pasos, resultado esperado/real, frecuencia, build y captura o log.
