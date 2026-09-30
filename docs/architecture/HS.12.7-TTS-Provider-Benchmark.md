# HS.12.7 — TTS Provider Benchmark

**Status:** Spike complete (decision point — **no automatic provider selection**)  
**Date:** 2026-09-30  
**Phase:** Voice Synthesis — local/hosted TTS provider experiment  
**Boundary preserved:** `VoiceRenderingPort` → `POST /story-voice-renderings` → EH AI proxy → TTS adapter (HS.12.6 / HS-ADR-077)

---

## 0. Current provider boundary (discovery before changes)

Inspected on `main` after PR #99 (`HS-ADR-077`) merge. Actual wiring before this spike:

```text
Flutter / RenderStoryVoiceUseCase
  → VoiceRenderingPort
  → ProxyVoiceRenderingAdapter | InMemoryVoiceRenderingAdapter
  → POST /story-voice-renderings
  → StoryVoiceRenderingHandler
  → OpenAiSpeechClient (hard-wired)
  → audio/mpeg bytes → StoryVoiceRendering
```

| Artifact | Role |
|----------|------|
| `VoiceRenderingPort` | Provider-neutral domain port (`language` + opaque hints) |
| `StoryVoiceRendering` | Derived presentation VO — not Story identity |
| `RenderStoryVoiceUseCase` | Consent + idempotency + media persistence |
| `ProxyVoiceRenderingAdapter` | Flutter → proxy HTTP only (no vendor SDKs) |
| `InMemoryVoiceRenderingAdapter` | Deterministic Flutter tests |
| `OpenAiSpeechClient` | Proxy-only OpenAI TTS (`tts-1` / `alloy` / mp3, 4096-char limit) |
| HS-ADR-077 | Provider-neutral synthetic narration contract |
| Voice Synthesis plan | Calls for V2 local spike (Qwen3 / CosyVoice) then multi-provider router |

**Architectural rule confirmed:** provider selection belongs in `services/ai_proxy`. No second narration port. No Story representation hierarchy change. No Flutter TTS vendor coupling.

HS.12.7 added an **internal** `TtsProvider` resolver inside the proxy only.

---

## 1. Environment

### Spike execution host (this Cloud Agent)

| Item | Value |
|------|-------|
| OS | Linux 6.12.94+ x86_64 |
| CPUs | 4 |
| RAM | 15 GiB (no swap) |
| GPU | **None** (`nvidia-smi` unavailable) |
| Python | 3.12.3 |
| Dart / Flutter | Dart 3.13.4 / Flutter 3.47.5 (installed for tests) |

> **Important:** This is **not** the Apple M4 Mac mini. M4/16GB conclusions below combine (a) measurements on this CPU Linux host, (b) official docs, and (c) published community Mac reports. Live OpenAI API calls were **not** run here (`OPENAI_API_KEY` absent).

### Target primary machine (product context)

| Item | Value |
|------|-------|
| Hardware | Apple M4 Mac mini, 16 GB unified memory |
| Implication | Prefer ≤0.6B-class local models; CosyVoice ~8 GB worker is tight |

---

## 2. Benchmark corpus

Fixed corpus (identical across providers):

`services/ai_proxy/tool/tts_benchmark/corpus.json`  
Human-readable twin: `services/ai_proxy/tool/tts_benchmark/corpus.md`

| Item ID | Language | Approx target duration | Chars |
|---------|----------|------------------------|-------|
| `english_short` | en | 20–30 s | 259 |
| `english_narrative` | en | 90–120 s | 1215 |
| `multilingual_en` | en | short | 54 |
| `multilingual_es` | es | short | 64 |
| `multilingual_fr` | fr | short | 67 |
| `multilingual_de` | de | short | 69 |

Exact texts are in the corpus files (do not edit between providers).

---

## 3. Providers / models tested

| Provider | Model / path | Result |
|----------|--------------|--------|
| **OpenAI** (baseline) | `tts-1` + voice `alloy` (defaults in `ProxyConfig` / `OpenAiSpeechClient`) | **Preserved + routed** via `OpenAiTtsProvider`. **Live API synthesis not measured** in this environment (no API key). |
| **Qwen3-TTS** | `Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice` (synthetic CustomVoice speakers; **no cloning**) | **Successfully tested** on CPU Linux. WAV artifacts + metrics under `docs/architecture/hs12_7_benchmark_artifacts/qwen3/`. |
| **CosyVoice** | `FunAudioLLM/Fun-CosyVoice3-0.5B-2512` | **Not successfully tested.** Install/runtime spike stopped (CUDA-oriented deps + ~9.75 GB weights). No verified adapter shipped. |
| **fake** (sidecar) | Deterministic tiny WAV | Used to prove proxy ↔ sidecar routing without ML weights. |

