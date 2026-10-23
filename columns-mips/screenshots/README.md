# Game display captures

These PNGs show the actual 32 × 32 framebuffer produced by executing the recovered game in official MARS 4.5. They are framebuffer captures, rather than desktop-window screenshots: native desktop control was unavailable during capture.

A temporary copy renamed the original entry point and appended a capture driver. The driver initialized easy difficulty and MARS random generator 0 with seed 258, called the original board/color initialization routines, and drove `move_left`, `move_right`, `rotate_column`, and `move_down`. Drops continued until the original spawn logic reset the column position. It then called the original scene, active-column, and score drawing routines. No gems, scores, or framebuffer pixels were manually painted or supplied as a preset board.

- `02-mid-game.png`: after 12 scripted column drops and four additional downward steps.
- `04-stacked-board.png`: after 24 scripted column drops and four additional downward steps.
- `03-paused.png`: the original `clear_screen` and `draw_paused_message` routines, called directly after the 12-drop sequence. This captures the pause appearance without entering its keyboard-wait loop.

After each run, MARS dumped the display memory starting at `0x10008000`. Each little-endian word was interpreted as `0x00RRGGBB`. The resulting 32 × 32 image was enlarged to 768 × 768 using nearest-neighbor scaling, preserving exact colors and pixel edges. No simulator chrome, visual effects, recoloring, or generated artwork was added.

The capture driver bypasses interactive keyboard input, uses a deterministic seed, and exits after drawing. These images demonstrate rendering and scripted movement, rather than a manual interactive playthrough. `Columns_Game.asm` remains byte-for-byte identical to the recovered attachment.
