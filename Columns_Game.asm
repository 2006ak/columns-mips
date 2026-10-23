################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Akshar
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Datas
##############################################################################
ADDR_DSPL:
    .word 0x10008000

ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################
active_x:
    .word 12

active_y:
    .word 3

active_c1:
    .word 0

active_c2:
    .word 0

active_c3:
    .word 0

preview_c1:
    .word 0

preview_c2:
    .word 0

preview_c3:
    .word 0

bg_color:
    .word 0x00000000

spawn_x:
    .word 12

spawn_y:
    .word 3

left_bound:
    .word 9

right_bound:
    .word 14

bottom_bound:
    .word 20

board_cells:
    .space 432
    
mark_cells:
    .space 432
    
gravity_counter:
    .word 0
    
level:
    .word 1

clear_count:
    .word 0

gravity_threshold:
    .word 60   # starts at 60 frames (≈1 sec)
    
score:
    .word 0

difficulty_multiplier:
    .word 1

##############################################################################
# Code
##############################################################################
    .text
    .globl main

main:
    lw $s0, ADDR_DSPL

    jal select_difficulty
    jal clear_board_array
    jal clear_mark_array
    sw $zero, gravity_counter
    jal init_active_column
    jal init_preview_column
    j game_loop


##############################################################################
# Select Difficulty: Easy, Medium, or Hard
##############################################################################
select_difficulty:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

select_difficulty_loop:
    lw $t0, ADDR_KBRD
    lw $t1, 0($t0)
    beq $t1, $zero, select_difficulty_loop

    lw $t2, 4($t0)

    li $t3, 0x31
    beq $t2, $t3, select_easy

    li $t3, 0x32
    beq $t2, $t3, select_medium

    li $t3, 0x33
    beq $t2, $t3, select_hard

    j select_difficulty_loop

select_easy:
    li $t4, 1
    sw $t4, level
    sw   $t4, difficulty_multiplier
    jal  update_gravity_speed
    j    select_difficulty_done

select_medium:
    li   $t4, 2
    sw   $t4, level
    sw   $t4, difficulty_multiplier
    jal  update_gravity_speed
    j    select_difficulty_done

select_hard:
    li   $t4, 3
    sw   $t4, level
    sw   $t4, difficulty_multiplier
    jal  update_gravity_speed
    j    select_difficulty_done

select_difficulty_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
##############################################################################
# Initialize active column colors
##############################################################################
init_active_column:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  get_random_color
    sw   $v0, active_c1

    jal  get_random_color
    sw   $v0, active_c2

    jal  get_random_color
    sw   $v0, active_c3

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Initialize preview column colors
##############################################################################
init_preview_column:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  get_random_color
    sw   $v0, preview_c1

    jal  get_random_color
    sw   $v0, preview_c2

    jal  get_random_color
    sw   $v0, preview_c3

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Clears stored board cells
##############################################################################
clear_board_array:
    li   $t0, 0
    li   $t1, 108
    la   $t2, board_cells

clear_board_array_loop:
    sll  $t3, $t0, 2
    add  $t4, $t2, $t3
    sw   $zero, 0($t4)

    addi $t0, $t0, 1
    slt  $t5, $t0, $t1
    bne  $t5, $zero, clear_board_array_loop

    jr   $ra

##############################################################################
# Clears mark cells
##############################################################################
clear_mark_array:
    li   $t0, 0
    li   $t1, 108
    la   $t2, mark_cells

clear_mark_array_loop:
    sll  $t3, $t0, 2
    add  $t4, $t2, $t3
    sw   $zero, 0($t4)

    addi $t0, $t0, 1
    slt  $t5, $t0, $t1
    bne  $t5, $zero, clear_mark_array_loop

    jr   $ra

##############################################################################
# Gets address of board cell by row/col in v0
# Input: a0 = row, a1 = col
##############################################################################
board_rc_get_address:
    li   $t0, 6
    mult $a0, $t0
    mflo $t1
    add  $t1, $t1, $a1
    sll  $t1, $t1, 2

    la   $t2, board_cells
    add  $v0, $t2, $t1
    jr   $ra

##############################################################################
# Gets address of mark cell by row/col in v0
# Input: a0 = row, a1 = col
##############################################################################
mark_rc_get_address:
    li   $t0, 6
    mult $a0, $t0
    mflo $t1
    add  $t1, $t1, $a1
    sll  $t1, $t1, 2

    la   $t2, mark_cells
    add  $v0, $t2, $t1
    jr   $ra

##############################################################################
# Mark one cell
# Input: a0 = row, a1 = col
##############################################################################
mark_cell:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  mark_rc_get_address
    li   $t0, 1
    sw   $t0, 0($v0)

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Mark vertical matches
##############################################################################
mark_vertical_matches:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)

    li   $s0, 0

mark_vertical_row_loop:
    li   $s1, 0

mark_vertical_col_loop:
    move $a0, $s0
    move $a1, $s1
    jal  board_rc_get_address
    lw   $s2, 0($v0)
    beq  $s2, $zero, mark_vertical_next_col

    addi $a0, $s0, 1
    move $a1, $s1
    jal  board_rc_get_address
    lw   $s3, 0($v0)
    bne  $s2, $s3, mark_vertical_next_col

    addi $a0, $s0, 2
    move $a1, $s1
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    bne  $s2, $t0, mark_vertical_next_col

    move $a0, $s0
    move $a1, $s1
    jal  mark_cell

    addi $a0, $s0, 1
    move $a1, $s1
    jal  mark_cell

    addi $a0, $s0, 2
    move $a1, $s1
    jal  mark_cell

    jal  has_special_vertical
    beq  $v0, $zero, mark_vertical_next_col

    move $a1, $s1
    jal  mark_whole_column

mark_vertical_next_col:
    addi $s1, $s1, 1
    slti $t1, $s1, 6
    bne  $t1, $zero, mark_vertical_col_loop

    addi $s0, $s0, 1
    slti $t1, $s0, 16
    bne  $t1, $zero, mark_vertical_row_loop

    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    jr   $ra

mark_whole_column:
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    sw   $s4, 4($sp)
    sw   $s5, 8($sp)

    move $s5, $a1          # keep column safe
    li   $s4, 0            # row counter

mark_whole_column_loop:
    move $a0, $s4
    move $a1, $s5
    jal  mark_cell

    addi $s4, $s4, 1
    slti $t1, $s4, 18
    bne  $t1, $zero, mark_whole_column_loop

    lw   $s5, 8($sp)
    lw   $s4, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 12
    jr   $ra
    
