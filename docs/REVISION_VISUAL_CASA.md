# Revisión visual de la casa y su entrada

Fecha: 27 de octubre de 2026

## Hallazgos y correcciones

1. **Piedra delante de la puerta exterior.** `RoomSetDressing._dress_road()` instanciaba una roca en `(5.5, 0, -2.0)`, prácticamente centrada sobre la puerta/área de acceso de la casa. Era un modelo decorativo sin colisión. Se quitó de la entrada.
2. **Vegetación en la entrada.** El reparto aleatorio de arbustos y pasto no tenía en cuenta la puerta situada en `x=5.656, z=-0.581`. Se añadió un margen libre de 3 m alrededor de ese acceso.
3. **Decoración interior duplicada y sin textura.** `_dress_house()` añadía una segunda sala, cajas de color plano y muebles ubicados al otro lado de los tabiques. Se retiraron esas piezas. Se conserva la decoración fija organizada por zonas: recibidor al suroeste, sala al noroeste, comedor/cocina al noreste y despensa al este.
4. **Recibidor demasiado vacío.** Se añadió una consola de madera con colisión y un cuadro texturizado contra el muro sur, sin invadir la ruta central desde la entrada hacia la sala.
5. **Atlas de texturas de la cocina ausente.** Los GLB de PSX Horror Farm Kit apuntaban a `../textures/atlas.png`, pero se había copiado el modelo sin su carpeta compañera. Se restauró `atlas.png` y el resto de PNG del paquete en `art3d/extras/textures/`, donde resuelven esas referencias relativas.

## Recursos

La escena usa los modelos y texturas ya importados en `art3d/psx_house_pack/props` y `art3d/props_extra/house`. El paquete PSX Horror Farm Kit Free está conservado en `art3d/extras/PSX_Horror_Farm` junto con su licencia y README; sus texturas están en `art3d/extras/textures/`.

## Comprobación

Godot 4.7.2 reimportó los seis modelos GLB que usan el atlas y cargó `Room_camino_entrada.tscn` y `Room_casa_principal.tscn` en modo headless sin errores. La partida que ya estaba abierta conserva los nodos cargados antes de la edición; hay que reiniciarla para verlos en esa instancia.

## Segunda pasada: patio, pasto y establo

Fecha: 28 de octubre de 2026

- **Pasto encontrado.** Se identificó `art3d/classic64_pack/Ground/Materials/grass_01.png`. Se aplicó como base texturizada del piso del campo y se conservó la hierba procedural por encima. También se acotó el pasto, las flores y los cultivos al tamaño transitable del patio para que no aparezcan fuera del suelo ni atraviesen el establo.
- **Referencia visual encontrada.** La foto de la habitación principal está en `C:/Users/CFMH1/OneDrive/Escritorio/recursos videjuego/ChatGPT Image 18 sept 2026, 20_40_50.png`; muestra una sala organizada con retratos, ventana, escritorio, librero/radio, baúl y chimenea. La referencia del establo está en `ChatGPT Image 19 sept 2026, 16_44_31.png`. La decoración existente de la casa se conserva; esta pasada se concentró en el patio y el establo.
- **Granero ubicado en el patio de la cosecha.** Se sustituyó el frente de pared y puerta superpuestos por el edificio exterior completo `GraneroPatio`, con muros, base, techo, interior oscuro, portones corredizos de madera y colisión. El candado y la salida bloqueada hacia `establo` siguen asociados a la llave oxidada. El granero de la entrada queda cerrado como elemento de fondo.
- **Interior del establo.** Se conservaron las zonas de heno, alimento y pesebre existentes. La construcción exterior ahora permite leer el lugar como un establo y relacionarlo con la puerta que conecta al interior jugable.
- **Cráter.** Se retiraron los nueve prismas morados rectangulares que parecían cuadritos sueltos. Se mantienen el meteorito y la piedra/vegetación ya presentes en la escena.
- **Grapper en el laberinto.** Se encontró que nacía en `(0, 0, 0)`, justo dentro del tabique transversal de `z=0`. Ahora inicia en el primer corredor, alineado con la abertura de entrada y a unos pasos detrás del jugador: `(−18, 0, 22)` desde el bosque o `(−18, 0, −22)` desde el patio. La persecución forzada y el screamer existentes se conservan.

## Verificación de esta pasada

Godot 4.7.2 cargó en modo headless las zonas de campo, camino, laberinto y cráter con código de salida 0 y sin errores de parser/recurso. Tres de los procesos cerrados inmediatamente imprimieron avisos de `ObjectDB instances were leaked`/recursos aún en uso; ese patrón de cierre abrupto ya está registrado en el acta beta y no demuestra por sí solo un fallo durante una salida normal. Falta inspeccionar visualmente las escenas en una partida reiniciada. Tampoco se da por verificada la persecución jugable hasta verla alcanzar al inspector dentro del laberinto en una ejecución normal.
