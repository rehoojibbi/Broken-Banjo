# Sorceress sprite pack

- Each `*.png` is a uniform grid (left→right, top→bottom).
- `sprite_sheets.json` describes grid size, selected frames, FPS, animation sections/tags, combat pointers, and timing (`sourceFps` / `sampleEvery` / `playbackFps`).
- Optional `*.hits.json` files hold per-frame hitboxes (x/y/w/h in exported frame pixels).
- Optional `*.mp3` files are the audio track extracted from each source animation video.

## Timing (read this before wiring playback)

- Source video fps is assumed **30**.
- Frame extraction uses **sampleEvery** (every Nth source frame). UI "Every 4" → sampleEvery=4.
- Default sheet **playbackFps = sourceFps / sampleEvery** (e.g. 30/4 = **7.5**). Playing at that rate keeps the same duration as the original 30fps clip (equivalent timing with fewer frames).
- Agents/games may change fps — that is fine — but then stretch or retime audio yourself.
- With Sounds packed: each sprite's `audioFile` should start at animation start when using that sprite's default `timing.playbackFps` (or section fps). Start each audioFile with its sprite animation. At the pack/sprite default playbackFps (sourceFps / sampleEvery), SFX stay aligned with the source clip. Changing fps without retiming audio will desync sound.

Prefer `animation.sections` over legacy start/middle/end mirrors. Custom section `name`/`description` are gameplay tags.