has_special_vertical:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t9, 0x00ffffff

    move $a0, $s0
    move $a1, $s1
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    beq  $t0, $t9, has_special_vertical_true

    addi $a0, $s0, 1
    move $a1, $s1
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    beq  $t0, $t9, has_special_vertical_true

    addi $a0, $s0, 2
    move $a1, $s1
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    beq  $t0, $t9, has_special_vertical_true

    move $v0, $zero
    j    has_special_vertical_done

has_special_vertical_true:
    li   $v0, 1

has_special_vertical_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Mark horizontal matches
##############################################################################
mark_horizontal_matches:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)

    li   $s0, 0

mark_horizontal_row_loop:
    li   $s1, 0

mark_horizontal_col_loop:
    move $a0, $s0
    move $a1, $s1
    jal  board_rc_get_address
    lw   $s2, 0($v0)
    beq  $s2, $zero, mark_horizontal_next_col

    move $a0, $s0
    addi $a1, $s1, 1
    jal  board_rc_get_address
    lw   $s3, 0($v0)
    bne  $s2, $s3, mark_horizontal_next_col

    move $a0, $s0
    addi $a1, $s1, 2
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    bne  $s2, $t0, mark_horizontal_next_col

    move $a0, $s0
    move $a1, $s1
    jal  mark_cell

    move $a0, $s0
    addi $a1, $s1, 1
    jal  mark_cell

    move $a0, $s0
    addi $a1, $s1, 2
    jal  mark_cell

    jal  has_special_horizontal
    beq  $v0, $zero, mark_horizontal_next_col

    move $a0, $s0
    jal  mark_whole_row

mark_horizontal_next_col:
    addi $s1, $s1, 1
    slti $t1, $s1, 4
    bne  $t1, $zero, mark_horizontal_col_loop

    addi $s0, $s0, 1
    slti $t1, $s0, 18
    bne  $t1, $zero, mark_horizontal_row_loop

    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    jr   $ra
    
mark_whole_row:
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    sw   $s4, 4($sp)
    sw   $s5, 8($sp)

    move $s5, $a0          # keep row safe
    li   $s4, 0            # col counter

mark_whole_row_loop:
    move $a0, $s5
    move $a1, $s4
    jal  mark_cell

    addi $s4, $s4, 1
    slti $t1, $s4, 6
    bne  $t1, $zero, mark_whole_row_loop

    lw   $s5, 8($sp)
    lw   $s4, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 12
    jr   $ra
    
has_special_horizontal:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t9, 0x00ffffff

    move $a0, $s0
    move $a1, $s1
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    beq  $t0, $t9, has_special_horizontal_true

    move $a0, $s0
    addi $a1, $s1, 1
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    beq  $t0, $t9, has_special_horizontal_true

    move $a0, $s0
    addi $a1, $s1, 2
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    beq  $t0, $t9, has_special_horizontal_true

    move $v0, $zero
    j    has_special_horizontal_done

has_special_horizontal_true:
    li   $v0, 1

has_special_horizontal_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
##############################################################################
# Mark diagonal down-right matches
##############################################################################
mark_diag_dr_matches:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)

    li   $s0, 0

mark_diag_dr_row_loop:
    li   $s1, 0

mark_diag_dr_col_loop:
    move $a0, $s0
    move $a1, $s1
    jal  board_rc_get_address
    lw   $s2, 0($v0)
    beq  $s2, $zero, mark_diag_dr_next_col

    addi $a0, $s0, 1
    addi $a1, $s1, 1
    jal  board_rc_get_address
    lw   $s3, 0($v0)
    bne  $s2, $s3, mark_diag_dr_next_col

    addi $a0, $s0, 2
    addi $a1, $s1, 2
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    bne  $s2, $t0, mark_diag_dr_next_col

    move $a0, $s0
    move $a1, $s1
    jal  mark_cell

    addi $a0, $s0, 1
    addi $a1, $s1, 1
    jal  mark_cell

    addi $a0, $s0, 2
    addi $a1, $s1, 2
    jal  mark_cell

mark_diag_dr_next_col:
    addi $s1, $s1, 1
    slti $t1, $s1, 4
    bne  $t1, $zero, mark_diag_dr_col_loop

    addi $s0, $s0, 1
    slti $t1, $s0, 16
    bne  $t1, $zero, mark_diag_dr_row_loop

    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    jr   $ra

##############################################################################
# Mark diagonal down-left matches
##############################################################################
mark_diag_dl_matches:
    addi $sp, $sp, -20
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)

    li   $s0, 0

mark_diag_dl_row_loop:
    li   $s1, 2

mark_diag_dl_col_loop:
    move $a0, $s0
    move $a1, $s1
    jal  board_rc_get_address
    lw   $s2, 0($v0)
    beq  $s2, $zero, mark_diag_dl_next_col

    addi $a0, $s0, 1
    addi $a1, $s1, -1
    jal  board_rc_get_address
    lw   $s3, 0($v0)
    bne  $s2, $s3, mark_diag_dl_next_col

    addi $a0, $s0, 2
    addi $a1, $s1, -2
    jal  board_rc_get_address
    lw   $t0, 0($v0)
    bne  $s2, $t0, mark_diag_dl_next_col

    move $a0, $s0
    move $a1, $s1
    jal  mark_cell

    addi $a0, $s0, 1
    addi $a1, $s1, -1
    jal  mark_cell

    addi $a0, $s0, 2
    addi $a1, $s1, -2
    jal  mark_cell

mark_diag_dl_next_col:
    addi $s1, $s1, 1
    slti $t1, $s1, 6
    bne  $t1, $zero, mark_diag_dl_col_loop

    addi $s0, $s0, 1
    slti $t1, $s0, 16
    bne  $t1, $zero, mark_diag_dl_row_loop

    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 20
    jr   $ra

##############################################################################
# Returns 1 in v0 if any marks exist, else 0
##############################################################################
any_marks_exist:
    li   $t0, 0
    la   $t1, mark_cells

any_marks_exist_loop:
    lw   $t2, 0($t1)
    bne  $t2, $zero, any_marks_exist_true

    addi $t0, $t0, 1
    addi $t1, $t1, 4
    slti $t3, $t0, 108
    bne  $t3, $zero, any_marks_exist_loop

    move $v0, $zero
    jr   $ra

