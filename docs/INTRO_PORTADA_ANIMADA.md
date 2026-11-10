# Portada animada del menú

Fecha: 29 de octubre de 2026

Se integró en el menú principal la imagen `art3d/backgrounds/title_farm_purple.png`, proporcionada para esta intro. El diseño conserva el inspector y el resplandor como centro de atención, con el menú en un panel oscuro a la derecha.

## Animación

- La pantalla parte de negro y revela lentamente la granja.
- La cámara hace un acercamiento suave que oscila con lentitud para mantener viva la composición.
- Un shader da al resplandor un pulso muy leve; otro genera niebla baja con desplazamiento horizontal.
- El título y el lema aparecen antes del panel de opciones.
- La canción existente del menú sigue controlando el ambiente musical.

La animación se compone en tiempo real dentro de Godot a partir de la imagen fija; no depende de un video prerenderizado. Los botones conservan sus acciones originales, incluida la selección de las cuatro dificultades.

## Validación

Godot 4.7.2 importó el PNG y abrió `MainMenu3D.tscn` sin errores de carga de recursos ni de script. La ventana del juego se revisó visualmente: el título no tapa al detective ni el resplandor y el panel queda sobre la zona oscura del establo.
