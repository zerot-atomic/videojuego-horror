# Controles multiplataforma — beta 0.1.8

## Configuración

Abre **Opciones → Controles** desde el menú de ajustes para reasignar las acciones. Cada acción conserva su asignación de teclado y de mando; el juego guarda los cambios localmente en `user://input_bindings.cfg`. **Restaurar valores predeterminados** vuelve a las asignaciones incluidas con el juego. WASD, stick izquierdo y joystick táctil usan un marco direccional relativo a la cámara que se mantiene estable mientras el jugador sostiene una dirección; la cámara está anclada al jugador y acompaña suavemente sus giros. Las opciones generales de volumen y pantalla completa siguen disponibles en la pestaña **General**.

| Acción | Teclado inicial | Mando inicial |
|---|---|---|
| Avanzar / retroceder | W / S y flechas arriba / abajo | Stick izquierdo / cruceta |
| Girar izquierda / derecha | A / D y flechas izquierda / derecha | Stick izquierdo / cruceta |
| Correr | Shift | Stick izquierdo presionado (L3) |
| Agacharse | C | B |
| Interactuar | E | A |
| Diario | Tab | Y |
| Pausa | Escape | Start |

La navegación de menús también admite cruceta, stick y botones del mando. Las teclas y botones se pueden volver a asignar desde la pantalla de controles.

## Pantalla táctil

En Android y dispositivos con pantalla táctil aparece un joystick virtual direccional y botones para correr, agacharse, interactuar, abrir el diario y pausar. El diario tiene un botón **Cerrar** dentro de la ventana, accesible con tacto. Las visiones de personaje incluyen un botón **Continuar** en Android; teclado y mando siguen avanzando con Aceptar. Al iniciar una partida nueva, una tarjeta breve presenta el caso y explica qué buscar. La exportación Android está configurada en orientación horizontal. La interfaz táctil y el rendimiento aún requieren validación en dispositivos físicos; esta entrega no certifica compatibilidad con todos los teléfonos.

En el menú principal, la frase bajo el título se elige al azar sin repetir la última sesión. Si el menú sigue abierto, cambia con un fundido tras un intervalo aleatorio de 15 a 30 minutos.

## Estado de las plataformas

- **Windows:** ejecutable de beta para escritorio.
- **Android:** APK de QA firmado con la clave de depuración de Godot. Sirve para pruebas privadas; no se debe publicar en una tienda. Para una distribución de producción hace falta firmar con una clave privada de lanzamiento y conservarla de forma segura.
- **Consolas:** el juego ya recibe entradas de mando y permite navegar los menús con él, pero esta carpeta no contiene un paquete de PlayStation, Xbox o Nintendo. Exportar a esas plataformas requiere acceso aprobado al programa del fabricante, sus SDK y plantillas de exportación específicas. La disponibilidad y el proceso dependen de la plataforma elegida.

## Artefactos de esta beta

Los tamaños y hashes SHA-256 de los paquetes entregados se encuentran en [`../dist/MANIFIESTO_BETA_0.1.8_MULTIPLATAFORMA.txt`](../dist/MANIFIESTO_BETA_0.1.8_MULTIPLATAFORMA.txt). La firma del APK se verifica al exportar. La validación de rendimiento aún requiere hardware Android; no se probó en una consola física.

La implementación de entradas no cambia el sistema de cordura.