any_marks_exist_true:
    li   $v0, 1
    jr   $ra

##############################################################################
# Clear marked cells from board
##############################################################################
count_marked_cells:
    li   $t0, 0
    la   $t1, mark_cells
    move $v0, $zero

loop_count:
    lw   $t2, 0($t1)
    beq  $t2, $zero, next_cell
    addi $v0, $v0, 1

next_cell:
    addi $t1, $t1, 4
    addi $t0, $t0, 1
    li   $t3, 108
    bne  $t0, $t3, loop_count

    jr   $ra

clear_marked_cells:
    li   $t0, 0
    li   $t1, 108
    la   $t2, board_cells
    la   $t3, mark_cells

clear_marked_cells_loop:
    sll  $t4, $t0, 2
    add  $t5, $t2, $t4
    add  $t6, $t3, $t4
    lw   $t7, 0($t6)
    beq  $t7, $zero, clear_marked_cells_next

    sw   $zero, 0($t5)

clear_marked_cells_next:
    addi $t0, $t0, 1
    slt  $t8, $t0, $t1
    bne  $t8, $zero, clear_marked_cells_loop

    jr   $ra

##############################################################################
# Apply gravity to all columns
##############################################################################
apply_gravity:
    addi $sp, $sp, -24
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)
    sw   $s3, 16($sp)
    sw   $s4, 20($sp)

    li   $s0, 0

gravity_col_loop:
    li   $s1, 17
    li   $s2, 17

gravity_write_loop:
    bltz $s1, gravity_next_col

gravity_find_next:
    bltz $s2, gravity_fill_zeroes

    move $a0, $s2
    move $a1, $s0
    jal  board_rc_get_address
    lw   $s3, 0($v0)
    bne  $s3, $zero, gravity_place_gem

    addi $s2, $s2, -1
    j    gravity_find_next

gravity_place_gem:
    move $a0, $s1
    move $a1, $s0
    jal  board_rc_get_address
    sw   $s3, 0($v0)

    bne  $s1, $s2, gravity_clear_old
    addi $s1, $s1, -1
    addi $s2, $s2, -1
    j    gravity_write_loop

gravity_clear_old:
    move $a0, $s2
    move $a1, $s0
    jal  board_rc_get_address
    sw   $zero, 0($v0)

    addi $s1, $s1, -1
    addi $s2, $s2, -1
    j    gravity_write_loop

gravity_fill_zeroes:
    move $a0, $s1
    move $a1, $s0
    jal  board_rc_get_address
    sw   $zero, 0($v0)

    addi $s1, $s1, -1
    bgez $s1, gravity_fill_zeroes

gravity_next_col:
    addi $s0, $s0, 1
    slti $t0, $s0, 6
    bne  $t0, $zero, gravity_col_loop

    lw   $s4, 20($sp)
    lw   $s3, 16($sp)
    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 24
    jr   $ra
    
##############################################################################
# Updated the speed that blocks fall
##############################################################################

update_gravity_speed:
    lw   $t0, level

    li   $t1, 80
    li   $t2, 15

    mul  $t3, $t0, $t2
    sub  $t4, $t1, $t3

    li   $t5, 8
    slt  $t6, $t4, $t5
    beq  $t6, $zero, speed_ok
    move $t4, $t5

speed_ok:
    sw   $t4, gravity_threshold
    jr   $ra

##############################################################################
# Resolve board: all match directions, with flash, clear, and gravity
##############################################################################
resolve_board:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

resolve_board_loop:
    jal  clear_mark_array
    jal  mark_vertical_matches
    jal  mark_horizontal_matches
    jal  mark_diag_dr_matches
    jal  mark_diag_dl_matches
    jal  any_marks_exist
    beq  $v0, $zero, resolve_board_done

    jal  flash_marked_gems

    jal count_marked_cells      # v0 = gems cleared

    lw   $t0, difficulty_multiplier
    mul  $t1, $v0, $t0         # gems * difficulty

    lw   $t2, score
    add  $t2, $t2, $t1
    sw   $t2, score

    jal  clear_marked_cells
    jal  redraw_scene
    li   $v0, 32
    li   $a0, 160
    syscall

    lw   $t0, clear_count
    addi $t0, $t0, 1
    sw   $t0, clear_count

    li   $t1, 5
    bne  $t0, $t1, skip_level_up

    sw   $zero, clear_count

    lw   $t2, level
    addi $t2, $t2, 1
    sw   $t2, level

    jal  update_gravity_speed

skip_level_up:
    jal  apply_gravity
    jal  redraw_scene
    li   $v0, 32
    li   $a0, 220
    syscall

    j    resolve_board_loop

resolve_board_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
##############################################################################    
# Show outline where the active block would fall if it stayed in the same column
##############################################################################    
show_drop_outline:
    addi $sp, $sp, -16
    sw   $ra, 0($sp)
    sw   $s0, 4($sp)
    sw   $s1, 8($sp)
    sw   $s2, 12($sp)

    lw   $s0, active_y        # temp landing y
    lw   $s1, active_x        # keep x

show_drop_outline_find:
    lw   $t0, bottom_bound
    beq  $s0, $t0, show_drop_outline_draw

    move $a0, $s1
    addi $a1, $s0, 3
    jal  board_cell_occupied
    bne  $v0, $zero, show_drop_outline_draw

    addi $s0, $s0, 1
    j    show_drop_outline_find

show_drop_outline_draw:
    li   $s2, 0x00ffffff      # white

    move $a0, $s1
    move $a1, $s0
    move $a2, $s2
    jal  draw_unit

    move $a0, $s1
    addi $a1, $s0, 1
    move $a2, $s2
    jal  draw_unit

    move $a0, $s1
    addi $a1, $s0, 2
    move $a2, $s2
    jal  draw_unit

    li   $v0, 32
    li   $a0, 100
    syscall

    lw   $s2, 12($sp)
    lw   $s1, 8($sp)
    lw   $s0, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 16
    jr   $ra

##############################################################################
# Keyboard input: check once per frame
##############################################################################
handle_input:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t0, ADDR_KBRD
    lw   $t8, 0($t0)
    beq  $t8, $zero, handle_input_done

    lw   $t9, 4($t0)

    beq  $t9, 0x71, handle_q
    beq  $t9, 0x61, handle_a
    beq  $t9, 0x64, handle_d
    beq  $t9, 0x73, handle_s
    beq  $t9, 0x77, handle_w
    beq  $t9, 0x70, handle_p
    beq  $t9, 0x65, handle_e
    j    handle_input_done

