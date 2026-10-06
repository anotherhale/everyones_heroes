"""Compiler unit tests."""

from __future__ import annotations

import pytest

from ace_step_eh_adapter.compiler import compile_timeline, repaint_window_for_phase
from ace_step_eh_adapter.fixtures_io import load_poc_pair
from ace_step_eh_adapter.models import (
    CompilerMode,
    NarrativeMusicTimeline,
    NarrativePhase,
    StorySeed,
)


@pytest.fixture
def poc():
    return load_poc_pair()


def test_eh_tags_appear_in_lyrics(poc):
    seed, timeline_a, _ = poc
    req = compile_timeline(seed, timeline_a, mode=CompilerMode.EH_TAGS)
    lyrics = req.params.lyrics
    assert "[Opening]" in lyrics
    assert "[Breakthrough]" in lyrics
    assert "[Resolution]" in lyrics
    assert "[Instrumental]" in lyrics
    # Conventional song tags should not be required
    assert "[Chorus]" not in lyrics


def test_conventional_mode_maps_breakthrough_to_chorus(poc):
    seed, timeline_a, _ = poc
    req = compile_timeline(seed, timeline_a, mode=CompilerMode.CONVENTIONAL)
    assert "[Chorus]" in req.params.lyrics
    assert "[Intro]" in req.params.lyrics
    assert "[Outro]" in req.params.lyrics


def test_inspiration_lm_forced_off(poc):
    seed, timeline_a, _ = poc
    req = compile_timeline(seed, timeline_a)
    assert req.inspiration_lm_off is True
    assert req.params.use_llm_inspiration is False
    assert req.params.thinking is False
    assert req.params.format_lyrics_with_llm is False


def test_duration_equals_timeline_end(poc):
    seed, timeline_a, _ = poc
    req = compile_timeline(seed, timeline_a)
    assert req.params.duration == 240.0
    assert req.phase_windows[-1].end_seconds == 240.0


def test_caption_encodes_timed_arc(poc):
    seed, timeline_a, _ = poc
    req = compile_timeline(seed, timeline_a)
    caption = req.params.caption
    assert "0:00–0:30 Opening" in caption
    assert "2:40–3:30 Breakthrough" in caption or "2:40–3:30" in caption
    assert "peak intensity" in caption.lower() or "elevated" in caption.lower()


def test_repaint_window_for_breakthrough(poc):
    seed, timeline_a, _ = poc
    req = compile_timeline(seed, timeline_a)
    window = repaint_window_for_phase(req, "Breakthrough")
    assert window["task_type"] == "repaint"
    assert window["repainting_start"] == 160.0
    assert window["repainting_end"] == 210.0


def test_story_id_mismatch_raises():
    seed = StorySeed(
        story_id="a",
        title="t",
        narrative_summary="s",
        style_brief="style",
    )
    timeline = NarrativeMusicTimeline(
        timeline_id="t1",
        story_id="b",
        label="bad",
        phases=(
            NarrativePhase(
                name="Opening",
                start_seconds=0,
                end_seconds=10,
                emotional_state="calm",
                energy=0.2,
                musical_intent="sparse",
            ),
        ),
    )
    with pytest.raises(ValueError, match="story_id mismatch"):
        compile_timeline(seed, timeline)


def test_overlapping_phases_rejected():
    with pytest.raises(ValueError, match="overlapping"):
        NarrativeMusicTimeline(
            timeline_id="t1",
            story_id="s",
            label="bad",
            phases=(
                NarrativePhase(
                    name="A",
                    start_seconds=0,
                    end_seconds=20,
                    emotional_state="x",
                    energy=0.2,
                    musical_intent="a",
                ),
                NarrativePhase(
                    name="B",
                    start_seconds=10,
                    end_seconds=30,
                    emotional_state="y",
                    energy=0.3,
                    musical_intent="b",
                ),
            ),
        )
