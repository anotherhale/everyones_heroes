"""Provider-neutral experimental narrative music types for the ACE-Step POC.

These are hypotheses to validate — NOT approved EH production domain objects.
Do not import ACE-Step types here.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Iterable, List, Mapping, Optional, Sequence
import json


@dataclass(frozen=True)
class NarrativeMusicSegment:
    """One phase in an experimental narrative music timeline."""

    role: str
    narrative_intent: str
    emotional_state: str
    energy: float
    instrumentation: Sequence[str]
    vocal_delivery: str
    duration_seconds: float
    performance_notes: Optional[str] = None

    def __post_init__(self) -> None:
        if not self.role.strip():
            raise ValueError("segment.role must be non-empty")
        if not (0.0 <= float(self.energy) <= 1.0):
            raise ValueError(f"energy must be in [0,1], got {self.energy}")
        if float(self.duration_seconds) <= 0:
            raise ValueError("duration_seconds must be > 0")

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class NarrativeMusicTimeline:
    """Ordered narrative musical phases for one generation."""

    name: str
    segments: Sequence[NarrativeMusicSegment]
    description: str = ""

    def __post_init__(self) -> None:
        if not self.name.strip():
            raise ValueError("timeline.name must be non-empty")
        if not self.segments:
            raise ValueError("timeline.segments must be non-empty")

    @property
    def total_duration_seconds(self) -> float:
        return float(sum(s.duration_seconds for s in self.segments))

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "description": self.description,
            "segments": [s.to_dict() for s in self.segments],
            "total_duration_seconds": self.total_duration_seconds,
        }


@dataclass(frozen=True)
class MusicCreativeDirection:
    """Broad musical constraints shared across timeline variants."""

    genre: str
    style: str
    instrumentation: Sequence[str]
    vocal_character: str
    bpm: int
    keyscale: str
    timesignature: str
    language: str
    duration_seconds: float
    constraints: Sequence[str] = field(default_factory=tuple)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class StoryText:
    """Canonical story text used for every generation."""

    text: str

    def __post_init__(self) -> None:
        if not self.text.strip():
            raise ValueError("story text must be non-empty")

    @property
    def lines(self) -> List[str]:
        return [ln.strip() for ln in self.text.splitlines() if ln.strip()]


def load_story(path: Path | str) -> StoryText:
    return StoryText(Path(path).read_text(encoding="utf-8").strip() + "\n")


def load_creative_direction(path: Path | str) -> MusicCreativeDirection:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    return MusicCreativeDirection(
        genre=raw["genre"],
        style=raw["style"],
        instrumentation=list(raw.get("instrumentation", [])),
        vocal_character=raw["vocal_character"],
        bpm=int(raw["bpm"]),
        keyscale=raw["keyscale"],
        timesignature=str(raw["timesignature"]),
        language=raw["language"],
        duration_seconds=float(raw["duration_seconds"]),
        constraints=list(raw.get("constraints", [])),
    )


def load_timeline(path: Path | str) -> NarrativeMusicTimeline:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    segments = [
        NarrativeMusicSegment(
            role=s["role"],
            narrative_intent=s["narrative_intent"],
            emotional_state=s["emotional_state"],
            energy=float(s["energy"]),
            instrumentation=list(s.get("instrumentation", [])),
            vocal_delivery=s["vocal_delivery"],
            duration_seconds=float(s["duration_seconds"]),
            performance_notes=s.get("performance_notes"),
        )
        for s in raw["segments"]
    ]
    return NarrativeMusicTimeline(
        name=raw["name"],
        description=raw.get("description", ""),
        segments=segments,
    )


def allocate_story_lines(
    story: StoryText, segments: Sequence[NarrativeMusicSegment]
) -> List[List[str]]:
    """Split story lines across segments by approximate duration weight."""
    lines = story.lines
    if not lines:
        raise ValueError("story has no lines")
    weights = [max(s.duration_seconds, 0.1) for s in segments]
    total_w = sum(weights)
    counts: List[int] = []
    assigned = 0
    for i, w in enumerate(weights):
        if i == len(weights) - 1:
            counts.append(len(lines) - assigned)
        else:
            n = max(1, round(len(lines) * (w / total_w)))
            # leave at least one line for remaining segments
            remaining_segments = len(weights) - i - 1
            n = min(n, len(lines) - assigned - remaining_segments)
            n = max(1, n)
            counts.append(n)
            assigned += n
    out: List[List[str]] = []
    idx = 0
    for n in counts:
        out.append(lines[idx : idx + n])
        idx += n
    return out
