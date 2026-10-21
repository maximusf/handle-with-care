# Player sprites

All game frames are 48 × 64 RGBA pixels. Use nearest-neighbor filtering.

- `player_body.aseprite` / `.png` / `.json` contain the animated body, hands, and shoes, without the head.
- `player_head.aseprite` / `.png` / `.json` contain five static aiming directions and their matching blink frames.

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

Both sheets use the same canvas coordinates. Draw the body at its normal origin. The head anchor is (22, 26); the floor boundary is y = 63, below the lowest opaque shoe pixel. Mirror the composed character for left-facing movement so all parts and offsets stay aligned.
