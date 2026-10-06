"""Load POC fixtures from JSON."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from ace_step_eh_adapter.models import (
    NarrativeMusicTimeline,
    NarrativePhase,
    StorySeed,
)

# fixtures_io.py → ace_step_eh_adapter/ → src/ → package root
FIXTURES_DIR = Path(__file__).resolve().parents[2] / "fixtures"


def _load_json(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as f:
        return json.load(f)


def load_story_seed(path: Path | None = None) -> StorySeed:
    data = _load_json(path or FIXTURES_DIR / "story_seed.json")
    return StorySeed(
        story_id=data["story_id"],
        title=data["title"],
        narrative_summary=data["narrative_summary"],
        style_brief=data["style_brief"],
        instrumental=bool(data.get("instrumental", True)),
        bpm=data.get("bpm"),
        keyscale=data.get("keyscale"),
        language=data.get("language", "unknown"),
    )


def load_timeline(path: Path) -> NarrativeMusicTimeline:
    data = _load_json(path)
    phases = tuple(
        NarrativePhase(
            name=p["name"],
            start_seconds=float(p["start_seconds"]),
            end_seconds=float(p["end_seconds"]),
            emotional_state=p["emotional_state"],
            energy=float(p["energy"]),
            musical_intent=p["musical_intent"],
            lyric_intent=p.get("lyric_intent"),
        )
        for p in data["phases"]
    )
    return NarrativeMusicTimeline(
        timeline_id=data["timeline_id"],
        story_id=data["story_id"],
        label=data["label"],
        phases=phases,
        notes=data.get("notes", ""),
    )


def load_poc_pair() -> tuple[StorySeed, NarrativeMusicTimeline, NarrativeMusicTimeline]:
    seed = load_story_seed()
    timeline_a = load_timeline(FIXTURES_DIR / "timeline_a.json")
    timeline_b = load_timeline(FIXTURES_DIR / "timeline_b.json")
    return seed, timeline_a, timeline_b
