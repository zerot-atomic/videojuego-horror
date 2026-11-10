# Guía interna del laberinto

El laberinto ahora se genera como un árbol de celdas conectadas: hay ramales sin salida, pero una sola ruta correcta entre la entrada sur y la salida norte. El tamaño y la disposición son deterministas por dificultad para que esta guía coincida con el juego.

## Solución por dificultad

Empieza en la entrada sur mirando hacia el norte. Cada instrucción es **giro y avance**: `I3` significa girar a la izquierda y avanzar tres celdas; `D2`, girar a la derecha y avanzar dos. Dos giros iguales seguidos incluyen un tramo de avance entre ellos. La salida está al norte. No se muestran estas rutas dentro del juego.

| Dificultad | Cuadrícula | Recorrido de solución |
|---|---:|---|
| Historia | 7 × 7 | I3 → D6 → D3 |
| Normal | 9 × 9 | I2 → D1 → D1 → I1 → D1 → I1 → D1 → I1 → D1 → I1 → D1 → I1 → D1 → I2 → I4 |
| Difícil | 11 × 11 | I5 → D3 → D1 → I1 → D1 → I2 → D1 → I1 → D1 → I1 → D2 → I1 → D1 → I1 → I2 |
| Lovecraft | 13 × 13 | I1 → D1 → D1 → I1 → D1 → I1 → D1 → I1 → D1 → I1 → D1 → I1 → D1 → I1 → D1 → I5 → I6 |

`I` = izquierda; `D` = derecha. Norte apunta hacia el campo de cultivo y sur hacia el bosque. La dificultad aumenta el número de celdas y ramales, no cambia los multiplicadores de cordura.

## Perseguidor y screamer

Cuando el Grapper alcanza al jugador en el laberinto, reproduce el screamer con `audio/scream_distorted.wav`, aplica el daño de cordura ya configurado y, tras el susto, reaparece a unos 6,5 m detrás del jugador. El punto de reaparición se comprueba contra la colisión del laberinto y se ajusta hacia un corredor cercano si hace falta; si no hay un punto libre inmediato, conserva su posición segura actual. Después retoma la persecución. En Historia la velocidad del jugador en el laberinto tiene un aumento leve del 12 %.

## Controles

WASD, el stick izquierdo y el joystick táctil usan el mismo movimiento direccional relativo a la cámara; las diagonales se normalizan y el inspector gira hacia donde avanza. El stick táctil ocupa la zona inferior izquierda. El diario incluye un botón visible **Cerrar**, también en móvil.
