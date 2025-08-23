QA Checklist for Crown Loop

1) Crown input
- Verify digital crown responsiveness across devices and OS versions.
- Check `invertCrown` toggle changes direction correctly and persists.

2) Hit / Miss edges
- Test alignment at exact tolerance boundaries and just outside (±hitToleranceDegrees).
- Verify a single hit is scored per gate (no double-counting).

3) Min / Max difficulty
- Ensure per-gate duration ramps down every 10 points and floors at 0.8s.
- Verify bonus points (streak multiples of 5) affect difficulty progression.

4) Daily mode rollover
- Confirm `seedForToday` is deterministic for the day.
- At local midnight, confirm dailyBest resets and new seed is used.

5) Settings persistence
- `hapticsEnabled`, `invertCrown`, and `ringSkin` persist across relaunch.

6) Haptics toggle
- Toggle haptics on/off and verify no haptic feedback when disabled.

7) Game Center failure modes
- If not authenticated, Leaderboard button shows an informative alert.
- Submitting high scores should fail gracefully (log or user feedback) when Game Center unavailable.

8) Complication snapshot
- Check complication displays updated `highScore` and that app triggers `WidgetCenter.reloadAllTimelines()` after new high score.

9) 40mm vs 45mm layout
- Verify ring/gate visuals and HUD fit and remain legible on both sizes.

10) VoiceOver labels
- Ensure Play area announces ring/gate positions and time remaining.
- Score/Streak/Lives announce as a single combined label for compact reading.

Notes
- Run these checks on actual watch hardware and in the Simulator with accessibility inspection enabled.
