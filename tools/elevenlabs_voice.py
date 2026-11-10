#!/usr/bin/env python3
"""Generate project narration with ElevenLabs without storing its API key.

Usage (PowerShell):
  $env:ELEVENLABS_API_KEY = 'paste-new-key-here'
  python tools/elevenlabs_voice.py voices
  python tools/elevenlabs_voice.py generate --voice-id VOICE_ID --text-file docs/narration/inspector_intro.txt --out audio/voices/inspector_intro.mp3

The key is read only from the process environment and is never printed or written.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


API_ROOT = "https://api.elevenlabs.io/v1"
DEFAULT_MODEL = "eleven_multilingual_v2"
DEFAULT_FORMAT = "mp3_44100_128"


def api_request(path: str, *, method: str = "GET", body: dict | None = None, audio: bool = False):
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        raise RuntimeError("Falta ELEVENLABS_API_KEY. Configura una clave nueva en esta terminal.")
    headers = {"xi-api-key": key, "Accept": "audio/mpeg" if audio else "application/json"}
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(API_ROOT + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=90) as response:
            return response.read(), response.headers.get("Content-Type", "")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:1200]
        raise RuntimeError(f"ElevenLabs respondió HTTP {exc.code}: {detail}") from None
    except urllib.error.URLError as exc:
        raise RuntimeError(f"No se pudo conectar con ElevenLabs: {exc.reason}") from None


def list_voices(_args: argparse.Namespace) -> int:
    payload, _ = api_request("/voices")
    data = json.loads(payload)
    for voice in data.get("voices", []):
        labels = voice.get("labels") or {}
        language = labels.get("language", "")
        accent = labels.get("accent", "")
        print(f"{voice.get('voice_id', '')}\t{voice.get('name', 'Sin nombre')}\t{language} {accent}".rstrip())
    return 0


def generate(args: argparse.Namespace) -> int:
    text = args.text if args.text is not None else Path(args.text_file).read_text(encoding="utf-8").strip()
    if not text:
        raise RuntimeError("El texto de narración está vacío.")
    if not args.voice_id:
        raise RuntimeError("Indica --voice-id con una voz que tengas permiso para usar.")
    query = urllib.parse.urlencode({"output_format": args.output_format})
    settings = {
        "stability": args.stability,
        "similarity_boost": args.similarity,
        "style": args.style,
        "use_speaker_boost": not args.no_speaker_boost,
    }
    body = {
        "text": text,
        "model_id": args.model,
        "voice_settings": settings,
    }
    payload, content_type = api_request(
        f"/text-to-speech/{urllib.parse.quote(args.voice_id, safe='')}?{query}",
        method="POST", body=body, audio=True,
    )
    if not content_type.startswith("audio/") or not payload:
        raise RuntimeError("La API no devolvió un archivo de audio válido.")
    destination = Path(args.out)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(payload)
    print(f"Audio guardado: {destination} ({len(payload)} bytes)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Voces de narración del videojuego con ElevenLabs")
    commands = parser.add_subparsers(dest="command", required=True)
    voices = commands.add_parser("voices", help="listar las voces disponibles en la cuenta")
    voices.set_defaults(handler=list_voices)
    tts = commands.add_parser("generate", help="sintetizar una línea de narración")
    tts.add_argument("--voice-id", required=True)
    source = tts.add_mutually_exclusive_group(required=True)
    source.add_argument("--text")
    source.add_argument("--text-file")
    tts.add_argument("--out", required=True)
    tts.add_argument("--model", default=DEFAULT_MODEL)
    tts.add_argument("--output-format", default=DEFAULT_FORMAT)
    tts.add_argument("--stability", type=float, default=0.42)
    tts.add_argument("--similarity", type=float, default=0.78)
    tts.add_argument("--style", type=float, default=0.18)
    tts.add_argument("--no-speaker-boost", action="store_true")
    tts.set_defaults(handler=generate)
    args = parser.parse_args()
    try:
        return args.handler(args)
    except (OSError, ValueError, RuntimeError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
