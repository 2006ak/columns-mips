# Recovery and validation record

Date: 2026-10-23.

## Recovery

The referenced conversation exposed its attachment as `Columns_Game.asm` through a local temporary preview file. `/mnt/data/Columns_Game.asm` was not present in this desktop environment. The actual attached file was copied directly as bytes, without reconstructing it from chat previews.

- Byte length: 60,703.
- Logical source lines: 3,035.
- LF characters: 3,034; no final newline.
- Encoding: valid UTF-8.
- SHA-256: `6d866677383ec77ca2dc77c6692e78e29dfc9f966ce74568286839d8ad716132`.
- Labels found by static scan: 192, with no duplicates.
- Last instruction: `j game_loop`.
- No external includes or game assets are needed for assembly.

This confirms complete recovery of the supplied attachment, not comparison against an unavailable earlier authoring copy.

## Original assembly

Used the official `Mars4_5.jar` release asset from:
https://github.com/dpetersanderson/MARS/releases/download/v.4.5.1/Mars4_5.jar

Host Java: OpenJDK 25.0.1.

```sh
java -Djava.awt.headless=true -jar Mars4_5.jar nc a ae1 Columns_Game.asm
```

Result: exit 0, no assembly errors or warnings. This also resolves references accepted by the MARS assembler.

## Bounded original execution

```sh
java -Djava.awt.headless=true -jar Mars4_5.jar nc me 10000 Columns_Game.asm
```

Result: execution reached the 10,000-step limit without a reported exception. With no MMIO keyboard events provided, this is expected to stay in the difficulty-selection polling loop. It does not exercise gameplay.

## Instrumented smoke test

`tools/smoke_test.py` first assembles the original, then creates a temporary derivative. It replaces only the first difficulty-selection call with an easy-difficulty initialization stub, adds a frame counter at `game_loop`, and prints a success marker and exits on entering iteration 121. All original gameplay routines and sleep calls remain present. A two-million-instruction bound and process timeout guard the test.

The marker confirms 120 complete game-loop iterations, exercising initialization, random colors, automatic downward movement, and scene drawing into memory. It does not verify visible graphics, keyboard focus, movement keys, matching, scoring, special gems, pause, game over, or retry. No interactive playthrough or installed Saturn execution was performed.

Observed result: original assembly passed; temporary execution printed `SMOKE_OK: 120 frames completed` and exited successfully.