handle_e:
    jal  show_drop_outline
    j    handle_input_done
    
handle_q:
    j    respond_to_Q

handle_a:
    jal  move_left
    j    handle_input_done

handle_d:
    jal  move_right
    j    handle_input_done

handle_s:
    jal  move_down
    sw   $zero, gravity_counter
    j    handle_input_done

handle_w:
    jal  rotate_column
    j    handle_input_done
    
handle_p:
    jal  pause_screen
    j    handle_input_done

handle_input_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Execute quitting on press of Q
##############################################################################
respond_to_Q:
    li   $v0, 10
    syscall

##############################################################################
# Executing pausing the game
##############################################################################
pause_screen:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

pause_screen_redraw:
    jal  clear_screen
    jal  draw_paused_message

pause_wait_input:
    lw   $t0, ADDR_KBRD
    lw   $t1, 0($t0)
    beq  $t1, $zero, pause_wait_input

    lw   $t2, 4($t0)

    li   $t3, 0x70
    beq  $t2, $t3, pause_done

    j    pause_wait_input

pause_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
draw_paused_message:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $a2, 0x00ffffff

    # P
    li   $a0, 4
    li   $a1, 8
    jal  draw_unit
    li   $a0, 5
    li   $a1, 8
    jal  draw_unit
    li   $a0, 6
    li   $a1, 8
    jal  draw_unit
    li   $a0, 4
    li   $a1, 9
    jal  draw_unit
    li   $a0, 6
    li   $a1, 9
    jal  draw_unit
    li   $a0, 4
    li   $a1, 10
    jal  draw_unit
    li   $a0, 5
    li   $a1, 10
    jal  draw_unit
    li   $a0, 6
    li   $a1, 10
    jal  draw_unit
    li   $a0, 4
    li   $a1, 11
    jal  draw_unit
    li   $a0, 4
    li   $a1, 12
    jal  draw_unit

    # A
    li   $a0, 8
    li   $a1, 8
    jal  draw_unit
    li   $a0, 9
    li   $a1, 8
    jal  draw_unit
    li   $a0, 10
    li   $a1, 8
    jal  draw_unit
    li   $a0, 8
    li   $a1, 9
    jal  draw_unit
    li   $a0, 10
    li   $a1, 9
    jal  draw_unit
    li   $a0, 8
    li   $a1, 10
    jal  draw_unit
    li   $a0, 9
    li   $a1, 10
    jal  draw_unit
    li   $a0, 10
    li   $a1, 10
    jal  draw_unit
    li   $a0, 8
    li   $a1, 11
    jal  draw_unit
    li   $a0, 10
    li   $a1, 11
    jal  draw_unit
    li   $a0, 8
    li   $a1, 12
    jal  draw_unit
    li   $a0, 10
    li   $a1, 12
    jal  draw_unit

    # U
    li   $a0, 12
    li   $a1, 8
    jal  draw_unit
    li   $a0, 14
    li   $a1, 8
    jal  draw_unit
    li   $a0, 12
    li   $a1, 9
    jal  draw_unit
    li   $a0, 14
    li   $a1, 9
    jal  draw_unit
    li   $a0, 12
    li   $a1, 10
    jal  draw_unit
    li   $a0, 14
    li   $a1, 10
    jal  draw_unit
    li   $a0, 12
    li   $a1, 11
    jal  draw_unit
    li   $a0, 14
    li   $a1, 11
    jal  draw_unit
    li   $a0, 12
    li   $a1, 12
    jal  draw_unit
    li   $a0, 13
    li   $a1, 12
    jal  draw_unit
    li   $a0, 14
    li   $a1, 12
    jal  draw_unit

    # S
    li   $a0, 16
    li   $a1, 8
    jal  draw_unit
    li   $a0, 17
    li   $a1, 8
    jal  draw_unit
    li   $a0, 18
    li   $a1, 8
    jal  draw_unit
    li   $a0, 16
    li   $a1, 9
    jal  draw_unit
    li   $a0, 16
    li   $a1, 10
    jal  draw_unit
    li   $a0, 17
    li   $a1, 10
    jal  draw_unit
    li   $a0, 18
    li   $a1, 10
    jal  draw_unit
    li   $a0, 18
    li   $a1, 11
    jal  draw_unit
    li   $a0, 16
    li   $a1, 12
    jal  draw_unit
    li   $a0, 17
    li   $a1, 12
    jal  draw_unit
    li   $a0, 18
    li   $a1, 12
    jal  draw_unit

    # E
    li   $a0, 20
    li   $a1, 8
    jal  draw_unit
    li   $a0, 21
    li   $a1, 8
    jal  draw_unit
    li   $a0, 22
    li   $a1, 8
    jal  draw_unit
    li   $a0, 20
    li   $a1, 9
    jal  draw_unit
    li   $a0, 20
    li   $a1, 10
    jal  draw_unit
    li   $a0, 21
    li   $a1, 10
    jal  draw_unit
    li   $a0, 22
    li   $a1, 10
    jal  draw_unit
    li   $a0, 20
    li   $a1, 11
    jal  draw_unit
    li   $a0, 20
    li   $a1, 12
    jal  draw_unit
    li   $a0, 21
    li   $a1, 12
    jal  draw_unit
    li   $a0, 22
    li   $a1, 12
    jal  draw_unit

    # D
    li   $a0, 24
    li   $a1, 8
    jal  draw_unit
    li   $a0, 25
    li   $a1, 8
    jal  draw_unit
    li   $a0, 24
    li   $a1, 9
    jal  draw_unit
    li   $a0, 26
    li   $a1, 9
    jal  draw_unit
    li   $a0, 24
    li   $a1, 10
    jal  draw_unit
    li   $a0, 26
    li   $a1, 10
    jal  draw_unit
    li   $a0, 24
    li   $a1, 11
    jal  draw_unit
    li   $a0, 26
    li   $a1, 11
    jal  draw_unit
    li   $a0, 24
    li   $a1, 12
    jal  draw_unit
    li   $a0, 25
    li   $a1, 12
    jal  draw_unit

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Move column left with wall / gem collision
##############################################################################
move_left:
    addi $sp, $sp, -8
    sw   $ra, 0($sp)
    sw   $s1, 4($sp)

    lw   $t1, active_x
    lw   $t2, left_bound
    beq  $t1, $t2, move_left_done

    addi $s1, $t1, -1

    move $a0, $s1
    lw   $a1, active_y
    jal  board_cell_occupied
    bne  $v0, $zero, move_left_done

    move $a0, $s1
    lw   $t4, active_y
    addi $a1, $t4, 1
    jal  board_cell_occupied
    bne  $v0, $zero, move_left_done

    move $a0, $s1
    lw   $t4, active_y
    addi $a1, $t4, 2
    jal  board_cell_occupied
    bne  $v0, $zero, move_left_done

    sw   $s1, active_x

