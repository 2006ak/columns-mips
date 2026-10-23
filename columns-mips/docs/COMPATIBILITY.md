# Simulator compatibility

## Findings and limits

MARS assembly succeeds for the exact attachment. This rules out a basic MARS syntax failure in the recovered file. It does not establish why a particular Saturn installation failed to open the file. The installed Saturn version, exact error, and original file-picker behavior were unavailable.

The inspected Saturn `development` sources explicitly dispatch syscalls 10, 32 (sleep), and 42 (bounded random integer); expose keyboard MMIO at `0xffff0000`; and include a configurable bitmap display. Therefore these dependencies are requirements to configure/check, not demonstrated Saturn incompatibilities. An installed release may differ from development.

## Separate the symptoms

- **Cannot open the file:** use the extracted `Columns_Game.asm` from this project with Saturn's Open command. This is plain UTF-8 text, not an archive, document, or compiled executable. A file-picker filter, inaccessible attachment location, or application issue remains possible; none was reproduced. Record the Saturn version and exact error if this persists.
- **Opens but does not assemble:** keep pseudo/extended instructions enabled. The source uses `li`, `la`, `move`, label-based loads/stores, and immediate-operand branch pseudoinstructions. Capture the first diagnostic and line number before making a separate compatibility copy.
- **Runs but stays blank:** `main` calls `select_difficulty` before any scene drawing. Click/focus the keyboard input surface and press `1`, `2`, or `3`. Console input is insufficient.
- **Runs but display is distorted/empty:** configure base address `0x10008000` and a 32 × 32 logical word grid. In MARS this is 256 × 256 display pixels with 8 × 8 units. Saturn's inspected UI labels display dimensions in units; use 32 × 32 logical units with 8 × 8 pixel scaling where applicable. Match the logical grid rather than copying pixel counts into fields labeled units. Prefer the explicit base address over an assumed `$gp` value.
- **Keyboard does nothing in Saturn:** the inspected Bitmap tab says to click the display to connect keyboard events. In MARS, connect and focus the Keyboard and Display MMIO Simulator input area.
- **Unexpected execution:** delayed branching must be disabled; the program does not provide safe delay-slot scheduling. Use the default MARS memory map so data at `0x10010000` stays separate from the display at `0x10008000`.
- **Pacing differs:** sleeps use milliseconds, but rendering and simulator overhead add time. Initial gravity thresholds are 65, 50, and 35 game-loop iterations for easy, medium, and hard; the code clamps later thresholds to at least 8.

## Unmodified source observations

`restart_game` (lines 1999–2016) does not restore the initial active-column position. A fresh simulator reset restores the data defaults (`active_x = 12`, `active_y = 3`).

White gems are not a general wildcard in the match routines: equality checks happen before the special-gem checks. Do not assume that one white gem matches two arbitrary colors.

No compatibility fork is supplied because no failing Saturn assembly diagnostic has been reproduced. Any future fixes should be made as a clearly named derivative or commit, keeping this original and its checksum available.

## Primary references

Inspected on 2026-10-23:

- [Official MARS repository and downloads](https://github.com/dpetersanderson/MARS)
- [MARS syscall reference](https://dpetersanderson.github.io/Help/SyscallHelp.html)
- [MARS settings](https://dpetersanderson.github.io/Help/Settings.html)
- [Saturn repository](https://github.com/1whatleytay/saturn)
- [Saturn syscall implementation](https://github.com/1whatleytay/saturn/blob/development/src-backend/src/syscall.rs)
- [Saturn keyboard implementation](https://github.com/1whatleytay/saturn/blob/development/src-backend/src/keyboard.rs)
- [Saturn Bitmap tab](https://github.com/1whatleytay/saturn/blob/development/src/components/console/BitmapTab.vue)

Saturn links point to a moving development branch, not the user's installed version.
