# Voces de narración

El proyecto usa un generador local para crear archivos de voz y luego importarlos como audio en Godot. La clave de ElevenLabs nunca debe guardarse en `project.godot`, scripts, archivos de configuración ni en el juego exportado.

## Preparación segura (PowerShell)

1. Revoca cualquier clave que se haya pegado en chats o documentos compartidos y crea una nueva con permisos mínimos de Text to Speech y lectura de voces.
2. Abre una terminal de PowerShell en la carpeta del juego y guarda la clave nueva únicamente durante esa sesión:

```powershell
$env:ELEVENLABS_API_KEY = 'TU_CLAVE_NUEVA'
```

3. Lista las voces disponibles:

```powershell
python tools/elevenlabs_voice.py voices
```

4. Genera una línea usando el ID de una voz que tengas derecho a usar:

```powershell
python tools/elevenlabs_voice.py generate --voice-id ID_DE_VOZ --text-file docs/narration/inspector_intro.txt --out audio/voices/inspector_intro.mp3
```

La salida predeterminada es MP3 44.1 kHz/128 kbps y el modelo `eleven_multilingual_v2`. Se pueden ajustar `--model`, `--output-format`, `--stability`, `--similarity` y `--style`. No está integrado al cliente: el audio se genera desde la terminal y después se importa al proyecto. Así la clave no se distribuye con el juego.

## Voces sugeridas

- **Inspector / narrador:** voz masculina adulta en español latino, grave-media, cansada, cercana al micrófono, contenida y cada vez más fracturada. Entrega pausada; preservar inteligibilidad. Evitar el tono de tráiler épico.
- **Recuerdos o registros:** voz adulta neutra, lejana y ligeramente fatigada. Mantener naturalidad; aplicar el filtro de radio dentro del motor de audio si el diseño final lo requiere.
- **Grapper:** evitar darle diálogo claro. El perseguidor funciona mejor como presencia física, ruido respiratorio y señal de distancia.

Usar una voz disponible de la cuenta o una voz creada con permiso explícito de su titular. Para seleccionar IDs, compara muestras desde tu cuenta. El texto de `inspector_intro.txt` es solo una propuesta inicial de prueba; sustituirlo por la narración final del autor antes de integrar las líneas en las escenas.

## API consultada

- [Autenticación oficial](https://elevenlabs.io/docs/api-reference/authentication): enviar la clave en el encabezado `xi-api-key`; mantenerla en secreto.
- [Crear voz hablada](https://elevenlabs.io/docs/api-reference/text-to-speech/convert): `POST /v1/text-to-speech/{voice_id}`, con `text`, `model_id` y formato de salida.
- [Listar voces](https://elevenlabs.io/docs/api-reference/voices/search): permite obtener los IDs disponibles para la cuenta.