move_left_done:
    lw   $s1, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 8
    jr   $ra

##############################################################################
# Move column right with wall / gem collision
##############################################################################
move_right:
    addi $sp, $sp, -8
    sw   $ra, 0($sp)
    sw   $s1, 4($sp)

    lw   $t1, active_x
    lw   $t2, right_bound
    beq  $t1, $t2, move_right_done

    addi $s1, $t1, 1

    move $a0, $s1
    lw   $a1, active_y
    jal  board_cell_occupied
    bne  $v0, $zero, move_right_done

    move $a0, $s1
    lw   $t4, active_y
    addi $a1, $t4, 1
    jal  board_cell_occupied
    bne  $v0, $zero, move_right_done

    move $a0, $s1
    lw   $t4, active_y
    addi $a1, $t4, 2
    jal  board_cell_occupied
    bne  $v0, $zero, move_right_done

    sw   $s1, active_x

move_right_done:
    lw   $s1, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 8
    jr   $ra

##############################################################################
# Move column down or lock it
##############################################################################
move_down:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  can_move_down
    beq  $v0, $zero, lock_active_and_spawn_new

    lw   $t1, active_y
    addi $t1, $t1, 1
    sw   $t1, active_y

    jal  can_move_down
    beq  $v0, $zero, lock_after_move
    j    move_down_done

lock_after_move:
    jal  store_active_column
    jal  resolve_board
    jal  top_row_occupied
    bne  $v0, $zero, game_over
    jal  spawn_next_column
    j    move_down_done

lock_active_and_spawn_new:
    lw   $t0, active_y
    li   $t1, 5
    slt  $t2, $t0, $t1
    bne  $t2, $zero, game_over

    jal  store_active_column
    jal  resolve_board
    jal  top_row_occupied
    bne  $v0, $zero, game_over
    jal  spawn_next_column
    j    move_down_done

game_over:
    jal  game_over_screen
    j    move_down_done

move_down_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Rotate active column colors
##############################################################################
rotate_column:
    lw   $t0, active_c1
    lw   $t1, active_c2
    lw   $t2, active_c3

    sw   $t2, active_c1
    sw   $t0, active_c2
    sw   $t1, active_c3
    jr   $ra

##############################################################################
# Check if active column can move down
# Returns v0 = 1 if yes, 0 if no
##############################################################################
can_move_down:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t0, active_y
    lw   $t1, bottom_bound
    beq  $t0, $t1, can_move_down_false

    lw   $a0, active_x
    addi $a1, $t0, 3
    jal  board_cell_occupied
    bne  $v0, $zero, can_move_down_false

    li   $v0, 1
    j    can_move_down_done

can_move_down_false:
    move $v0, $zero

can_move_down_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Store active column into board array
##############################################################################
store_active_column:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t1, active_y
    li   $t7, 5

    slt  $t6, $t1, $t7
    bne  $t6, $zero, skip_store_c1
    lw   $a0, active_x
    lw   $a1, active_y
    lw   $a2, active_c1
    jal  board_set_cell

skip_store_c1:
    lw   $t1, active_y
    addi $t2, $t1, 1
    slt  $t6, $t2, $t7
    bne  $t6, $zero, skip_store_c2
    lw   $a0, active_x
    move $a1, $t2
    lw   $a2, active_c2
    jal  board_set_cell

skip_store_c2:
    lw   $t1, active_y
    addi $t3, $t1, 2
    slt  $t6, $t3, $t7
    bne  $t6, $zero, skip_store_c3
    lw   $a0, active_x
    move $a1, $t3
    lw   $a2, active_c3
    jal  board_set_cell

skip_store_c3:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Make preview become active, then generate new preview
##############################################################################
spawn_next_column:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t0, spawn_x
    sw   $t0, active_x

    lw   $t1, spawn_y
    sw   $t1, active_y

    lw   $t2, preview_c1
    sw   $t2, active_c1

    lw   $t2, preview_c2
    sw   $t2, active_c2

    lw   $t2, preview_c3
    sw   $t2, active_c3

    jal  init_preview_column

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Returns 1 in v0 if board cell occupied, else 0
# Input: a0 = screen x, a1 = screen y
##############################################################################
board_cell_occupied:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t0, 5
    slt  $t1, $a1, $t0
    bne  $t1, $zero, board_cell_empty_above

    jal  board_get_address
    lw   $t0, 0($v0)
    sltu $v0, $zero, $t0
    j    board_cell_occupied_done

board_cell_empty_above:
    move $v0, $zero

board_cell_occupied_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Sets board cell
# Input: a0 = screen x, a1 = screen y, a2 = color
##############################################################################
board_set_cell:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  board_get_address
    sw   $a2, 0($v0)

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Gets address of board cell in v0
# Input: a0 = screen x, a1 = screen y
##############################################################################
board_get_address:
    addi $t0, $a0, -9
    addi $t1, $a1, -5

    li   $t2, 6
    mult $t1, $t2
    mflo $t3
    add  $t3, $t3, $t0
    sll  $t3, $t3, 2

    la   $t4, board_cells
    add  $v0, $t4, $t3
    jr   $ra

##############################################################################
# Returns 1 in v0 if any locked gem is in the top playable row, else 0
##############################################################################
top_row_occupied:
    li   $t0, 0
    li   $t1, 6
    la   $t2, board_cells

top_row_occupied_loop:
    sll  $t3, $t0, 2
    add  $t4, $t2, $t3
    lw   $t5, 0($t4)
    bne  $t5, $zero, top_row_occupied_true

    addi $t0, $t0, 1
    slt  $t6, $t0, $t1
    bne  $t6, $zero, top_row_occupied_loop

    move $v0, $zero
    jr   $ra

top_row_occupied_true:
    li   $v0, 1
    jr   $ra

##############################################################################
# Draw all locked gems from board array
##############################################################################
draw_locked_gems:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t0, 0

draw_locked_gems_outer:
    li   $t1, 0