---

## 4. Installation requirements

### OpenAI (hosted)

- Already integrated: `OPENAI_API_KEY`, optional `OPENAI_SPEECH_MODEL` / `OPENAI_SPEECH_VOICE`
- Complexity: **low**

### Qwen3-TTS (local)

| Item | Observation |
|------|-------------|
| Python | 3.12 recommended (used 3.12) |
| Package | `qwen-tts==0.1.1` (+ CPU `torch` / `torchaudio`) |
| Install complexity | **Moderate** — isolate venv; pin CPU torch wheels to avoid multi-GB CUDA downloads; `gradio` optional (demo UI only) |
| Model download | ~**2.5 GB** HF tree for 0.6B CustomVoice (weights ~1.81 GB safetensors) |
| Disk (venv + cache) | ~1.6 GB venv + ~2.4 GB HF cache observed on spike host |
| Device | Official happy path CUDA; CPU works with `dtype=float32`; Apple Silicon via MPS/community (not measured here) |

Sidecar: `services/ai_proxy/tts_sidecar/` with `EH_LOCAL_TTS_BACKEND=qwen3`.

### CosyVoice (local) — not completed

| Item | Observation |
|------|-------------|
| Python | **3.10 via conda** (upstream README) |
| Requirements | CUDA/TensorRT oriented (`onnxruntime-gpu`, `tensorrt-cu12*`, `deepspeed`, cu121 torch pins) |
| Model download | **~9.75 GB** (`Fun-CosyVoice3-0.5B-2512`) + optional `CosyVoice-ttsfrd` ~0.35 GB |
| Apple Silicon | Upstream MPS issue open; community forks; one M4/16GB report cites ~**8 GB RAM** worker, RTF ~0.76 |
| Spike decision | **Stop** rather than force unverified CPU install (per milestone stopping rule) |

Probe JSON: `docs/architecture/hs12_7_benchmark_artifacts/cosyvoice/install_probe.json`

---

## 5. Performance measurements

### A. OpenAI (hosted baseline)

| Metric | Recorded value |
|--------|----------------|
| Model configured | `tts-1` (override via `OPENAI_SPEECH_MODEL`) |
| Voice | `alloy` |
| Format | `audio/mpeg` (mp3) |
| Endpoint | `POST {OPENAI_BASE_URL}/audio/speech` |
| Input limit | 4096 characters |
| Live latency / RTF / duration | **NOT MEASURED** — `OPENAI_API_KEY` missing on spike host |
| Integration complexity | Low (existing client wrapped by `OpenAiTtsProvider`) |

**Reproduce on M4 Mac (or any keyed host):**

```bash
cd services/ai_proxy
export OPENAI_API_KEY=...
dart run tool/tts_benchmark/run_benchmark.dart \
  --provider openai \
  --out ../../docs/architecture/hs12_7_benchmark_artifacts
```

### B. Qwen3-TTS 0.6B CustomVoice (CPU Linux — measured)

Cold HF download excluded from the “loaded 2.3s” warm-cache figure; first probe load was ~11 s including download/setup.

| Item | Startup (model load) | Synthesis | Audio duration | RTF | Format | Sample rate | File size | Peak RSS |
|------|----------------------|-----------|----------------|-----|--------|-------------|-----------|----------|
| english_short | 2.3 s (warm) / 11.0 s (first probe) | 59.6 s | 22.48 s | **2.65** | WAV PCM | 24 kHz | 1.08 MB | ~4.7 GB |
| english_narrative | — | 271.2 s | 94.56 s | **2.87** | WAV PCM | 24 kHz | 4.54 MB | ~5.0 GB |
| multilingual_en | — | 10.0 s | 4.00 s | 2.50 | WAV | 24 kHz | 192 KB | ~5.0 GB |
| multilingual_es | — | 15.9 s | 6.24 s | 2.55 | WAV | 24 kHz | 300 KB | ~5.0 GB |
| multilingual_fr | — | 22.1 s | 8.48 s | 2.60 | WAV | 24 kHz | 407 KB | ~5.0 GB |
| multilingual_de | — | 10.7 s | 4.32 s | 2.47 | WAV | 24 kHz | 207 KB | ~5.0 GB |

Raw JSON: `docs/architecture/hs12_7_benchmark_artifacts/qwen3/results.json`  
Audio: `docs/architecture/hs12_7_benchmark_artifacts/qwen3/audio/*.wav`

**CPU utilization:** multi-core busy during synth (process dominated host; no GPU).  
**Stability:** six sequential corpus items completed without crash; RSS stayed ~4.7–5.0 GB after load.

