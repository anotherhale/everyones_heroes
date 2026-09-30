"""EH local TTS sidecar for HS.12.7 provider spike.

Complete-file synthetic narration only. No streaming. No voice cloning /
VoiceProfile / reference-audio enrollment.

Backends:
  fake     — deterministic tiny WAV (CI / smoke)
  qwen3    — Qwen3-TTS CustomVoice synthetic speakers
  cosyvoice — Fun-CosyVoice3 synthetic path (stock prompt; not Hero cloning)

Environment:
  EH_LOCAL_TTS_BACKEND=fake|qwen3|cosyvoice
  EH_LOCAL_TTS_HOST=127.0.0.1
  EH_LOCAL_TTS_PORT=8791
  EH_QWEN3_TTS_MODEL=Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice
  EH_QWEN3_TTS_SPEAKER=Ryan
  EH_QWEN3_TTS_DEVICE=cpu
  EH_COSYVOICE_MODEL_DIR=... (optional local weights dir)
  EH_COSYVOICE_PROMPT_WAV=... (stock prompt wav for synthetic path)
"""

from __future__ import annotations

import base64
import io
import json
import os
import struct
import time
import traceback
import wave
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib.parse import urlparse


BACKEND = os.environ.get("EH_LOCAL_TTS_BACKEND", "fake").strip().lower()
HOST = os.environ.get("EH_LOCAL_TTS_HOST", "127.0.0.1").strip() or "127.0.0.1"
PORT = int(os.environ.get("EH_LOCAL_TTS_PORT", "8791"))
QWEN_MODEL = os.environ.get(
    "EH_QWEN3_TTS_MODEL", "Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice"
).strip()
QWEN_SPEAKER = os.environ.get("EH_QWEN3_TTS_SPEAKER", "Ryan").strip() or "Ryan"
QWEN_DEVICE = os.environ.get("EH_QWEN3_TTS_DEVICE", "cpu").strip() or "cpu"
COSY_MODEL_DIR = os.environ.get("EH_COSYVOICE_MODEL_DIR", "").strip()
COSY_PROMPT_WAV = os.environ.get("EH_COSYVOICE_PROMPT_WAV", "").strip()

_MODEL = None
_MODEL_LOAD_SECONDS: float | None = None
_LOAD_ERROR: str | None = None