draw_locked_gems_inner:
    li   $t2, 6
    mult $t0, $t2
    mflo $t3
    add  $t3, $t3, $t1
    sll  $t3, $t3, 2

    la   $t4, board_cells
    add  $t5, $t4, $t3
    lw   $t6, 0($t5)
    beq  $t6, $zero, skip_draw_locked_gem

    addi $a0, $t1, 9
    addi $a1, $t0, 5
    move $a2, $t6
    jal  draw_unit

skip_draw_locked_gem:
    addi $t1, $t1, 1
    slti $t7, $t1, 6
    bne  $t7, $zero, draw_locked_gems_inner

    addi $t0, $t0, 1
    slti $t7, $t0, 18
    bne  $t7, $zero, draw_locked_gems_outer

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Draw marked gems in white
##############################################################################
draw_marked_gems_white:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t0, 0

draw_marked_white_outer:
    li   $t1, 0

draw_marked_white_inner:
    li   $t2, 6
    mult $t0, $t2
    mflo $t3
    add  $t3, $t3, $t1
    sll  $t3, $t3, 2

    la   $t4, mark_cells
    add  $t5, $t4, $t3
    lw   $t6, 0($t5)
    beq  $t6, $zero, skip_draw_marked_white

    addi $a0, $t1, 9
    addi $a1, $t0, 5
    li   $a2, 0x00ffffff
    jal  draw_unit

skip_draw_marked_white:
    addi $t1, $t1, 1
    slti $t7, $t1, 6
    bne  $t7, $zero, draw_marked_white_inner

    addi $t0, $t0, 1
    slti $t7, $t0, 18
    bne  $t7, $zero, draw_marked_white_outer

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Redraw whole scene
##############################################################################
redraw_scene:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  clear_screen
    jal  draw_board
    jal  draw_locked_gems
    jal  draw_preview_column

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Flash matched gems
##############################################################################
flash_marked_gems:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  redraw_scene
    jal  draw_marked_gems_white
    li   $v0, 32
    li   $a0, 120
    syscall

    jal  redraw_scene
    li   $v0, 32
    li   $a0, 120
    syscall

    jal  redraw_scene
    jal  draw_marked_gems_white
    li   $v0, 32
    li   $a0, 120
    syscall

    jal  redraw_scene
    li   $v0, 32
    li   $a0, 80
    syscall

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Clear entire screen
##############################################################################
clear_screen:
    lw   $t0, bg_color
    li   $t1, 0
    li   $t2, 1024

clear_loop:
    sll  $t3, $t1, 2
    add  $t3, $s0, $t3
    sw   $t0, 0($t3)

    addi $t1, $t1, 1
    slt  $t4, $t1, $t2
    bne  $t4, $zero, clear_loop

    jr   $ra

##############################################################################
# Initialize the drawing of the board
##############################################################################
draw_board:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t0, 8
    li   $t1, 15
    li   $t2, 4
    li   $t3, 23
    li   $t4, 0x00aaaaaa
    add  $t5, $t0, $zero

top_loop:
    move $a0, $t5
    move $a1, $t2
    move $a2, $t4
    jal  draw_unit

    beq  $t5, $t1, bottom_start
    addi $t5, $t5, 1
    j    top_loop

bottom_start:
    add  $t5, $t0, $zero

bottom_loop:
    move $a0, $t5
    move $a1, $t3
    move $a2, $t4
    jal  draw_unit

    beq  $t5, $t1, left_start
    addi $t5, $t5, 1
    j    bottom_loop

left_start:
    add  $t5, $t2, $zero

left_loop:
    move $a0, $t0
    move $a1, $t5
    move $a2, $t4
    jal  draw_unit

    beq  $t5, $t3, right_start
    addi $t5, $t5, 1
    j    left_loop

right_start:
    add  $t5, $t2, $zero

right_loop:
    move $a0, $t1
    move $a1, $t5
    move $a2, $t4
    jal  draw_unit

    beq  $t5, $t3, board_done
    addi $t5, $t5, 1
    j    right_loop

board_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Returns a random gem color in $v0
# Possible colors: red, orange, yellow, green, blue, purple
##############################################################################
get_random_color:
    addi $sp, $sp, -4
    sw   $a1, 0($sp)

    li   $v0, 42
    li   $a0, 0
    li   $a1, 7
    syscall

    lw   $a1, 0($sp)
    addi $sp, $sp, 4

    beq  $a0, 0, color_red
    beq  $a0, 1, color_orange
    beq  $a0, 2, color_yellow
    beq  $a0, 3, color_green
    beq  $a0, 4, color_blue
    beq  $a0, 5, color_purple
    beq $a0, 6, color_white

color_white:
    li   $v0, 0x00ffffff
    jr   $ra

color_red:
    li   $v0, 0x00ff0000
    jr   $ra

color_orange:
    li   $v0, 0x00ff7f00
    jr   $ra

color_yellow:
    li   $v0, 0x00ffff00
    jr   $ra

color_green:
    li   $v0, 0x0000ff00
    jr   $ra

color_blue:
    li   $v0, 0x000000ff
    jr   $ra

color_purple:
    li   $v0, 0x00800080
    jr   $ra

##############################################################################
# Draws active column, only visible parts
##############################################################################
draw_active_column:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    lw   $t0, active_x
    lw   $t1, active_y

    li   $t7, 5

    slt  $t6, $t1, $t7
    bne  $t6, $zero, skip_draw_active_c1
    lw   $a2, active_c1
    move $a0, $t0
    move $a1, $t1
    jal  draw_unit

skip_draw_active_c1:
    addi $t2, $t1, 1
    slt  $t6, $t2, $t7
    bne  $t6, $zero, skip_draw_active_c2
    lw   $a2, active_c2
    move $a0, $t0
    move $a1, $t2
    jal  draw_unit

skip_draw_active_c2:
    addi $t3, $t1, 2
    slt  $t6, $t3, $t7
    bne  $t6, $zero, skip_draw_active_c3
    lw   $a2, active_c3
    move $a0, $t0
    move $a1, $t3
    jal  draw_unit

skip_draw_active_c3:
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Draws 3 gems vertically outside the board
##############################################################################
draw_preview_column:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    li   $t0, 20

    lw   $a2, preview_c1
    move $a0, $t0
    li   $a1, 8
    jal  draw_unit

    lw   $a2, preview_c2
    move $a0, $t0
    li   $a1, 9
    jal  draw_unit

    lw   $a2, preview_c3
    move $a0, $t0
    li   $a1, 10
    jal  draw_unit

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