**M4 projection (engineering estimate, not measured):**

- 0.6B CustomVoice fits 16 GB with headroom (community + this ~5 GB RSS CPU float32 run).
- Expect substantially better RTF on MPS than CPU RTF≈2.5–2.9 (likely <1.0 if MPS is healthy — **verify on Mac**).
- Prefer 0.6B over 1.7B on 16 GB.

### C. CosyVoice

| Metric | Record |
|--------|--------|
| All synthesis metrics | **N/A — not successfully run** |
| Error | Install/runtime not completed on CPU-only spike host; CUDA-first stack + 9.75 GB weights |

---

## 6. Audio characteristics

| Provider | Format | Sample rate | Notes |
|----------|--------|-------------|-------|
| OpenAI | mp3 (`audio/mpeg`) | vendor default (typically 24 kHz for TTS mp3) | From existing client |
| Qwen3 | WAV PCM s16le mono | **24000 Hz** | Measured via ffprobe |
| CosyVoice | — | — | Not generated |

---

## 7. Multilingual results

| Language | Qwen3-TTS 0.6B CustomVoice |
|----------|----------------------------|
| English | Succeeded (short + narrative + multilingual line) |
| Spanish | Succeeded |
| French | Succeeded (waveform shows **high silence ratio ~0.78** — possible pacing/quality quirk; needs human listen) |
| German | Succeeded |

OpenAI / CosyVoice multilingual: not live-measured in this spike.

Qwen3 public claim: 10 languages (zh/en/ja/ko/de/fr/ru/pt/es/it). CosyVoice public claim: 9 languages + Chinese dialects.

---

## 8. Stability observations

- **Qwen3:** Stable across full corpus (~6.5 minutes wall synthesis time on CPU). No OOM after load on 15 GB host with ~5 GB available headroom at start.
- **CosyVoice:** Not run.
- **Proxy failure containment:** `TtsProviderException` → HTTP 502 JSON `{"error":"..."}` without Python tracebacks (unit-tested). Unavailable local sidecar → 502. Unknown/`cosyvoice` provider → 502 with explicit message.

---

## 9. Resource consumption

| Provider | Model size (HF tree) | Observed process RSS | Disk notes |
|----------|----------------------|----------------------|------------|
| OpenAI | N/A (hosted) | N/A | Network only |
| Qwen3 0.6B CustomVoice | ~2.5 GB | ~4.7–5.0 GB | + torch CPU wheels |
| Qwen3 1.7B CustomVoice | ~4.5 GB | not loaded | Likely tight on 16 GB |
| CosyVoice 0.5B | ~9.75 GB | not loaded | Community ~8 GB RAM worker on M4 |

---

## 10. Licensing findings

| Artifact | License finding | Commercial use |
|----------|-----------------|----------------|
| OpenAI TTS API | OpenAI commercial ToS / product terms | Permitted under OpenAI terms (existing EH usage) |
| Qwen3-TTS GitHub | Apache-2.0 | Appears permitted under Apache-2.0 |
| `Qwen/Qwen3-TTS-12Hz-0.6B-*` HF cards | `license: apache-2.0` | Appears permitted — **still legal review before production** |
| CosyVoice GitHub | Apache-2.0 | Repo OK |
| `Fun-CosyVoice3-0.5B-2512` HF card | `license: apache-2.0` | Appears permitted — **legal review** |
| `CosyVoice-ttsfrd` HF card | `license: apache-2.0` | Appears permitted — **legal review**; optional (wetext fallback) |
| Companion wheels / third_party | Various (Matcha-TTS submodule, etc.) | **UNKNOWN — REQUIRES LICENSE REVIEW** for production packaging |

Do **not** infer weight licenses from source-repo licenses alone; HF cards were checked for the checkpoints named above.

---

## 11. Provider-specific limitations

### OpenAI

- 4096 character input limit (proxy enforces)
- Hosted cost + data leaves EH hardware
- No VoiceProfile/cloning in EH path (correct for this milestone)

### Qwen3-TTS

- Official path CUDA-first; CPU RTF ≈ 2.5–2.9 (too slow for snappy UX without accelerator)
- Instruction control / speakers depend on CustomVoice vs Base vs VoiceDesign checkpoints
- Future cloning uses **Base** models + reference audio — **not implemented** here (intentionally)
- French sample silence ratio anomaly needs human QA

### CosyVoice

- Heavy CUDA/TensorRT-oriented install
- Large weight download (~10 GB)
- Synthetic narration still tends to need a **prompt wav** for zero-shot paths (stock prompt ≠ Hero VoiceProfile, but operationally awkward)
- Not verified in this spike → **no adapter claimed**

