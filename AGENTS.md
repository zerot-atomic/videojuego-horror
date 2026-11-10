# Reglas obligatorias para cambios del juego

Antes de modificar escenas, cámara, jugador, empaquetado o controles, lee [`docs/LECCIONES_Y_VALIDACION.md`](docs/LECCIONES_Y_VALIDACION.md).

## Descubrimiento del código

Este proyecto usa `codebase-memory-mcp`. Prefiere `search_graph`, `trace_path`, `get_code_snippet`, `query_graph` y `search_code`, en ese orden, para descubrir código. Usa búsqueda de archivos como `rg` cuando el índice no esté disponible o sea insuficiente, y para literales, configuraciones y recursos no-code.

- No cambies la cámara, su jerarquía, altura, distancia, seguimiento ni encuadre salvo que el usuario lo pida explícitamente.
- No cambies la posición del cuerpo, la cápsula, la escala ni el offset del modelo para compensar un problema de cámara. Primero reproduce y mide el estado en la escena real.
- No consideres suficiente que el editor importe el proyecto o que un export termine: carga la escena jugable directamente y comprueba errores de script y transforms.
- No entregues una beta si no verificaste en ejecución el inicio, la vista del jugador y el movimiento básico. Si el escritorio no permite inspección visual, documenta el bloqueo y no afirmes que la presentación quedó validada.
- Mantén el mismo número de versión cuando el usuario define una hotfix (por ejemplo 0.1.7b). No inventes sufijos o subversiones para encubrir una entrega que no está validada.
- Al balancear movimiento o persecuciones, mide el tiempo de ruta por dificultad, la velocidad efectiva del jugador y los márgenes de alcance/reinicio del perseguidor. No declares una dificultad finalizable basándote solo en que los scripts compilan.
- Trata como límites de diseño la cámara original, el spawn/cápsula sobre el suelo y la cordura ya aprobada. Solo se modifican con instrucción explícita del usuario.

## Cómo ejecutar Godot

Godot 4.7.2 NO está instalado ni en el PATH. Es solo un .exe en la carpeta raíz del proyecto, junto a project.godot. Nunca ejecutes `godot` a secas. Localízalo con `Get-ChildItem -Filter 'Godot*.exe'` y usa la variante con '_console' si existe (imprime en la terminal; la otra puede no mostrar salida y requiere --log-file docs/godot.log).

Plantilla PowerShell:
```powershell
$GODOT = (Get-ChildItem -Filter 'Godot*console*.exe' | Select-Object -First 1).FullName
if (-not $GODOT) { $GODOT = (Get-ChildItem -Filter 'Godot*.exe' | Select-Object -First 1).FullName }
& $GODOT --headless --path . --quit-after 120 2>&1 | Select-String 'ERROR|WARNING'
```

Comprobar un script:
```powershell
& $GODOT --headless --path . --check-only --script res://RUTA.gd
```

Probar una escena:
```powershell
& $GODOT --headless --path . res://scenes3d/X.tscn --quit-after 120
```

En worktrees el .exe no está (no se versiona): usa la ruta ABSOLUTA del exe de la carpeta original.

Si tu entorno no puede ejecutar un .exe de Windows, NO inventes resultados: deja scripts .ps1/.bat en tools/qa/ para que el usuario los ejecute y pegue la salida, y marca todo como "No verificado ejecutando". El .exe no se versiona, ni se mueve, ni se borra.

## Regla de versionado y documentación

Tras cada cambio, actualiza versión (project.godot), CHANGELOG.md y la documentación afectada.