# Revisión asistida 0.1.8B: movimiento y dificultad

## Objetivo

Recuperar un control fluido y dejar el laberinto Difícil/Lovecraft desafiante pero terminable. Se preservan la cámara, el origen y cápsula del inspector, y los valores/modelo de cordura. Esta revisión corrige la relación de velocidad de la persecución y el reinicio del Grapper.

## Cambios

- El jugador alcanza la velocidad de sprint del laberinto en aproximadamente 0.1 s, con desaceleración breve al soltar el control y giro corporal más receptivo. El vector sigue usando el yaw guardado al iniciar cada impulso; no se ha cambiado el seguimiento ni el encuadre de la cámara.
- Multiplicadores de sprint dentro del laberinto: Historia 1.12, Normal 1.08, Difícil 1.22, Lovecraft 1.30. Con velocidad base 6 m/s, el máximo efectivo es 6.72, 6.48, 7.32 y 7.80 m/s respectivamente.
- El Grapper calcula su presión en relación con la velocidad efectiva del jugador y la dificultad. En Difícil/Lovecraft su ventaja a distancia se limita a la velocidad que ya tiene configurada por dificultad; cerca del jugador reduce el margen y lo puede alcanzar al final de una ruta limpia.
- Tras el screamer, el Grapper se coloca en una celda libre a 6–7 pasos conectados del jugador. En extremos del mapa acepta 5 u 8 pasos. La distancia se obtiene del grafo real del laberinto; no atraviesa paredes ni aparece fuera de la cuadrícula.
- Corregí las apariciones del laberinto: quien llega desde el bosque aparece junto a la abertura norte y quien llega desde el campo junto a la abertura sur. La ruta impresa ahora parte del acceso del bosque y termina en la salida al campo; las dos puertas y los marcadores de spawn coinciden.
- Sin cambios a `GameManager` ni a la pérdida de cordura/daño del ataque.

## Medición de ruta

Se cargó `Room_laberinto.tscn` por separado con Godot 4.7.2 en las cuatro dificultades. La ruta medida es la ruta mínima BFS desde el acceso del bosque hasta la salida del campo. El tiempo es longitud de esa ruta dividida entre sprint efectivo, sin contar giros, tropiezos ni persecución.

| Dificultad | Cuadrícula | Pasos mínimos | Longitud | Sprint efectivo | Tiempo mínimo estimado |
|---|---:|---:|---:|---:|---:|
| Historia | 7×7 | 12 | 102.86 m | 6.72 m/s | 15.31 s |
| Normal | 9×9 | 20 | 133.33 m | 6.48 m/s | 20.58 s |
| Difícil | 11×11 | 24 | 130.91 m | 7.32 m/s | 17.88 s |
| Lovecraft | 13×13 | 26 | 120.00 m | 7.80 m/s | 15.38 s |

El tiempo de tabla es un límite ideal. Además, ejecuté un recorrido asistido con el `Player3D` físico, las paredes reales, el Grapper activo y la ruta BFS. Para medir la posibilidad de salida sin pausar el juego, el asistente orientó al personaje hacia cada siguiente centro de celda; el desplazamiento, la colisión, los ataques y los reinicios sí corrieron en tiempo de juego.

| Dificultad | Recorrido | Alcances de Grapper | Cordura al salir | Game over |
|---|---:|---:|---:|---|
| Difícil | 24/24 pasos y salida alcanzada a 0.48 m | 2 | 53.25% | No |
| Lovecraft | 26/26 pasos y salida alcanzada a 0.52 m | 1 | 67.15% | No |

La prueba empezó con el contador de corrupción en cero. La pérdida de cordura no se modificó. Por eso hay una condición de entrada que conviene conservar en la documentación: al pasar 30% de corrupción, correr consume 10.8 puntos/s en Difícil y 14.4 puntos/s en Lovecraft. El sprint continuo desde 100% cordura dura como máximo 9.26 s en Difícil y 6.94 s en Lovecraft; una entrada tardía al laberinto reduce mucho el margen. El recorrido de prueba demuestra que ambos modos se pueden completar con el margen de cordura conservado cuando se llega antes de esos umbrales (216 s en Difícil, 180 s en Lovecraft). No afirma que una entrada tardía sea igual de viable.

Ruta desde el bosque hacia el campo (N/S/E/O):

- Historia: `O-O-O-S-S-S-S-S-S-E-E-E`
- Normal: `E-E-E-E-S-S-O-S-O-S-O-S-O-S-O-S-O-S-E-E`
- Difícil: `E-E-S-O-S-O-O-S-O-S-O-S-S-O-S-O-S-S-S-E-E-E-E-E`
- Lovecraft: `E-E-E-E-E-E-S-S-S-S-S-O-S-O-S-O-S-O-S-O-S-O-S-O-S-E`

## Comprobaciones registradas

- Godot 4.7.2: escaneo del proyecto y registro de clases sin errores de parseo.
- Carga del laberinto y de la zona jugable con las cuatro dificultades; BFS confirma rutas conectadas, longitud esperada y marcadores de entrada/salida en lados opuestos.
- Consulta física de reaparición: en las cuatro dificultades y desde ambas entradas el Grapper encontró una celda libre a seis pasos del jugador.
- Recorrido automatizado asistido de los 24 pasos de Difícil y 26 de Lovecraft hasta la salida, con el Grapper y la cordura activos; resultados arriba.
- Respuesta planar codificada con aceleración de 72 m/s² (0–6 m/s en 0.083 s; 0–7.8 m/s en 0.108 s) y giro corporal de 12 rad/s.
- Conservación de cámara/origen/cápsula: solo se editó respuesta planar, velocidad del laberinto, generación de sus muros y lógica de persecución/reaparición.
- Pendiente de recepción: una partida humana completa desde el menú en Difícil y Lovecraft para valorar los giros y el tiempo de reacción, además de instalar y probar el APK en teléfono. El recorrido automatizado comprueba que existe una solución transitable, no sustituye esa evaluación de sensación.

## Rutas de orientación para documentación

La ruta exacta se imprime al iniciar el laberinto como `[Laberinto] <dificultad> ruta de solución (N/S/E/O)`. No mostrar esta ruta al jugador en la beta.
