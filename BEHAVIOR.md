# Bell behavior plan

Bell is a silent, top-right focus timer that stays out of the way until a work block ends.

## Timer

- Default focus block: **35 minutes**; duration is configurable.
- The displayed time and perimeter update only at **5-minute boundaries**: `35 → 30 → 25 → … → 5 → 0`.
- Custom durations remain exact and then decrease every five elapsed minutes; for example, `37 → 32 → 27 → …`.
- Round remaining time up to the next five-minute mark. Never show seconds or animate continuously.
- Keep the timer very translucent through 10 minutes remaining. Increase visibility at 5 minutes, then show the goal prompt at 0.
- The perimeter represents elapsed time but moves only with the five-minute display updates.
- No sound, bouncing, pulsing, glow, or notification badge.

## Goal flow

- During a focus block, show the current goal inside the circle without a redundant label.
- At 0, replace the circle with one compact row:
  - Text field placeholder: `Highest value driver`
  - Arrow button to save and begin the next block
- Below the field, show `30 min`, `45 min`, and `60 min` chips plus a compact custom-minutes field. The chosen duration applies when the arrow is pressed.
- Clicking the goal inside the circle opens the same editor with the current goal and duration, allowing the next block to be revised and restarted.
- Do not show a heading, explanatory copy, dropdown, or Skip action.
- The prompt is lightly translucent at rest and darkens only on hover or keyboard focus.

## Controls

- The overlay is draggable and starts in the top-right.
- The overlay window is always **210 × 196 points**. The 180-point circle and the 180 × 152-point editor swap inside that fixed footprint, so changing states never moves or expands beyond the screen edge.
- While the editor is visible and Bell is active: `⌘0` focuses the goal, `⌘1` selects 30 minutes, `⌘2` selects 45 minutes, `⌘3` selects 60 minutes, `⌘4` focuses custom minutes, and `⌘↩` starts the timer.
- These editor shortcuts are never global and do nothing while the quiet timer is showing.
- A subtle `×` remains at the top-right with a forgiving hit area; clicking it quits Bell immediately.
- Also support normal macOS `⌘Q`, a menu-bar **Quit Bell** action, and terminal command `pkill -x Bell`.

## Logging

- Append one row when a block ends, with: start time, end time, planned minutes, clean elapsed time, status, and goal.
- Completed blocks use the explicit status `completed ✓`; canceled blocks use `canceled` and show their actual elapsed time, such as `12m 34s`.
- Editing, restarting, changing duration, ringing now, or quitting ends the active block as canceled; zero-length interruptions are omitted.
- Migrate legacy goal-start rows to `started` without guessing whether they completed, and retain a local legacy backup.
- CSV remains spreadsheet-compatible and local by default.
- Never block the next timer because logging failed; preserve the entry locally and retry later.

## Implementation rule

The Swift build should match the approved HTML mock before adding settings or polish. Behavior changes belong in this document first.