##############################################################################
# Draw one unit
##############################################################################
draw_unit:
    sll  $t8, $a1, 5
    add  $t8, $t8, $a0
    sll  $t8, $t8, 2
    add  $t8, $s0, $t8
    sw   $a2, 0($t8)
    jr   $ra

##############################################################################
# Restart Game
##############################################################################

game_over_screen:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  flash_game_over_text
    j    game_over_wait_input
    
flash_game_over_text:
    addi $sp, $sp, -8
    sw   $ra, 0($sp)
    sw   $s1, 4($sp)

    li   $s1, 4

flash_loop:
    jal  draw_game_over_screen
    li   $v0, 32
    li   $a0, 120
    syscall

    jal  clear_screen
    li   $v0, 32
    li   $a0, 120
    syscall

    addi $s1, $s1, -1
    bne  $s1, $zero, flash_loop

    jal  draw_game_over_screen

    lw   $s1, 4($sp)
    lw   $ra, 0($sp)
    addi $sp, $sp, 8
    jr   $ra

game_over_wait_input:
    lw   $t0, ADDR_KBRD
    lw   $t1, 0($t0)
    beq  $t1, $zero, game_over_wait_input

    lw   $t2, 4($t0)

    li   $t3, 0x31
    beq  $t2, $t3, game_over_retry

    li   $t3, 0x71
    beq  $t2, $t3, game_over_quit

    j    game_over_wait_input

game_over_retry:
    jal  restart_game
    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

game_over_quit:
    li   $v0, 10
    syscall

restart_game:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  select_difficulty
    jal  clear_board_array
    jal  clear_mark_array

    sw   $zero, gravity_counter
    sw   $zero, clear_count
    sw   $zero, score

    jal  init_active_column
    jal  init_preview_column

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra

draw_game_over_screen_red:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  clear_screen
    li   $a2, 0x00ff0000

draw_game_over_screen:
    addi $sp, $sp, -4
    sw   $ra, 0($sp)

    jal  clear_screen

    li   $a2, 0x00ffffff

    # G
    li   $a0, 4
    li   $a1, 6
    jal  draw_unit
    li   $a0, 5
    li   $a1, 6
    jal  draw_unit
    li   $a0, 6
    li   $a1, 6
    jal  draw_unit
    li   $a0, 4
    li   $a1, 7
    jal  draw_unit
    li   $a0, 4
    li   $a1, 8
    jal  draw_unit
    li   $a0, 6
    li   $a1, 8
    jal  draw_unit
    li   $a0, 4
    li   $a1, 9
    jal  draw_unit
    li   $a0, 6
    li   $a1, 9
    jal  draw_unit
    li   $a0, 4
    li   $a1, 10
    jal  draw_unit
    li   $a0, 5
    li   $a1, 10
    jal  draw_unit
    li   $a0, 6
    li   $a1, 10
    jal  draw_unit

    # A
    li   $a0, 8
    li   $a1, 6
    jal  draw_unit
    li   $a0, 9
    li   $a1, 6
    jal  draw_unit
    li   $a0, 10
    li   $a1, 6
    jal  draw_unit
    li   $a0, 8
    li   $a1, 7
    jal  draw_unit
    li   $a0, 10
    li   $a1, 7
    jal  draw_unit
    li   $a0, 8
    li   $a1, 8
    jal  draw_unit
    li   $a0, 9
    li   $a1, 8
    jal  draw_unit
    li   $a0, 10
    li   $a1, 8
    jal  draw_unit
    li   $a0, 8
    li   $a1, 9
    jal  draw_unit
    li   $a0, 10
    li   $a1, 9
    jal  draw_unit
    li   $a0, 8
    li   $a1, 10
    jal  draw_unit
    li   $a0, 10
    li   $a1, 10
    jal  draw_unit

    # M
    li   $a0, 12
    li   $a1, 6
    jal  draw_unit
    li   $a0, 14
    li   $a1, 6
    jal  draw_unit
    li   $a0, 16
    li   $a1, 6
    jal  draw_unit
    li   $a0, 12
    li   $a1, 7
    jal  draw_unit
    li   $a0, 13
    li   $a1, 7
    jal  draw_unit
    li   $a0, 15
    li   $a1, 7
    jal  draw_unit
    li   $a0, 16
    li   $a1, 7
    jal  draw_unit
    li   $a0, 12
    li   $a1, 8
    jal  draw_unit
    
    li   $a0, 16
    li   $a1, 8
    jal  draw_unit
    li   $a0, 12
    li   $a1, 9
    jal  draw_unit
    li   $a0, 16
    li   $a1, 9
    jal  draw_unit
    li   $a0, 12
    li   $a1, 10
    jal  draw_unit
    li   $a0, 16
    li   $a1, 10
    jal  draw_unit

    # E
    li   $a0, 18
    li   $a1, 6
    jal  draw_unit
    li   $a0, 19
    li   $a1, 6
    jal  draw_unit
    li   $a0, 20
    li   $a1, 6
    jal  draw_unit
    li   $a0, 18
    li   $a1, 7
    jal  draw_unit
    li   $a0, 18
    li   $a1, 8
    jal  draw_unit
    li   $a0, 19
    li   $a1, 8
    jal  draw_unit
    li   $a0, 20
    li   $a1, 8
    jal  draw_unit
    li   $a0, 18
    li   $a1, 9
    jal  draw_unit
    li   $a0, 18
    li   $a1, 10
    jal  draw_unit
    li   $a0, 19
    li   $a1, 10
    jal  draw_unit
    li   $a0, 20
    li   $a1, 10
    jal  draw_unit

    # O
    li   $a0, 8
    li   $a1, 14
    jal  draw_unit
    li   $a0, 9
    li   $a1, 14
    jal  draw_unit
    li   $a0, 10
    li   $a1, 14
    jal  draw_unit
    li   $a0, 8
    li   $a1, 15
    jal  draw_unit
    li   $a0, 10
    li   $a1, 15
    jal  draw_unit
    li   $a0, 8
    li   $a1, 16
    jal  draw_unit
    li   $a0, 10
    li   $a1, 16
    jal  draw_unit
    li   $a0, 8
    li   $a1, 17
    jal  draw_unit
    li   $a0, 10
    li   $a1, 17
    jal  draw_unit
    li   $a0, 8
    li   $a1, 18
    jal  draw_unit
    li   $a0, 9
    li   $a1, 18
    jal  draw_unit
    li   $a0, 10
    li   $a1, 18
    jal  draw_unit

    # V
    li   $a0, 12
    li   $a1, 14
    jal  draw_unit
    li   $a0, 16
    li   $a1, 14
    jal  draw_unit
    li   $a0, 12
    li   $a1, 15
    jal  draw_unit
    li   $a0, 16
    li   $a1, 15
    jal  draw_unit
    li   $a0, 12
    li   $a1, 16
    jal  draw_unit
    li   $a0, 16
    li   $a1, 16
    jal  draw_unit
    li   $a0, 13
    li   $a1, 17
    jal  draw_unit
    li   $a0, 15
    li   $a1, 17
    jal  draw_unit
    li   $a0, 14
    li   $a1, 18
    jal  draw_unit

    # E
    li   $a0, 18
    li   $a1, 14
    jal  draw_unit
    li   $a0, 19
    li   $a1, 14
    jal  draw_unit
    li   $a0, 20
    li   $a1, 14
    jal  draw_unit
    li   $a0, 18
    li   $a1, 15
    jal  draw_unit
    li   $a0, 18
    li   $a1, 16
    jal  draw_unit
    li   $a0, 19
    li   $a1, 16
    jal  draw_unit
    li   $a0, 20
    li   $a1, 16
    jal  draw_unit
    li   $a0, 18
    li   $a1, 17
    jal  draw_unit
    li   $a0, 18
    li   $a1, 18
    jal  draw_unit
    li   $a0, 19
    li   $a1, 18
    jal  draw_unit
    li   $a0, 20
    li   $a1, 18
    jal  draw_unit

    # R
    li   $a0, 22
    li   $a1, 14
    jal  draw_unit
    li   $a0, 23
    li   $a1, 14
    jal  draw_unit
    li   $a0, 24
    li   $a1, 14
    jal  draw_unit
    li   $a0, 22
    li   $a1, 15
    jal  draw_unit
    li   $a0, 24
    li   $a1, 15
    jal  draw_unit
    li   $a0, 22
    li   $a1, 16
    jal  draw_unit
    li   $a0, 23
    li   $a1, 16
    jal  draw_unit
    li   $a0, 24
    li   $a1, 16
    jal  draw_unit
    li   $a0, 22
    li   $a1, 17
    jal  draw_unit
    li   $a0, 24
    li   $a1, 17
    jal  draw_unit
    li   $a0, 22
    li   $a1, 18
    jal  draw_unit
    li   $a0, 24
    li   $a1, 18
    jal  draw_unit

    lw   $ra, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
    
