# EH local TTS sidecar (HS.12.7)
#
# Synthetic narration only. No cloning / VoiceProfile / streaming.
#
# Quick smoke (no ML weights):
#   python3 server.py
#   # EH_LOCAL_TTS_BACKEND=fake (default)
#
# Qwen3-TTS (after installing qwen-tts + torch into a venv):
#   export EH_LOCAL_TTS_BACKEND=qwen3
#   export EH_QWEN3_TTS_MODEL=Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice
#   export EH_QWEN3_TTS_SPEAKER=Ryan
#   export EH_QWEN3_TTS_DEVICE=cpu   # or mps / cuda:0 on capable hosts
#   python3 server.py
#
# CosyVoice (NOT successfully verified in HS.12.7 — kept for future Mac trials only):
#   Do not enable in production proxy selection until Andy approves a verified run.
#   export EH_LOCAL_TTS_BACKEND=cosyvoice
#   export EH_COSYVOICE_MODEL_DIR=/path/to/Fun-CosyVoice3-0.5B
#   export EH_COSYVOICE_PROMPT_WAV=/path/to/stock_prompt.wav
#   python3 server.py
#
# Wire into the Dart AI proxy (verified providers only: openai | qwen3):
#   export EH_TTS_PROVIDER=qwen3
#   export EH_LOCAL_TTS_URL=http://127.0.0.1:8791

requirements-fake.txt
  (none — stdlib only)

requirements-qwen3.txt
  see sibling file
