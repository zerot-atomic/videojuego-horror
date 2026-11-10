# Revisión de Grapper y dificultad del laberinto

**Fecha:** 27 de octubre de 2026  
**Alcance:** lectura del comportamiento, ajuste de dificultad y comprobación headless de la zona del laberinto. No equivale a una pasada visual completa ni a una prueba manual de principio a fin.

## Hallazgos previos

- La zona ya iniciaba a Grapper con `start_chase(jugador, true, true)`: la persecución está forzada, sigue la posición actual del jugador y no cae al estado de búsqueda por perder línea de visión.
- El laberinto, sin embargo, usaba la misma distribución en todas las dificultades: siete tabiques transversales con pasos alternos.
- La velocidad base configurada por dificultad era 4.80 m/s en Historia, 6.15 en Normal, 6.52 en Difícil y 6.77 en Lovecraft; el jugador corre a 6.0 m/s. Por tanto, la diferencia de persecución entre Normal y Lovecraft era pequeña.
- Grapper conserva pausas breves al atacar y al tropezar contra obstáculos. Estas ventanas impiden que el contacto sea una captura automática, pero necesitan calibración visual para confirmar que no se repiten de forma injusta.

## Cambios hechos en el proyecto

- El laberinto cambia ahora con la dificultad: Historia tiene cinco tabiques y huecos más amplios; Normal conserva siete; Difícil usa nueve con pasos más angostos; Lovecraft usa once y los pasos más angostos.
- La velocidad base del perseguidor sube a 6.89 m/s en Difícil y 7.50 m/s en Lovecraft.
- Durante la persecución, Grapper acelera gradualmente si el jugador le saca distancia y reduce el paso cuando se acerca mucho. No se teletransporta y mantiene una velocidad de aproximación inferior a la carrera del jugador en corto alcance.

## Comprobación técnica

- Godot 4.7.2 cargó la zona del laberinto con cada uno de los cuatro perfiles.
- En los cuatro casos Grapper alcanzó el estado `CHASING` y el cálculo A* produjo una ruta: 12 celdas en Historia, 12 en Normal, 24 en Difícil y 45 en Lovecraft durante la muestra headless.
- Esta ejecución valida carga, estados y existencia de ruta; no mide el tiempo real de escape ni sustituye probar el control con teclado, cámara, animación y sonido.
- El cierre inmediato de la ejecución headless puede reportar recursos OGG en uso; es un efecto de terminación de la prueba y no se usó como criterio de éxito de la IA.

## Estado de revisión de escenas

La revisión anterior cargó las escenas del proyecto y del paquete para comprobar errores estructurales. **No se había completado una inspección visual y jugable individual de cada escena.** En esta revisión se trabajó específicamente el sistema del laberinto/Grapper. Camino, bosque, campo, establo, casa, ático, cráter, pozo, finales, menús y transiciones aún requieren recorrido visual manual antes de declarar cerrada la revisión integral.

Los cambios de esta nota están en los archivos fuente. El ejecutable `0.1.0` exportado anteriormente no incluye estos cambios y debe volver a exportarse con un número de build nuevo antes de distribuirlos a testers.

## Corrección de aparición — 28 de octubre de 2026

La revisión del reporte de que no se veía al Grapper encontró la causa: la instancia se colocaba en `(0, 0, 0)`, coincidente con un tabique transversal del laberinto en `z=0`. Aunque la persecución entraba al estado `CHASING` y A* calculaba una ruta, la colisión podía dejarlo atascado desde el comienzo. Se movió al primer corredor, alineado con el hueco de entrada y a unos pasos detrás del inspector. La posición cambia según la llegada desde bosque o patio; se mantiene `start_chase(..., true, true)` y el screamer inicial.

La ruta headless previa no detectaba que el punto de inicio estuviera dentro de un muro. Esta corrección necesita una prueba visual en partida normal; hasta hacerla, se considera resuelta la colocación en código pero no cerrada la validación jugable.