##############################################################################
# Draw one digit at (a0, a1)
# Input:
#   a0 = x
#   a1 = y
#   a2 = digit (0-9)
##############################################################################
draw_digit:
    addi $sp, $sp, -12
    sw   $ra, 0($sp)
    sw   $a0, 4($sp)
    sw   $a1, 8($sp)

    li   $t0, 0x00ffffff

    beq  $a2, 0, draw_digit_0
    beq  $a2, 1, draw_digit_1
    beq  $a2, 2, draw_digit_2
    beq  $a2, 3, draw_digit_3
    beq  $a2, 4, draw_digit_4
    beq  $a2, 5, draw_digit_5
    beq  $a2, 6, draw_digit_6
    beq  $a2, 7, draw_digit_7
    beq  $a2, 8, draw_digit_8
    beq  $a2, 9, draw_digit_9
    j    draw_digit_done

draw_digit_0:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    j    draw_digit_done

draw_digit_1:
    lw   $a0, 4($sp)        # base x
    addi $a0, $a0, 1        # x + 1 (center column)

    lw   $a1, 8($sp)        # base y
    move $a2, $t0
    jal  draw_unit

    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit

    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit

    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit

    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit

    j    draw_digit_done

draw_digit_2:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    j    draw_digit_done

draw_digit_3:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit

    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    j    draw_digit_done

draw_digit_4:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    j    draw_digit_done

draw_digit_5:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    j    draw_digit_done

draw_digit_6:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    j    draw_digit_done

draw_digit_7:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    j    draw_digit_done

draw_digit_8:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    j    draw_digit_done

draw_digit_9:
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 1
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 2
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 3
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 1
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit
    lw   $a0, 4($sp)
    addi $a0, $a0, 2
    lw   $a1, 8($sp)
    addi $a1, $a1, 4
    move $a2, $t0
    jal  draw_unit

draw_digit_done:
    lw   $ra, 0($sp)
    addi $sp, $sp, 12
    jr   $ra
    
##############################################################################
# Draw 4-digit score in top-left area
##############################################################################
draw_score:
    addi $sp, $sp, -24
    sw   $ra, 0($sp)

    lw   $t0, score

    li   $t1, 1000
    div  $t0, $t1
    mflo $t2
    mfhi $t0
    sw   $t2, 4($sp)        # thousands

    li   $t1, 100
    div  $t0, $t1
    mflo $t2
    mfhi $t0
    sw   $t2, 8($sp)        # hundreds

    li   $t1, 10
    div  $t0, $t1
    mflo $t2
    mfhi $t3
    sw   $t2, 12($sp)       # tens
    sw   $t3, 16($sp)       # ones

    li   $a0, 17
    li   $a1, 26
    lw   $a2, 4($sp)
    jal  draw_digit

    li   $a0, 21
    li   $a1, 26
    lw   $a2, 8($sp)
    jal  draw_digit

    li   $a0, 25
    li   $a1, 26
    lw   $a2, 12($sp)
    jal  draw_digit

    li   $a0, 29
    li   $a1, 26
    lw   $a2, 16($sp)
    jal  draw_digit

    lw   $ra, 0($sp)
    addi $sp, $sp, 24
    jr   $ra
    
##############################################################################
# Main game loop
##############################################################################
game_loop:
    jal  handle_input

    lw   $t0, gravity_counter
    addi $t0, $t0, 1
    sw   $t0, gravity_counter

    lw   $t1, gravity_threshold
    bne  $t0, $t1, skip_auto_gravity

    jal  move_down
    sw   $zero, gravity_counter

skip_auto_gravity:
    jal  clear_screen
    jal  draw_board
    jal  draw_locked_gems
    jal  draw_active_column
    jal  draw_preview_column
    jal  draw_score

    li   $v0, 32
    li   $a0, 16
    syscall

    j    game_loop