# Revisión de correcciones para beta — 29 de octubre de 2026

## Ajustes realizados

- **Campo de cultivo / pasto:** se mantuvo el suelo de pasto existente y se hizo más legible su material; se aclaró moderadamente el tono de la vegetación procedural y se elevó un poco la luz ambiental y de relleno. La escena conserva su atmósfera nocturna.
- **Habitación principal:** se añadió iluminación cálida local y una imagen familiar al marco que ya existía. El suelo sigue siendo de madera; no se puso pasto dentro de la casa.
- **Pista del zapato:** la pista estaba construida con tres cajas CSG y un volumen de colisión cúbico grande, lo que podía verse como el cubo reportado. Ahora instancia una escena de zapato infantil de cuero estilizado y su volumen de interacción se centra sobre el objeto.
- **Screamer:** se reemplazó el provisional por `Scream.wav`, dentro de `Downloads/Horror SFX Free.zip`, con menor volumen para que el ataque sea menos estridente. El ZIP no contiene licencia ni atribución; por ello el audio queda pendiente de verificación de derechos y no debe incluirse en una publicación comercial hasta confirmar sus términos.
- **Exportación:** el preset ahora incluye formatos de recursos adicionales (`.glb`, `.fbx`, `.obj`, `.ttf`, `.res`) que podían quedar fuera si se cargaban en tiempo de ejecución. El ejecutable 0.1.0 era anterior a estos cambios; se generó una compilación 0.1.1 y se comprobó que empaqueta los recursos clave.

## Cordura

No se modificaron las variables, tasas, reglas ni comportamiento del sistema de cordura.

## Verificación

- Importación de recursos con Godot 4.7.2: completada.
- Campo, casa principal, bosque y laberinto: ejecutados en modo headless sin errores de carga.
- Exportación Windows 0.1.1: completada; el registro confirma el empaquetado de la escena del bosque, la escena del zapato, el modelo de pasto y el nuevo WAV.
- Ejecutable independiente: inicia en modo headless. El smoke test corto registra recursos en uso al terminar; no reporta assets faltantes, pero no sustituye un recorrido visual prolongado.
- Manifiesto y SHA-256: `dist/MANIFIESTO_BETA_0.1.1.txt`.

La licencia del audio del ZIP fuente no se pudo establecer; mantenerlo en la beta interna hasta confirmarla.