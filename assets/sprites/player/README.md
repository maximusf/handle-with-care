# Player sprites

All game frames are 48 × 64 RGBA pixels. Use nearest-neighbor filtering.

- `player_base.aseprite`, `player_idle.png`, and `player_base_right.png` preserve the approved static pose.
- `player_body.aseprite` / `.png` / `.json` contain the animated body, hands, and shoes, without the head.
- `player_head.aseprite` / `.png` / `.json` contain five static aiming directions and their matching blink frames.
- `player_animations.aseprite` / `.png` / `.json` contain complete character animations using the neutral head, ready for preview or use without independent aiming.

## Body animation tags

Frame indices below are zero-based, matching exported JSON.

| Tag | Frames | Playback |
| --- | --- | --- |
| idle | 0–3 | Loop |
| walk | 4–9 | Loop |
| jump | 10–12 | Crouch, airborne tuck, recovery; trigger with gameplay |
| kick | 13–20 | Play once; maximum extension at frame 17 |

For variable jump lengths, hold frame 11 while airborne and use frame 12 for recovery. Character travel and jump height belong to gameplay; frames animate the pose in place. Frame durations are in the sheet JSON.

## Independent head aiming

Head frames 0–4 are `aim_down`, `aim_forward_down`, `aim_forward`, `aim_forward_up`, and `aim_up`. Frames 5–9 are matching `_blink` variants. Switch to the matching blink briefly, then restore the current open-eye frame.

Both sheets use the same canvas coordinates. Draw the body at its normal origin. Offset the head by `body_neck_per_frame[frame] - head_neck_anchor` from `player_body_neck.json`. The head anchor is (22, 26); the floor boundary is y = 63, below the lowest opaque shoe pixel. Mirror the composed character for left-facing movement so all parts and offsets stay aligned.

## Previews

`player_idle_preview.gif`, `player_walk_preview.gif`, `player_jump_preview.gif`, and `player_kick_preview.gif` are 8× nearest-neighbor previews. GIFs repeat for review even when the game action plays once. `player_aim_preview.png` shows the five open-eye directions at 4×; `player_kick_preview.png` shows the kick sequence at 3×. Preview files are not game sprite sheets.
