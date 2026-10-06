"""EH → ACE-Step Narrative Music Adapter (out-of-repo POC).

This package is intentionally outside the EH Flutter domain.
It compiles Narrative Music Timelines into ACE-Step GenerationParams-shaped
payloads. ACE-Step types must not leak into EH domain models.
"""

from .compiler import compile_timeline
from .models import (
    AceGenerationRequest,
    CompilerMode,
    NarrativeMusicTimeline,
    NarrativePhase,
    StorySeed,
)

__all__ = [
    "AceGenerationRequest",
    "CompilerMode",
    "NarrativeMusicTimeline",
    "NarrativePhase",
    "StorySeed",
    "compile_timeline",
]
