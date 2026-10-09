"""POC invariant: same story, two timelines → different ACE plans; LM off."""

from __future__ import annotations

from ace_step_eh_adapter.compiler import compile_timeline
from ace_step_eh_adapter.fixtures_io import load_poc_pair
from ace_step_eh_adapter.models import CompilerMode


def test_same_story_two_timelines_change_the_plan():
    seed, timeline_a, timeline_b = load_poc_pair()

    assert seed.story_id == timeline_a.story_id == timeline_b.story_id
    assert timeline_a.timeline_id != timeline_b.timeline_id

    a = compile_timeline(seed, timeline_a, mode=CompilerMode.EH_TAGS, seed_value=42)
    b = compile_timeline(seed, timeline_b, mode=CompilerMode.EH_TAGS, seed_value=42)

    # Controls held fixed
    assert a.params.seed == b.params.seed == 42
    assert a.params.bpm == b.params.bpm == seed.bpm
    assert a.params.keyscale == b.params.keyscale
    assert a.params.model_hint == b.params.model_hint
    assert a.params.duration == b.params.duration == 240.0
    assert a.inspiration_lm_off and b.inspiration_lm_off
    assert a.params.use_llm_inspiration is False
    assert b.params.use_llm_inspiration is False

    # Music plan changes because the narrative timeline changed
    assert a.params.caption != b.params.caption
    assert a.params.lyrics != b.params.lyrics
    assert a.phase_windows != b.phase_windows

    # Timeline A peaks at Breakthrough; Timeline B suppresses it
    a_breakthrough = next(w for w in a.phase_windows if w.phase_name == "Breakthrough")
    b_breakthrough = next(w for w in b.phase_windows if w.phase_name == "Breakthrough")
    assert a_breakthrough.energy > b_breakthrough.energy
    assert a_breakthrough.start_seconds > b_breakthrough.start_seconds

    # Phase order differs in compiled caption timing
    assert "Breakthrough" in a.params.caption and "Breakthrough" in b.params.caption
    assert "2:40–3:30 Breakthrough" in a.params.caption or "2:40" in a.params.caption
    assert "0:55–1:35 Breakthrough" in b.params.caption or "0:55" in b.params.caption


def test_conventional_backend_also_differs_by_timeline():
    """Option A tags may be used as a compiler backend inside Option B."""
    seed, timeline_a, timeline_b = load_poc_pair()
    a = compile_timeline(seed, timeline_a, mode=CompilerMode.CONVENTIONAL)
    b = compile_timeline(seed, timeline_b, mode=CompilerMode.CONVENTIONAL)
    assert a.params.lyrics != b.params.lyrics
    assert "[Chorus]" in a.params.lyrics
    assert a.inspiration_lm_off
