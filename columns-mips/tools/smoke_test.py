#!/usr/bin/env python3
"""Assemble the original; run an explicitly instrumented temporary copy in MARS."""
from pathlib import Path
import subprocess, sys, tempfile
root = Path(__file__).resolve().parents[1]
jar = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else None
if jar is None:
    raise SystemExit('Usage: python3 tools/smoke_test.py /path/to/Mars4_5.jar')
base = ['java', '-Djava.awt.headless=true', '-jar', str(jar), 'nc']
subprocess.run(base + ['a', 'ae1', str(root / 'Columns_Game.asm')], check=True, timeout=30)
source = (root / 'Columns_Game.asm').read_text()
source = source.replace('    jal select_difficulty', '    jal smoke_select', 1)
source = source.replace('game_loop:\n', '''game_loop:
    lw $t0, smoke_frames
    addiu $t0, $t0, 1
    sw $t0, smoke_frames
    li $t1, 121
    beq $t0, $t1, smoke_done
''', 1)
source += '''
.data
smoke_frames: .word 0
smoke_message: .asciiz "SMOKE_OK: 120 frames completed\\n"
.text
smoke_select:
    li $t4, 1
    sw $t4, level
    sw $t4, difficulty_multiplier
    j update_gravity_speed
smoke_done:
    li $v0, 4
    la $a0, smoke_message
    syscall
    li $v0, 10
    syscall
'''
with tempfile.TemporaryDirectory() as folder:
    derived = Path(folder) / 'instrumented.asm'
    derived.write_text(source)
    result = subprocess.run(base + ['ae1', 'se2', '2000000', str(derived)], capture_output=True, text=True, timeout=45)
    print(result.stdout, end='')
    print(result.stderr, end='', file=sys.stderr)
    if result.returncode or 'SMOKE_OK' not in result.stdout:
        raise SystemExit('Smoke test failed')