def _pcm16_mono_wav(samples: list[int], sample_rate: int = 24000) -> bytes:
    buf = io.BytesIO()
    with wave.open(buf, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        frames = b"".join(struct.pack("<h", max(-32767, min(32767, s))) for s in samples)
        wf.writeframes(frames)
    return buf.getvalue()


def _fake_synthesize(text: str, language: str) -> dict[str, Any]:
    # Deterministic short tone burst sized by text length (not musical quality).
    sample_rate = 24000
    duration_s = min(8.0, 0.35 + len(text) / 180.0)
    n = int(sample_rate * duration_s)
    samples = []
    for i in range(n):
        # Simple square-ish beep pattern encoded from text hash.
        seed = (ord(text[i % len(text)]) if text else 1) + i
        samples.append(1200 if (seed % 40) < 20 else -1200)
    audio = _pcm16_mono_wav(samples, sample_rate)
    return {
        "audioBase64": base64.b64encode(audio).decode("ascii"),
        "contentType": "audio/wav",
        "modelLabel": "fake-tts",
        "sampleRate": sample_rate,
        "speaker": "fake",
        "language": language,
        "backend": "fake",
    }


def _bcp47_to_qwen_language(language: str) -> str:
    primary = (language or "en").split("-", 1)[0].lower()
    mapping = {
        "en": "English",
        "es": "Spanish",
        "fr": "French",
        "de": "German",
        "zh": "Chinese",
        "ja": "Japanese",
        "ko": "Korean",
        "ru": "Russian",
        "pt": "Portuguese",
        "it": "Italian",
    }
    return mapping.get(primary, "English")


def _ensure_qwen_model() -> Any:
    global _MODEL, _MODEL_LOAD_SECONDS, _LOAD_ERROR
    if _MODEL is not None:
        return _MODEL
    if _LOAD_ERROR is not None:
        raise RuntimeError(_LOAD_ERROR)
    started = time.perf_counter()
    try:
        import torch
        from qwen_tts import Qwen3TTSModel

        dtype = torch.float32 if QWEN_DEVICE == "cpu" else torch.bfloat16
        _MODEL = Qwen3TTSModel.from_pretrained(
            QWEN_MODEL,
            device_map=QWEN_DEVICE,
            dtype=dtype,
        )
        _MODEL_LOAD_SECONDS = time.perf_counter() - started
        return _MODEL
    except Exception as exc:  # noqa: BLE001 - surface as sidecar error
        _LOAD_ERROR = f"Qwen3-TTS model load failed: {exc}"
        raise RuntimeError(_LOAD_ERROR) from exc


def _qwen_synthesize(text: str, language: str, model_hint: str | None) -> dict[str, Any]:
    import numpy as np
    import soundfile as sf

    model = _ensure_qwen_model()
    qwen_lang = _bcp47_to_qwen_language(language)
    speaker = QWEN_SPEAKER
    # Motivational delivery via instruct when the CustomVoice checkpoint supports it.
    instruct = "Speak in a warm, steady, motivational tone."
    wavs, sr = model.generate_custom_voice(
        text=text,
        language=qwen_lang,
        speaker=speaker,
        instruct=instruct,
    )
    wav = np.asarray(wavs[0])
    buf = io.BytesIO()
    sf.write(buf, wav, int(sr), format="WAV")
    audio = buf.getvalue()
    return {
        "audioBase64": base64.b64encode(audio).decode("ascii"),
        "contentType": "audio/wav",
        "modelLabel": model_hint or QWEN_MODEL,
        "sampleRate": int(sr),
        "speaker": speaker,
        "language": language,
        "backend": "qwen3",
        "modelLoadSeconds": _MODEL_LOAD_SECONDS,
    }


def _ensure_cosyvoice_model() -> Any:
    global _MODEL, _MODEL_LOAD_SECONDS, _LOAD_ERROR
    if _MODEL is not None:
        return _MODEL
    if _LOAD_ERROR is not None:
        raise RuntimeError(_LOAD_ERROR)
    if not COSY_MODEL_DIR:
        raise RuntimeError(
            "CosyVoice backend requires EH_COSYVOICE_MODEL_DIR pointing at "
            "downloaded Fun-CosyVoice3 weights."
        )
    if not COSY_PROMPT_WAV or not os.path.isfile(COSY_PROMPT_WAV):
        raise RuntimeError(
            "CosyVoice synthetic path requires EH_COSYVOICE_PROMPT_WAV "
            "(stock prompt wav — not Hero voice enrollment)."
        )
    started = time.perf_counter()
    try:
        # Official CosyVoice import path; may fail on missing CUDA / deps.
        from cosyvoice.cli.cosyvoice import AutoModel  # type: ignore

        _MODEL = AutoModel(model_dir=COSY_MODEL_DIR)
        _MODEL_LOAD_SECONDS = time.perf_counter() - started
        return _MODEL
    except Exception as exc:  # noqa: BLE001
        _LOAD_ERROR = f"CosyVoice model load failed: {exc}"
        raise RuntimeError(_LOAD_ERROR) from exc


def _cosyvoice_synthesize(text: str, language: str, model_hint: str | None) -> dict[str, Any]:
    import numpy as np
    import soundfile as sf
    import torchaudio

    model = _ensure_cosyvoice_model()
    prompt_speech_16k, sr = torchaudio.load(COSY_PROMPT_WAV)
    if sr != 16000:
        prompt_speech_16k = torchaudio.functional.resample(prompt_speech_16k, sr, 16000)

    # Zero-shot with a stock prompt = synthetic system voice, NOT VoiceProfile cloning.
    chunks = []
    for result in model.inference_zero_shot(
        text,
        "",  # empty prompt text → cross-lingual / zero-shot style path
        prompt_speech_16k,
        stream=False,
    ):
        chunks.append(result["tts_speech"])
    if not chunks:
        raise RuntimeError("CosyVoice returned no audio chunks.")
    wav = chunks[0].squeeze().cpu().numpy()
    out_sr = 24000
    buf = io.BytesIO()
    sf.write(buf, wav, out_sr, format="WAV")
    audio = buf.getvalue()
    return {
        "audioBase64": base64.b64encode(audio).decode("ascii"),
        "contentType": "audio/wav",
        "modelLabel": model_hint or COSY_MODEL_DIR or "Fun-CosyVoice3-0.5B",
        "sampleRate": out_sr,
        "speaker": "stock_prompt",
        "language": language,
        "backend": "cosyvoice",
        "modelLoadSeconds": _MODEL_LOAD_SECONDS,
    }


def synthesize(payload: dict[str, Any]) -> dict[str, Any]:
    text = str(payload.get("text") or "").strip()
    if not text:
        raise ValueError("text is required")
    language = str(payload.get("language") or "en").strip().lower() or "en"
    model_hint = str(payload.get("modelHint") or "").strip() or None
    requested = str(payload.get("provider") or BACKEND).strip().lower() or BACKEND

    backend = requested if requested in {"fake", "qwen3", "cosyvoice"} else BACKEND
    # If the HTTP caller asks for a backend different from process default,
    # honor it when that backend is loadable; otherwise fail closed.
    if backend == "fake":
        return _fake_synthesize(text, language)
    if backend == "qwen3":
        return _qwen_synthesize(text, language, model_hint)
    if backend == "cosyvoice":
        return _cosyvoice_synthesize(text, language, model_hint)
    raise ValueError(f"Unsupported backend: {backend}")


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt: str, *args: Any) -> None:  # noqa: A003
        # Keep sidecar logs short; avoid dumping audio.
        print(f"[tts_sidecar] {self.address_string()} {fmt % args}")

    def _send(self, status: int, body: dict[str, Any]) -> None:
        raw = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path in {"/health", "/"}:
            self._send(
                200,
                {
                    "status": "ok",
                    "backend": BACKEND,
                    "modelLoaded": _MODEL is not None,
                    "modelLoadSeconds": _MODEL_LOAD_SECONDS,
                    "loadError": _LOAD_ERROR,
                },
            )
            return
        self._send(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path != "/synthesize":
            self._send(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length", "0"))
        raw = self.rfile.read(length) if length > 0 else b"{}"
        try:
            payload = json.loads(raw.decode("utf-8"))
            if not isinstance(payload, dict):
                raise ValueError("JSON body must be an object")
            started = time.perf_counter()
            result = synthesize(payload)
            result["synthesisSeconds"] = time.perf_counter() - started
            self._send(200, result)
        except Exception as exc:  # noqa: BLE001 - map to EH-friendly error
            # Do not return Python tracebacks to callers.
            print(f"[tts_sidecar] synthesize error: {exc}")
            print(traceback.format_exc())
            self._send(502, {"error": str(exc)})


def main() -> None:
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(
        f"EH local TTS sidecar listening on http://{HOST}:{PORT} "
        f"(backend={BACKEND})"
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
