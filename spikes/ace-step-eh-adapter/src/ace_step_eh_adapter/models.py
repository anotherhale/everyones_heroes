"""POC data shapes for Narrative Music Timeline → ACE-Step request.

These are spike / infrastructure artifacts only.
They are not EH domain aggregates and must not be imported into Flutter domain.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from enum import Enum
from typing import Any


class CompilerMode(str, Enum):
    """How phase labels are rendered into the lyrics string."""

    EH_TAGS = "eh_tags"
    """Use EH narrative phase names: [Opening], [Challenge], …"""

    CONVENTIONAL = "conventional"
    """Map phases onto soft Verse/Chorus-style tags as a compiler backend only."""


@dataclass(frozen=True)
class StorySeed:
    """Fixed story text shared across timeline variants."""

    story_id: str
    title: str
    narrative_summary: str
    style_brief: str
    instrumental: bool = True
    bpm: int | None = 88
    keyscale: str | None = "C minor"
    language: str = "unknown"


@dataclass(frozen=True)
class NarrativePhase:
    """One timed narrative phase on an EH-owned music timeline."""

    name: str
    start_seconds: float
    end_seconds: float
    emotional_state: str
    energy: float  # 0.0–1.0
    musical_intent: str
    lyric_intent: str | None = None

    def __post_init__(self) -> None:
        if self.end_seconds <= self.start_seconds:
            raise ValueError(
                f"phase {self.name!r}: end_seconds must be > start_seconds"
            )
        if not 0.0 <= self.energy <= 1.0:
            raise ValueError(f"phase {self.name!r}: energy must be in [0, 1]")

    @property
    def duration_seconds(self) -> float:
        return self.end_seconds - self.start_seconds


@dataclass(frozen=True)
class NarrativeMusicTimeline:
    """EH/application-side timeline — not an ACE-Step schema object."""

    timeline_id: str
    story_id: str
    label: str
    phases: tuple[NarrativePhase, ...]
    notes: str = ""

    def __post_init__(self) -> None:
        if not self.phases:
            raise ValueError("timeline must contain at least one phase")
        ordered = sorted(self.phases, key=lambda p: p.start_seconds)
        if tuple(p.name for p in ordered) != tuple(p.name for p in self.phases):
            # Allow unsorted input but store as provided; compiler sorts.
            pass
        for prev, curr in zip(ordered, ordered[1:]):
            if curr.start_seconds < prev.end_seconds - 1e-6:
                raise ValueError(
                    f"overlapping phases: {prev.name!r} and {curr.name!r}"
                )

    @property
    def duration_seconds(self) -> float:
        return max(p.end_seconds for p in self.phases)

    def sorted_phases(self) -> tuple[NarrativePhase, ...]:
        return tuple(sorted(self.phases, key=lambda p: p.start_seconds))


@dataclass(frozen=True)
class PhaseWindow:
    """Absolute seconds window for later ACE-Step repaint mapping."""

    phase_name: str
    start_seconds: float
    end_seconds: float
    energy: float


@dataclass(frozen=True)
class AceGenerationParams:
    """Subset of ACE-Step GenerationParams the adapter emits.

    Field names mirror ACE-Step's flat contract for easy HTTP / CLI handoff.
    Inspiration / CoT rewrite is explicitly disabled for the primary POC arm.
    """

    caption: str
    lyrics: str
    duration: float
    bpm: int | None = None
    keyscale: str | None = None
    vocal_language: str = "unknown"
    timesignature: str | None = "4/4"
    instrumental: bool = True
    # Inspiration LM / CoT rewrite MUST stay off for the primary POC.
    thinking: bool = False
    use_llm_inspiration: bool = False
    format_lyrics_with_llm: bool = False
    task_type: str = "text2music"
    seed: int | None = 42
    model_hint: str = "acestep-v15-turbo"

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class AceGenerationRequest:
    """Full adapter output: params + EH-side phase→time map + provenance."""

    params: AceGenerationParams
    phase_windows: tuple[PhaseWindow, ...]
    timeline_id: str
    story_id: str
    compiler_mode: CompilerMode
    inspiration_lm_off: bool = True
    provenance: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "params": self.params.to_dict(),
            "phase_windows": [asdict(w) for w in self.phase_windows],
            "timeline_id": self.timeline_id,
            "story_id": self.story_id,
            "compiler_mode": self.compiler_mode.value,
            "inspiration_lm_off": self.inspiration_lm_off,
            "provenance": self.provenance,
        }