---

## 12. Quality evaluation (experimental observations)

> These are **experimental listening/engineering notes**, not product MOS rankings.

### Qwen3-TTS 0.6B CustomVoice (Ryan + motivational instruct)

| Criterion | Experimental note (1–5) | Comment |
|-----------|-------------------------|---------|
| Naturalness | **3–4** (est.) | Waveforms continuous; CPU samples sound usable for lab — **confirm on headphones** |
| Pronunciation | **3–4** (est.) | Multilingual lines generated without hard failure; FR silence quirk |
| Prosody | **3** (est.) | Instruct used (“warm, steady, motivational”); not scored formally |
| Long-form consistency | **3–4** | 94.6 s narrative completed without crash; stability OK |
| Emotional / motivational delivery | **3** (est.) | Instruct path exists — subjective EH fitness needs human review of `english_narrative.wav` |

OpenAI / CosyVoice: not subjectively scored (no live OpenAI audio; CosyVoice not run).

---

## 13. Architecture experiment outcome

Implemented **inside `services/ai_proxy` only**:

```text
EH_TTS_PROVIDER / optional providerHint
        │
        ▼
TtsProviderResolver
        ├── openai → OpenAiTtsProvider → OpenAiSpeechClient
        └── qwen3  → LocalHttpTtsProvider → local Python sidecar
```

- Flutter still knows only `VoiceRenderingPort`
- Domain / `StoryVoiceRendering` unchanged in contract
- `EH_TTS_PROVIDER=openai|qwen3`
- `cosyvoice` fails closed with explicit “not successfully verified” error
- No streaming, no cloning, no VoiceProfile

---

## 14. Cost / ownership implications

| Path | Ops implication |
|------|-----------------|
| Hosted OpenAI | Per-character API cost; zero local GPU; data egress; simplest ops |
| Local Qwen3 0.6B | Hardware + electricity; privacy retention on-box; Mac mini feasible for lab; CPU-only too slow for interactive UX |
| CosyVoice (if later verified on M4) | Higher install burden; larger disk/RAM; possibly better zero-shot cloning later |

---

## 15. Recommended next experiment

1. **On the M4 Mac mini:** rerun `tool/tts_benchmark/run_benchmark.dart` for **OpenAI** (with key) and **Qwen3** (`EH_QWEN3_TTS_DEVICE=mps` if available).
2. Human-listen Qwen `english_narrative.wav` + multilingual set for EH motivational fitness.
3. Optional: attempt CosyVoice via a Mac-oriented fork / CPU path **only if** Andy prioritizes clone-path comparison — otherwise defer.
4. Do **not** proceed automatically to VoiceProfile / cloning / production provider lock.

---

## 16. Success criteria answers (for Andy — not auto-decided)

| Question | Evidence-based answer |
|----------|------------------------|
| Hosted OpenAI performance? | Client/path verified; **live latency pending keyed Mac run** |
| Can Qwen3 run practically on M4/16GB? | **Likely yes** for 0.6B (fits ~5 GB RSS on CPU; community Mac guidance aligns). **Confirm MPS RTF on Mac.** |
| Can CosyVoice run practically on M4/16GB? | **Possible but fragile/tight** (~8 GB worker reports; heavy install). **Not verified in this spike.** |
| Quality for long-form EH narration? | Qwen produced full ~95 s audio; subjective grade needs human listen |
| Multilingual coverage? | Qwen succeeded for en/es/fr/de in corpus |
| Future cloning path? | **Qwen3 Base** and **CosyVoice zero-shot** both look promising technically; Qwen is the one actually running today |
| Provider selection invisible to Flutter/domain? | **Yes** — proxy `TtsProvider` only |
| Final provider choice? | **Deferred — Andy’s approval required** |

---

## Repro commands

```bash
# Unit tests (no ML weights)
cd services/ai_proxy && dart test
cd ../.. && flutter test

# Fake sidecar smoke
python3 services/ai_proxy/tts_sidecar/server.py   # EH_LOCAL_TTS_BACKEND=fake
cd services/ai_proxy && dart run tool/tts_benchmark/run_benchmark.dart \
  --provider fake --sidecar http://127.0.0.1:8791 \
  --out ../../docs/architecture/hs12_7_benchmark_artifacts

# Qwen3 (after venv + weights)
export EH_LOCAL_TTS_BACKEND=qwen3
export EH_QWEN3_TTS_DEVICE=cpu   # or mps on Mac
python3 services/ai_proxy/tts_sidecar/server.py
export EH_TTS_PROVIDER=qwen3 EH_LOCAL_TTS_URL=http://127.0.0.1:8791
# then proxy + benchmark --provider qwen3
```
