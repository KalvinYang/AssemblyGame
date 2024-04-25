#####################################################################
#
# CSCB58 Winter 2024 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Kevin Jang, 1008104775, jangkevi, kevin.jang@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 128 (update this as needed)
# - Display height in pixels: 128 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 4
#
# Which approved features have been implemented for milestone 4?
# (See the assignment handout for the list of additional features)
# 1. Moving Objects/Enemies
# 2. Different Levels (3 Total)
# 3. Start Menu + Lose/Win Screens
# ... (add more if necessary)
#
# Link to video demonstration for final submission:
# - (https://youtu.be/3C0soGYfEY4). Make sure we can view it!
#
# Are you OK with us sharing the video with people outside course staff?
# - yes
#
# Any additional information that the TA needs to know:
# - In my sleep deprived state when starting and during this project,
# - I missed that 64 units x 64 units is not the same as 64 pixel x 64 pixels
# - by the time I realized my mistake the project was nearing the final stages
# - and I wouldn't have time to remake the entire thing in 64x64.
# - I ask you please at least consider all the other work put into this.
# - Thank you, I hope you enjoy this little game, even a little. :)
#
#####################################################################

# $t0 : Used for display address
# $t1 : Color/Temp holder
# $t2 : Color/Temp holder
# $t3 : Color/Temp holder
# $t4 : Iterator
# $t5 : Word size
# $t6 : Color/Temp holder
# $t8 : Current Level
# $t9 : Input

.data
MONSTER_LOCATIONS: 	.word	0, 0, 0
PLAYER_LOCATION:	.word	0

# Debugging prints
hold:	 .asciiz "holding"
newline: .asciiz "\n"

# Locations
.eqv	BASE_ADDRESS	0x10008000
.eqv	INPUT		0xffff0000

.eqv	WAIT		20
.eqv	GREEN		0x00ff00
.eqv	BLUE		0x0000ff
.eqv	BLACK		0x000000
.eqv	TURQUOISE	0x00ffff
.eqv	HEART		0xe31b23

#Monster
.eqv	MONSTER		0x006400

#Player
.eqv	ARMOR		0x6a6a6a
.eqv	HELMET		0xd8d8d8
.eqv	GLOVE		0xffffff

#door
.eqv	YELLOW		0x00ffff00
.eqv	DIMYELLOW	0xe6cc00

#ladders
.eqv	ORANGE		0xffa500
.eqv	BROWN		0x964b00
.eqv	DARKBROWN	0x4b2d0b
.eqv	RUNG		0xbe7900

#lava colors
.eqv	RED		0xff0000
.eqv	MAGMA		0xeb4111
.eqv	DARKRED		0x8B0000
.eqv	DARKYELLOW	0xe6b400

.text
start:
	li $t0, BASE_ADDRESS # $t0 stores the base address for display
	li $t9, INPUT # $t9 stores the base address for keyboard input
	
	jal clear_screen # wipe screen
	
	li $t4, 1 # iterator
	li $t5, 4 # size of word
	li $t8, 0 # Current level
	
	jal homescreen # homescreen
	
load_header:
	jal header # make the header
	
load: #used to load next level
	beq $t8, 4, you_win
	
	jal make_map # make the map
	
	jal spawn_entity # spawn entities
gameloop:
	# sleep
	li $v0, 32
	li $a0, WAIT # sleep for WAIT time
	syscall
	
	# check for keypress
	jal check_keypress
	
	# only move_monsters when game is on a level
	blez $t8, neutral
	
	# move monsters
	jal move_monsters
	
	# Neautral
neutral:
	#loop
	j gameloop

# --------------- Header Section ------------
header:
	# Push this return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li $t4, 1 # reset iterator
	
	jal make_border_start # make the border for the header
	li $t4, 1 # reset iterator
	
	jal make_hearts_start # make the hearts appear
	li $t4, 1 # reset iterator
	
	jal make_letters_start # make the letters appear
	li $t4, 1 # reset iterator
	
	# Pop return address off stack
	lw $ra, 0($sp) 	
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra #return

make_border_start:
	# Push header return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t0, BASE_ADDRESS # locate origin
	
	# Color in first positon
	li $t1, BLUE # $t1 stores the blue colour code
	sw $t1, 0($t0) # Color in new bit
	sw $t1, 512($t0) # Color 9 rows down
	
make_border:
	# If on 32 loop, exit
	li $t1, 32
	beq $t4, $t1, make_border_sides
	
	# next bit
	mult $t4, $t5
	mflo $t6
	
	add $t0, $t0, $t6 # Move map pointer
	li $t1, BLUE # $t1 stores the blue colour code
	sw $t1, 0($t0) # Color in new bit
	sw $t1, 768($t0) # Color 5 rows down
	
	addi $t4, $t4, 1 # iteration += 1
	li $t0, BASE_ADDRESS # locate origin
	
	j make_border # jump back to the beginning of the loop
	
make_border_sides:
	# In addition to the previous loops
	# do 6 more to fill sides of the headbar, exit when done
	li $t1, 38
	beq $t4, $t1, exit_make_border
	
	addi $t0, $t0, 128 # move 1 row down
	li $t1, BLUE # $t1 stores the blue colour code
	sw $t1, 0($t0) # Color in new bit left side
	sw $t1, 124($t0) # Color in new bit right side
	
	addi $t4, $t4, 1 # iteration += 1
	
	j make_border_sides
	
exit_make_border:
	# Pop header return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return to make_header
	
make_hearts_start:
	# Push header return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $t0, $t0, 384 # Three lines down
	
make_hearts_loop:
	# Leave loop after 3 hearts
	li $t1, 4
	beq $t4, $t1, exit_make_hearts
	
	addi $t0, $t0, 16 # Four pixels over
	
	li $t1, HEART # $t1 stores the red colour code
	# Color heart
	sw $t1, 0($t0)
	sw $t1, -4($t0)
	sw $t1, 4($t0)
	sw $t1, -132($t0)
	sw $t1, -124($t0)
	sw $t1, 128($t0)
	
	addi $t4, $t4, 1 # iterator += 1
	
	j make_hearts_loop
	
exit_make_hearts:
	# Pop header return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return to header
	
make_letters_start:
	# Line up address for easier access
	addi $t0, $t0, 448 # 384 (Three lines down), 48 (12 pixels over), 16 (Additional 4 pixels over) 
	
	li $t1, RED # $t1 stores the red colour code
	# Color "- Lv |"
	#(-)
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	#(L)line 1 - 3
	sw $t1, -112($t0)
	sw $t1, 16($t0)
	sw $t1, 144($t0)
	sw $t1, 148($t0)
	#(v)line 1 - 3
	sw $t1, 28($t0)
	sw $t1, 36($t0)
	sw $t1, 160($t0)
	
	li $t1, YELLOW
	#(|) level indication line 1 - 3
	sw $t1, -84($t0)
	sw $t1, 44($t0)
	sw $t1, 172($t0)
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return to header
	
# -------------------------------------------
#--------- Game spawns ----------------------
make_map:
	# Push this return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t4, 0 # set iterator for this function
	li $t0, BASE_ADDRESS # locate origin
	jal make_lava_start # make lava
	li $t4, 0 # reset iterator
	
	li $t0, BASE_ADDRESS # locate origin
	jal make_walls_start # make walls
	li $t4, 0 # reset iterator
	
	li $t0, BASE_ADDRESS # locate origin
	jal make_platforms_start # make platforms
	li $t4, 0 # reset iterator
	
	li $t0, BASE_ADDRESS # locate origin
	jal make_door_start # make exit door
	li $t4, 0 # reset iterator
	
	li $t0, BASE_ADDRESS # locate origin
	jal make_ladder_start # make ladders
	li $t4, 0 # reset iterator
	
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra #return

#-------------------------

make_door_start:
	# Push make_map return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Door location level 1
	li $t1, 1
	beq $t8, $t1, make_door_1
	
	# Door location level 2
	li $t1, 2
	beq $t8, $t1, make_door_2
	
	# Door location level 3
	li $t1, 3
	beq $t8, $t1, make_door_3
	
	# No current level
	j exit_make_door

#Set location for exit door based on level
make_door_1:
	addi $t0, $t0, 1424 # row 11 + 4 pixels
	j make_door
	
make_door_2:
	addi $t0, $t0, 3620 # row 29 + 9 pixel
	j make_door

make_door_3:
	addi $t0, $t0, 1484 # row 11 + 4 pixels
	j make_door

make_door:
	li $t1, YELLOW #Color door center in yellow
	# Color in door
	sw $t1, 0($t0)
	sw $t1, -128($t0)
	
	li $t1, DIMYELLOW #Color border of door dimyellow
	# Color border of door dimyellow
	sw $t1, -4($t0)
	sw $t1, 4($t0)
	sw $t1, -132($t0)
	sw $t1, -124($t0)
	sw $t1, -256($t0)

exit_make_door:
	# Pop make_map return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return

#--------------------------

make_lava_start:
	# Push make_map return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t2, 0 # For keeping track of randomizer line
	addi $t0, $t0, 3840 # 31 * 128, second last line on display
make_lava:
	li $t1, 32 # 32 pixels
	beq $t4, $t1, exit_make_lava # exit if on 31st pixel
	
	j ml_rand # skip the line down
	
ml_last_line:
	addi $t0, $t0, 128 # move one line down

ml_rand:
	li $v0, 42 # Random number generator
	li $a1, 4 # upper bound 4
	syscall

	li $t1, 0 #option 1
	beq $a0, $t1, lava_op_1
	
	li $t1, 1 #option 2
	beq $a0, $t1, lava_op_2
	
	li $t1, 2 #option 3
	beq $a0, $t1, lava_op_3
	
	li $t1, 3 #option 4
	beq $a0, $t1, lava_op_4
	
lava_op_1:
	li $t1, RED # $t1 stores the red colour code
	j lava_op_after
lava_op_2:
	li $t1, MAGMA # $t1 stores the magma colour code
	j lava_op_after
lava_op_3:
	li $t1, DARKRED # $t1 stores the darkred colour code 
	j lava_op_after
lava_op_4:
	li $t1, DARKYELLOW # $t1 stores the darkyellow colour code
lava_op_after:
	sw $t1, 0($t0) # Color in pixel
	addi $t2, $t2, 1 # pass through once
	
	li $t1, 1
	beq $t2, $t1, ml_last_line # if first pass through, go again
	
	li $t2, 0 # reset for next loop
	add $t0, $t0, -124 # Move one pixel over
	addi $t4, $t4, 1 # increase iterator
	
	j make_lava # Loop
	
exit_make_lava:
	# Pop make_map return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return

#------------------------

make_walls_start:
	li $t0, BASE_ADDRESS # locate origin

	# Push header return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# set past header
	addi $t0, $t0, 896
	li $t4, 0
	
	# Print blue for walls
	li $t1, BLUE
	
	# set end of loop
	li $t2, 25
	
make_walls:
	# Exit loop after loop reaches the length desired
	beq $t4, $t2, exit_make_walls
	
	# Color sides
	sw $t1, 0($t0)
	sw $t1, 124($t0)
	
	addi $t0, $t0, 128
	addi $t4, $t4, 1
	
	j make_walls
	
exit_make_walls:
	# Pop make_map return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return


# Various ladders of each level
make_ladder_start:
	# Push make_map return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t0, BASE_ADDRESS # locate origin
	
	# Make ladders based on what the current level is
	li $t1, 1
	beq $t1, $t8, make_ladder_1
	li $t1, 2
	beq $t1, $t8, make_ladder_2
	li $t1, 3
	beq $t1, $t8, make_ladder_3
	
	# If not one of the cases above, then current level is an error, exit
	j exit_make_ladder
	
ml_print_start:
	# Push return platform onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Reset Iterator
	li $t4, 2
	
	# Print brown on initial
	li $t1, DARKBROWN
	
	# display color on initial platform
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	
	# one row up
	addi $t0, $t0, -128

ml_print:
	# load color in position
	lw $t1, 0($t0)
	
	# Platform Color check
	li $t2 BLUE
	# Exit loop after loop reaches platform
	beq $t1, $t2, ml_print_finish
	
	# Platform Color check
	li $t2 BROWN
	# Exit loop after loop reaches platform
	beq $t1, $t2, ml_print_finish
	
	# Print orange for ladder
	li $t1, ORANGE
	
	# display color
	sw $t1, 0($t0)
	sw $t1, 8($t0)
	
	# check $t4 mod 2
	andi $t1, $t4, 1
	blez $t1, rung
	
	# Color middle empty
	li $t1, BLACK
	sw $t1, 4($t0)
	
	j no_rung
	
rung:
	# Print orange for ladder
	li $t1, RUNG
	# display rung
	sw $t1, 4($t0)
	
no_rung:
	# iterator += 1
	addi $t4, $t4, 1
	
	# one row up
	addi $t0, $t0, -128
	
	# loop
	j ml_print
	
	
ml_print_finish:
	# One last bit of ladder
	li $t1, BROWN
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)

	# Pop platform return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
#---------------------- bottom to top order, right to left
make_ladder_1:
	addi $t0, $t0, 3756 # ladder 1 - row 30 + 1 pixel
	jal ml_print_start # color in
	
	addi $t0, $t0, 3008 # ladder 2 - row 24 + 8 pixels
	jal ml_print_start # color in
	
	addi $t0, $t0, 2340 # ladder 3 - row 19 + 12 pixels
	jal ml_print_start #color in
	
	j exit_make_ladder
	
make_ladder_2:
	addi $t0, $t0, 3728 # ladder 1
	jal ml_print_start # color in
	
	addi $t0, $t0, 3796 # ladder 2
	jal ml_print_start # color in
	
	addi $t0, $t0, 3016 # ladder 3
	jal ml_print_start #color in

	addi $t0, $t0, 2988 # ladder 4
	jal ml_print_start #color in
	
	j exit_make_ladder

make_ladder_3:
	addi $t0, $t0, 2788 # ladder 1
	jal ml_print_start # color in
	
	j exit_make_ladder

exit_make_ladder:
	# Pop make_map return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
#-----------------------

#Various platforms of each level
make_platforms_start:
	# Push make_map return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Make platforms based on what the current level is
	li $t1, 1
	beq $t1, $t8, make_platforms_1
	li $t1, 2
	beq $t1, $t8, make_platforms_2
	li $t1, 3
	beq $t1, $t8, make_platforms_3
	
	# If not one of the cases above, then current level is an error, exit
	j exit_make_platforms

# Make a platform, taking in $t2 as the length, assuming t0 is set to 0($t0) as beginning of the platform
mp_print_start:
	# Push return platform onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Reset iterator
	li $t4 0
	
	# Print blue for platform
	li $t1, BLUE
mp_print:
	# Exit loop after loop reaches the length desired
	beq $t4, $t2, mp_print_finish
	
	# display color
	sw $t1, 0($t0)
	
	# iterator += 1
	addi $t4, $t4, 1
	
	# one pixel to the right
	addi $t0, $t0, 4
	
	# loop
	j mp_print
	
mp_print_finish:
	# Pop platform return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
	
#-----------------------
make_platforms_1:
	# Line length
	li $t2, 14
	addi $t0, $t0, 3716 # platform 1 - row 30 + 1 pixel
	jal mp_print_start # color in
	
	# line length
	li $t2, 15
	addi $t0, $t0, 2960 # platform 2 - row 24 + 4 pixels
	jal mp_print_start # color in
	
	# line length
	li $t2, 17
	addi $t0, $t0, 2340 # platform 3 - row 19 + 12 pixels
	jal mp_print_start #color in
	
	# line length
	li $t2, 17
	addi $t0, $t0, 1536 # platform 4 - row 13
	jal mp_print_start #color in
	
	j exit_make_platforms

make_platforms_2:
	# Line length
	li $t2, 7
	addi $t0, $t0, 3728 # platform 1 - row 30 + 4 pixel
	jal mp_print_start # color in
	
	# line length
	li $t2, 7
	addi $t0, $t0, 3796 # platform 2 - row 30 + 21 pixels
	jal mp_print_start # color in
	
	# line length
	li $t2, 24
	addi $t0, $t0, 2960 # platform 3 - row 24 + 4 pixels
	jal mp_print_start #color in

	# line length
	li $t2, 19
	addi $t0, $t0, 2332 # platform 4 - row 19 + 7 pixels
	jal mp_print_start #color in
	
	j exit_make_platforms

make_platforms_3:
	# Line length
	li $t2, 12
	addi $t0, $t0, 1600 # platform 1
	jal mp_print_start # color in
	
	# line length
	li $t2, 24
	addi $t0, $t0, 2700 # platform 2
	jal mp_print_start # color in
	
	# line length
	li $t2, 9
	addi $t0, $t0, 2060 # platform 3
	jal mp_print_start #color in

	# line length
	li $t2, 6
	addi $t0, $t0, 1548 # platform 4
	jal mp_print_start #color in
	
	j exit_make_platforms

exit_make_platforms:
	# Pop make_map return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
#-----------------------
spawn_entity:
	# Push this return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	li $t4, 0 # set iterator for this function
	li $t0, BASE_ADDRESS # locate origin
	
	jal spawn_monster_start # spawn monsters of level
	li $t4, 0 # reset iterator
	
	jal spawn_character_start # spawn monsters of level
	li $t4, 0 # reset iterator
	
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra #return

#----------------

spawn_monster_start:
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#monsters on level 1
	li $t1, 1
	beq $t8, $t1, spawn_monster_1
	
	#monsters on level 2
	li $t1, 2
	beq $t8, $t1, spawn_monster_2
	
	#monsters on level 3
	li $t1, 3
	beq $t8, $t1, spawn_monster_3
	
	#no current level
	j exit_spawn_monster
	
spawn_monster:
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#monster color
	li $t1, MONSTER
	#body
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, -4($t0)
	#head
	sw $t1, -128($t0)
	#feet
	sw $t1, 132($t0)
	sw $t1, 124($t0)
	sw $t1, 128($t0)
	
	# random starting direction (eyes)
	li $v0, 42 # Random number generator
	li $a1, 2 # upper bound 2
	syscall
	
	# if got 0 from randomizer, then make eye on left
	# else on right
	li $t1, 0
	beq $a0, $t1, sm_eye_left
	
	# Eye on right
	li $t1, MONSTER
	sw $t1, -132($t0)
	li $t1, RED
	sw $t1, -124($t0)
	
	j spawn_monster_finish
	
sm_eye_left:
	# Eye on left
	li $t1, RED
	sw $t1, -132($t0)
	li $t1, MONSTER
	sw $t1, -124($t0)
	
spawn_monster_finish:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
	
#monsters of each level
spawn_monster_1:
	addi $t0, $t0, 2744 # line 10 + 15 pixels
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, 2744 # save location of middle pixel
	sw $t2, 8($t1) # move location into last index of array
	jal spawn_monster # spawn monster
	
	addi $t0, $t0, 2128 # line 16 + 20 pixels
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, 2128 # save location of middle pixel
	sw $t2, 4($t1) # move location into second index in array
	jal spawn_monster # spawn monster
	
	addi $t0, $t0, 1332 # line 10 + 10 pixels
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, 1332 # save location of middle pixel
	sw $t2, 0($t1) # move location into first index in array
	jal spawn_monster # spawn monster
	
	j exit_spawn_monster

spawn_monster_2:
	addi $t0, $t0, 2720 # location
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, 2720 # save location of middle pixel
	sw $t2, 8($t1) # move location into last index of array
	jal spawn_monster # spawn monster
	
	addi $t0, $t0, 2128 # location
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, 2128 # save location of middle pixel
	sw $t2, 4($t1) # move location into second index in array
	jal spawn_monster # spawn monster
	
	addi $t0, $t0, 2780 # location
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, 2780 # save location of middle pixel
	sw $t2, 0($t1) # move location into first index in array
	jal spawn_monster # spawn monster
	
	j exit_spawn_monster
	
spawn_monster_3:
	#no monster
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, -1 # save location of middle pixel
	sw $t2, 8($t1) # move location into last index of array
	
	addi $t0, $t0, 2460 # location
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, 2460 # save location of middle pixel
	sw $t2, 4($t1) # move location into second index in array
	jal spawn_monster # spawn monster
	
	addi $t0, $t0, 1820 # location
	la $t1, MONSTER_LOCATIONS # load address of where monster_locations are saved
	li $t2, 1820 # save location of middle pixel
	sw $t2, 0($t1) # move location into first index in array
	jal spawn_monster # spawn monster
	
	j exit_spawn_monster

exit_spawn_monster:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
	
#monster movement---
shift_monster:
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	#monster color
	li $t1, MONSTER
	#body
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, -4($t0)
	#head
	sw $t1, -128($t0)
	#feet
	sw $t1, 132($t0)
	sw $t1, 124($t0)
	sw $t1, 128($t0)
	
	# if got 0 from $t6, then make eye on left
	# else on right
	li $t1, 0
	beq $t6, $t1, shm_eye_left
	
	# Eye on right
	li $t1, MONSTER
	sw $t1, -132($t0)
	li $t1, RED
	sw $t1, -124($t0)
	
	j shift_monster_finish
	
shm_eye_left:
	# Eye on left
	li $t1, RED
	sw $t1, -132($t0)
	li $t1, MONSTER
	sw $t1, -124($t0)
	
shift_monster_finish:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return

move_monsters:
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

move_monsters_1:
	li $t0, BASE_ADDRESS # locate origin

	# Find monster 1
	la $t1, MONSTER_LOCATIONS
	lw $t2, 0($t1)
	
	# skip to next monster if -1 (not exist)
	li $t3, -1
	beq $t2, $t3, move_monsters_2
	
	# Move $t0 to point to monster
	add $t0, $t0, $t2
	
	# check facing direction and set
	li $t3, RED
	lw $t6, -132($t0)
	beq $t3, $t6, mm1_left
	
	#check if near edge
	lw $t3, 264($t0)
	li $t6, BLACK
	beq $t3, $t6, mm1_face_left
	
	#check if near door or near wall
	lw $t3, 8($t0)
	li $t6, DIMYELLOW
	beq $t3, $t6, mm1_face_left
	li $t6, BLUE
	beq $t3, $t6, mm1_face_left
	lw $t3, 264($t0)
	li $t6, DARKBROWN
	beq $t3, $t6, mm1_face_left
	
	#Delete remnant colors
	li $t6, BLACK
	sw $t6, -4($t0)
	sw $t6, -132($t0)
	sw $t6, 124($t0)
	
	addi $t0, $t0, 4 # move right
	addi $t2, $t2, 4 # move pixel over
	# Save monster location
	la $t1, MONSTER_LOCATIONS
	sw $t2, 0($t1)
	
	# Check if there's a player in the way
	li $t6, GLOVE
	lw $t3, 4($t0)
	beq $t6, $t3, lose_heart
	li $t6, ARMOR
	beq $t6, $t3, lose_heart
	
	li $t6, 1 # face right
	
	jal shift_monster # color in
	j move_monsters_2 # next monster
mm1_face_left:
	li $t6, 0 # face left
	jal shift_monster # color in
	j move_monsters_2 # next monster
mm1_left:
	#check if near edge
	lw $t3, 248($t0)
	li $t6, BLACK
	beq $t3, $t6, mm1_face_right
	
	#check if near door or near wall
	lw $t3, -8($t0)
	li $t6, DIMYELLOW
	beq $t3, $t6, mm1_face_right
	li $t6, BLUE
	beq $t3, $t6, mm1_face_right
	lw $t3, 248($t0)
	li $t6, DARKBROWN
	beq $t3, $t6, mm1_face_right
	
	#Delete remnant colors
	li $t6, BLACK
	sw $t6, 4($t0)
	sw $t6, 132($t0)
	sw $t6, -124($t0)
	
	addi $t0, $t0, -4 # move left
	addi $t2, $t2, -4 # move pixel over
	# Save monster location
	la $t1, MONSTER_LOCATIONS
	sw $t2, 0($t1)
	
	# Check if there's a player in the way
	li $t6, GLOVE
	lw $t3, -4($t0)
	beq $t6, $t3, lose_heart
	li $t6, ARMOR
	beq $t6, $t3, lose_heart
	
	li $t6, 0 # face left
	
	jal shift_monster # color in
	j move_monsters_2 # next monster
mm1_face_right:
	li $t6, 1 # face right
	jal shift_monster # color in
	j move_monsters_2 # next monster

move_monsters_2:
	li $t0, BASE_ADDRESS # locate origin

	# Find monster 2
	la $t1, MONSTER_LOCATIONS
	lw $t2, 4($t1)
	
	# skip to next monster if -1 (not exist)
	li $t3, -1
	beq $t2, $t3, move_monsters_3
	
	# Move $t0 to point to monster
	add $t0, $t0, $t2
	
	# check facing direction and set
	li $t3, RED
	lw $t6, -132($t0)
	beq $t3, $t6, mm2_left
	
	#check if near edge
	lw $t3, 264($t0)
	li $t6, BLACK
	beq $t3, $t6, mm2_face_left
	
	#check if near door or near wall
	lw $t3, 8($t0)
	li $t6, DIMYELLOW
	beq $t3, $t6, mm2_face_left
	li $t6, BLUE
	beq $t3, $t6, mm2_face_left
	lw $t3, 264($t0)
	li $t6, DARKBROWN
	beq $t3, $t6, mm2_face_left
		
	#Delete remnant colors
	li $t6, BLACK
	sw $t6, -4($t0)
	sw $t6, -132($t0)
	sw $t6, 124($t0)
	
	addi $t0, $t0, 4 # move right
	addi $t2, $t2, 4 # move pixel over
	# Save monster location
	la $t1, MONSTER_LOCATIONS
	sw $t2, 4($t1)
	
	# Check if there's a player in the way
	li $t6, GLOVE
	lw $t3, 4($t0)
	beq $t6, $t3, lose_heart
	li $t6, ARMOR
	beq $t6, $t3, lose_heart
	
	li $t6, 1 # face right
	
	jal shift_monster # color in
	j move_monsters_3 # next monster
mm2_face_left:
	li $t6, 0 # face left
	jal shift_monster # color in
	j move_monsters_3 # next monster
mm2_left:
	#check if near edge
	lw $t3, 248($t0)
	li $t6, BLACK
	beq $t3, $t6, mm2_face_right
	
	#check if near door or near wall
	lw $t3, -4($t0)
	li $t6, DIMYELLOW
	beq $t3, $t6, mm2_face_right
	li $t6, BLUE
	beq $t3, $t6, mm2_face_right
	lw $t3, 248($t0)
	li $t6, DARKBROWN
	beq $t3, $t6, mm2_face_right
	
	#Delete remnant colors
	li $t6, BLACK
	sw $t6, 4($t0)
	sw $t6, 132($t0)
	sw $t6, -124($t0)
	
	addi $t0, $t0, -4 # move left
	addi $t2, $t2, -4 # move pixel over
	# Save monster location
	la $t1, MONSTER_LOCATIONS
	sw $t2, 4($t1)
	
	# Check if there's a player in the way
	li $t6, GLOVE
	lw $t3, -4($t0)
	beq $t6, $t3, lose_heart
	li $t6, ARMOR
	beq $t6, $t3, lose_heart
	
	li $t6, 0 # face left
	
	jal shift_monster # color in
	j move_monsters_3 # next monster
mm2_face_right:
	li $t6, 1 # face right
	jal shift_monster # color in
	j move_monsters_3 # next monster
	
move_monsters_3:
	li $t0, BASE_ADDRESS # locate origin
	
	# Find monster 3
	la $t1, MONSTER_LOCATIONS
	lw $t2, 8($t1)
	
	# skip to next monster if -1 (not exist)
	li $t3, -1
	beq $t2, $t3, exit_move_monsters
	
	# Move $t0 to point to monster
	add $t0, $t0, $t2
	
	# check facing direction and set
	li $t3, RED
	lw $t6, -132($t0)
	beq $t3, $t6, mm3_left
	
	#check if near edge
	lw $t3, 264($t0)
	li $t6, BLACK
	beq $t3, $t6, mm3_face_left
	
	#check if near door or near wall or near ladder
	lw $t3, 8($t0)
	li $t6, DIMYELLOW
	beq $t3, $t6, mm3_face_left
	li $t6, BLUE
	beq $t3, $t6, mm3_face_left
	lw $t3, 264($t0)
	li $t6, DARKBROWN
	beq $t3, $t6, mm3_face_left

	#Delete remnant colors
	li $t6, BLACK
	sw $t6, -4($t0)
	sw $t6, -132($t0)
	sw $t6, 124($t0)
	
	addi $t0, $t0, 4 # move right
	addi $t2, $t2, 4 # move pixel over
	# Save monster location
	la $t1, MONSTER_LOCATIONS
	sw $t2, 8($t1)
	
	# Check if there's a player in the way
	li $t6, GLOVE
	lw $t3, 4($t0)
	beq $t6, $t3, lose_heart
	li $t6, ARMOR
	beq $t6, $t3, lose_heart
	
	li $t6, 1 # face right
	
	jal shift_monster # color in
	j exit_move_monsters# next monster
mm3_face_left:
	li $t6, 0 # face left
	jal shift_monster # color in
	j exit_move_monsters # next monster
mm3_left:
	#check if near edge
	lw $t3, 248($t0)
	li $t6, BLACK
	beq $t3, $t6, mm3_face_right
	
	#check if near door or near wall or ladder
	lw $t3, -8($t0)
	li $t6, DIMYELLOW
	beq $t3, $t6, mm3_face_right
	li $t6, BLUE
	beq $t3, $t6, mm3_face_right
	lw $t3, 248($t0)
	li $t6, DARKBROWN
	beq $t3, $t6, mm3_face_right
	
	#Delete remnant colors
	li $t6, BLACK
	sw $t6, 4($t0)
	sw $t6, 132($t0)
	sw $t6, -124($t0)
	
	addi $t0, $t0, -4 # move left
	addi $t2, $t2, -4 # move pixel over
	# Save monster location
	la $t1, MONSTER_LOCATIONS
	sw $t2, 8($t1)
	
	# Check if there's a player in the way
	li $t6, GLOVE
	lw $t3, -4($t0)
	beq $t6, $t3, lose_heart
	li $t6, ARMOR
	beq $t6, $t3, lose_heart
	
	li $t6, 0 # face left
	
	jal shift_monster # color in
	j exit_move_monsters # next monster
mm3_face_right:
	li $t6, 1 # face right
	jal shift_monster # color in
	j exit_move_monsters # next monster
	
exit_move_monsters:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return

#--------------------

spawn_character_start:
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#spawnpoint on level 1
	li $t1, 1
	beq $t8, $t1, spawn_character_1
	
	#spawnpoint on level 2
	li $t1, 2
	beq $t8, $t1, spawn_character_2
	
	#spawnpoint on level 3
	li $t1, 3
	beq $t8, $t1, spawn_character_3
	
	#no current level
	j exit_spawn_character
	
spawn_character:
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	#character body and feet color
	li $t1, ARMOR
	#body
	sw $t1, 0($t0)
	sw $t1, 132($t0)
	sw $t1, 128($t0)
	sw $t1, 124($t0)
	
	#character helmet color
	li $t1, HELMET
	#helmet
	sw $t1, -124($t0)
	sw $t1, -128($t0)
	sw $t1, -132($t0)
	
	# Check which way to face
	li $t1, 1
	beq $t3, $t1, face_right
	
	li $t1, ARMOR # set color
	#character glove/sword color
	sw $t1, 4($t0)
	
	li $t1, GLOVE # set color
	#glove/sword
	sw $t1, -4($t0)
	
	j spawn_character_finish
	
face_right:
	li $t1, ARMOR # set color
	#character glove/sword color
	sw $t1, -4($t0)
	
	li $t1, GLOVE # set color
	#glove/sword
	sw $t1, 4($t0)

spawn_character_finish:	
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
	
#character spawn of each level
spawn_character_1:
	li $t0, BASE_ADDRESS # locate origin
	la $t1, PLAYER_LOCATION # load address of where monster_locations are saved

	addi $t0, $t0, 3468 # line 28 + 3 pixels
	li $t2, 3468 # save location of middle pixel
	sw $t2, 0($t1) # move location into array

	li $t3, 1 # set character facing right
	jal spawn_character # spawn player
	
	j exit_spawn_character

spawn_character_2:
	li $t0, BASE_ADDRESS # locate origin
	la $t1, PLAYER_LOCATION # load address of where monster_locations are saved

	addi $t0, $t0, 3552 # line 28 + 24 pixels
	li $t2, 3552 # save location of middle pixel
	sw $t2, 0($t1) # move location into array

	li $t3, 1 # set character facing right
	jal spawn_character # spawn player
	
	j exit_spawn_character
	
spawn_character_3:

	li $t0, BASE_ADDRESS # locate origin
	la $t1, PLAYER_LOCATION # load address of where monster_locations are saved

	addi $t0, $t0, 1300 # line 28 + 24 pixels
	li $t2, 1300 # save location of middle pixel
	sw $t2, 0($t1) # move location into array

	li $t3, 1 # set character facing right
	jal spawn_character # spawn player
	
	j exit_spawn_character

exit_spawn_character:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return

#Inputs section-----------------------
check_keypress:
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Check if keypress has occured
	lw $t1, 0($t9)
	beq $t1, 1, keypress_happened
	
	# Keypress handled
	li $t1, 0
	sw $t1, 0($t9)
	
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra # return
	
keypress_happened:
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, 4($t9) # Take the input in
	
	# Handle each key pressed
	beq $t1, 0x71, q_pressed # to quit
	beq $t1, 0x72, r_pressed # restart
	
	# Check if a level or not
	ble $t8, 0, not_level
	beq $t1, 0x77, w_pressed # up ladders
	beq $t1, 0x61, a_pressed # move left
	beq $t1, 0x73, s_pressed # down ladders
	beq $t1, 0x64, d_pressed # move right

not_level:
	bltz $t8, not_home # other states besides home
	beq $t1, 0x62, b_pressed # start the game
not_home:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra # return
#keys-----
#start the game
b_pressed:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	jal clear_screen # make screen black
	li $t8, 1
	j load_header

#Restart and quit
q_pressed:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	jal clear_screen # make screen black
	li $v0, 10 # terminate the program gracefully
	syscall
r_pressed:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	jal clear_screen # make screen black
	j start # restart game
	

#Up and down
w_pressed:
	li $t0, BASE_ADDRESS # locate origin

	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	
	# Move $t0 to point to player
	add $t0, $t0, $t2	
	
	# See if both feet are on ladder
	# see if right foot on ladder
	lw $t1, 252($t0)
	li $t3, DARKBROWN
	beq $t1, $t3, right_on
	
	j exit_w_pressed
right_on:
	# see if left foot on ladder
	lw $t1, 260($t0)
	li $t3, DARKBROWN
	beq $t1, $t3, up_start
	
	j exit_w_pressed
up_start:
	# Check direction
	lw $t1, -4($t0)
	li $t3, GLOVE
	
	# set direction
	beq $t1, $t3, u_left
	
	# facing right
	li $t6, 1
	j up
u_left:
	# facing left
	li $t6, 0
up:
	# $t2 holds player location, move 1 up
	addi $t2, $t2, -128
	addi $t0, $t0, -128
	
	# Save player location
	la $t1, PLAYER_LOCATION
	sw $t2, 0($t1)
	
	# add hit enemy
	
	# see if a foot is on the ladder and exit if so
	lw $t1, 256($t0)
	li $t3, BROWN
	beq $t1, $t3, spawn_up
	
	j up # loop
spawn_up:
	# redraw ladder
	li $t0, BASE_ADDRESS # locate origin
	jal make_ladder_start
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# touched enemy
	li $t3, MONSTER
	lw $t1, 4($t0)
	beq $t1, $t3, w_lose_heart
	lw $t1, -4($t0)
	beq $t1, $t3, w_lose_heart
	
	# facing direction
	move $t3, $t6
	
	#spawn character
	jal spawn_character
	j exit_w_pressed
	
w_lose_heart:
	jal lose_heart
exit_w_pressed:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	jr $ra # return
#---------
s_pressed:
	li $t0, BASE_ADDRESS # locate origin

	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# See if both feet are on ladder
	# see if right foot on ladder
	lw $t1, 260($t0)
	li $t3, BROWN
	beq $t1, $t3, left_on
	
	j exit_s_pressed
left_on:
	# see if left foot on ladder
	lw $t1, 252($t0)
	li $t3, BROWN
	beq $t1, $t3, down_start
	
	j exit_s_pressed
down_start:
	# Check direction
	lw $t1, -4($t0)
	li $t3, GLOVE
	
	# set direction
	beq $t1, $t3, d_left
	
	# facing right
	li $t6, 1
	j d_clear
d_left:
	# facing left
	li $t6, 0
d_clear:
	# Get rid of remnant colors
	li $t1, BLACK
	sw $t1, -132($t0)
	sw $t1, -128($t0)
	sw $t1, -124($t0)
	sw $t1, -4($t0)
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 124($t0)
	sw $t1, 128($t0)
	sw $t1, 132($t0)
down:
	# $t2 holds player location, move 1 down
	addi $t2, $t2, 128
	addi $t0, $t0, 128
	
	# Save player location
	la $t1, PLAYER_LOCATION
	sw $t2, 0($t1)
	
	# add hit enemy
	
	# see if a foot is on the ladder and exit if so
	lw $t1, 256($t0)
	li $t3, DARKBROWN
	beq $t1, $t3, spawn_down
	
	j down # loop
spawn_down:
	# facing direction
	move $t3, $t6
	
	# redraw ladder
	li $t0, BASE_ADDRESS # locate origin
	jal make_ladder_start
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	#spawn character
	jal spawn_character
	j exit_s_pressed
	
s_lose_heart:
	jal lose_heart
exit_s_pressed:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	jr $ra # return	

# Left and Right
a_pressed:
	li $t0, BASE_ADDRESS # locate origin
	
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2

	# Check if there's a monster in the way
	li $t1, MONSTER
	lw $t3, -8($t0)
	beq $t1, $t3, a_touch_monster
	
	#check if near door, proceed in game, or win
	li $t6, DIMYELLOW
	beq $t3, $t6, next_level
	
	# Check if there's a wall in the way
	li $t1, BLUE
	bne $t1, $t3, continue_left
	
	# Refresh wall
	jal make_walls_start
	j exit_a_pressed
	
continue_left:
	
	# $t2 holds player location, move one pixel left
	addi $t2, $t2, -4
	addi $t0, $t0, -4
	
	# Save player location
	la $t1, PLAYER_LOCATION
	sw $t2, 0($t1)
	
	# get rid of remnant colors
	li $t1, BLACK
	sw $t1, -120($t0)
	sw $t1, 8($t0)
	sw $t1, 136($t0)
	
	# if on a ladder, refresh otherwise skip
	li $t3, DARKBROWN
	lw $t6, 248($t0)
	beq $t3, $t6, a_refresh
	lw $t6, 264($t0)
	beq $t3, $t6, a_refresh
	
	j a_no_refresh
	
a_refresh:
	# redraw ladder
	li $t0, BASE_ADDRESS # locate origin
	jal make_ladder_start
	
a_no_refresh:
	li $t0, BASE_ADDRESS # locate origin
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# facing left
	li $t3, 0
	jal spawn_character
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# see if front foot is in the air, check other foot if so
	lw $t1, 260($t0)
	li $t3, BLACK
	bne $t1, $t3, exit_a_pressed
	
	#check other foot
	lw $t1, 252($t0)
	bne $t1, $t3, exit_a_pressed
	
	# In free fall
	jal fall_start
	# Did not touch monster
	j exit_a_pressed
	
a_touch_monster:
	#lose heart
	jal lose_heart
exit_a_pressed:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	jr $ra # return	

d_pressed:
	li $t0, BASE_ADDRESS # locate origin
	
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# Check if there's a monster in the way
	li $t1, MONSTER
	lw $t3, 8($t0)
	beq $t1, $t3, d_touch_monster
	
	#check if near door, proceed in game, or win
	li $t6, DIMYELLOW
	beq $t3, $t6, next_level
	
	# Check if there's a wall in the way
	li $t1, BLUE
	bne $t1, $t3, continue_right
	
	# Refresh wall
	jal make_walls_start
	j exit_d_pressed
continue_right:
	# add hit enemy
	
	# $t2 holds player location, move one pixel right
	addi $t2, $t2, 4
	addi $t0, $t0, 4
	
	# Save player location
	la $t1, PLAYER_LOCATION
	sw $t2, 0($t1)
	
	# Get rid of remnant colors
	li $t1, BLACK
	sw $t1, -136($t0)
	sw $t1, -8($t0)
	sw $t1, 120($t0)
	
	# if on a ladder, refresh otherwise skip
	li $t3, DARKBROWN
	lw $t6, 248($t0)
	beq $t3, $t6, d_refresh
	lw $t6, 264($t0)
	beq $t3, $t6, d_refresh
	
	j d_no_refresh

d_refresh:
	# redraw ladder
	li $t0, BASE_ADDRESS # locate origin
	jal make_ladder_start
d_no_refresh:
	li $t0, BASE_ADDRESS # locate origin
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# facing right
	li $t3, 1
	jal spawn_character
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# see if front foot is in the air, check other foot if so
	lw $t1, 252($t0)
	li $t3, BLACK
	bne $t1, $t3, exit_d_pressed
	
	#check other foot
	lw $t1, 260($t0)
	bne $t1, $t3, exit_d_pressed
	
	# In free fall
	jal fall_start
	
	#Did not touch monster
	j exit_d_pressed
d_touch_monster:
	#lose heart
	jal lose_heart
exit_d_pressed:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	jr $ra # return	
	

#---------

clear_screen:
	li $t0, BASE_ADDRESS # locate origin

	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# set color for screen
	li $t1, BLACK
	
	# set iterator for going through array
	li $t4, 0
	
	# set endpoint for loop to stop (pixel count)
	li $t2, 1024
clear_screen_loop:
	beq $t4, $t2, exit_clear_screen # exit condition
	
	sw $t1, 0($t0) # color in pixel
	
	addi $t4, $t4, 1 # iterator += 1
	addi $t0, $t0, 4 # next pixel
	
	j clear_screen_loop # loop
exit_clear_screen:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return

clear_game_area:
	li $t0, BASE_ADDRESS # locate origin

	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# set color for screen
	li $t1, BLACK
	
	# set iterator for going through array
	li $t4, 224
	
	# Skip Header
	addi $t0, $t0, 896
	
	# set endpoint for loop to stop (pixel count)
	li $t2, 1024
clear_ga_loop:
	beq $t4, $t2, exit_clear_ga # exit condition
	
	sw $t1, 0($t0) # color in pixel
	
	addi $t4, $t4, 1 # iterator += 1
	addi $t0, $t0, 4 # next pixel
	
	j clear_ga_loop # loop
exit_clear_ga:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
	

#--------------------

fall_start:
	li $t0, BASE_ADDRESS # locate origin
	
	# Push return onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# Check direction
	lw $t1, 4($t0)
	li $t3, GLOVE
	
	# set direction
	beq $t1, $t3, fall_right
	
	# Set facing left
	li $t6, 0
	
	j fall
fall_right:
	# Set facing right
	li $t6, 1
fall:
	li $t0, BASE_ADDRESS # locate origin
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# touched enemy
	li $t3, MONSTER
	lw $t1, 252($t0)
	beq $t1, $t3, fall_lose_heart
	lw $t1, 264($t0)
	beq $t1, $t3, fall_lose_heart
	lw $t1, 256($t0)
	beq $t1, $t3, fall_lose_heart
	lw $t1, 124($t0)
	beq $t1, $t3, fall_lose_heart
	lw $t1, 132($t0)
	beq $t1, $t3, fall_lose_heart
	
	# see if a foot is on the ground and exit if so
	li $t3, BLACK
	lw $t1, 252($t0)
	bne $t1, $t3, exit_fall
	lw $t1, 260($t0)
	bne $t1, $t3, exit_fall
	
	# $t2 holds player location, move 1 down
	addi $t2, $t2, 128
	addi $t0, $t0, 128
	
	# Remove remnant colors
	li $t1, BLACK
	sw $t1, -252($t0)
	sw $t1, -256($t0)
	sw $t1, -260($t0)
	
	# Save player location
	la $t1, PLAYER_LOCATION
	sw $t2, 0($t1)
	
	#set facing
	move $t3, $t6
	#spawn character
	jal spawn_character
	
	# player fell into lava
	li $t1, 3712
	addi $t3, $t2, 128
	bgt $t3, $t1, fall_lose_heart
	
	j fall # loop
fall_lose_heart:
	jal lose_heart
exit_fall:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	jr $ra # return
#-----------------

lose_heart:
	li $t0, BASE_ADDRESS # locate origin
	
	# Push header return address onto stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Find player location
	la $t1, PLAYER_LOCATION
	lw $t2, 0($t1)
	# Move $t0 to point to player
	add $t0, $t0, $t2
	
	# Delete player
	li $t1, BLACK
	
	# Remove remnant colors
	sw $t1, 0($t0)
	sw $t1, -4($t0)
	sw $t1, 4($t0)
	sw $t1, -128($t0)
	sw $t1, -132($t0)
	sw $t1, -124($t0)
	sw $t1, 128($t0)
	sw $t1, 124($t0)
	sw $t1, 132($t0)
	
	li $t0, BASE_ADDRESS # locate origin
	
	jal make_ladder_start # refresh ladder
	
	li $t1, HEART # $t1 stores the red colour code
	
	addi $t0, $t0, 432 # Three lines down + 12 pixels
	lw $t2, 0($t0) # check if heart is there
	beq $t1, $t2, exit_lose_heart
	
	addi $t0, $t0, -16 # check second heart
	lw $t2, 0($t0) # second heart location
	beq $t1, $t2, exit_lose_heart
	
	# Pop header return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	j you_lose

exit_lose_heart:
	# Delete Heart
	li $t1, BLACK

	# Color heart
	sw $t1, 0($t0)
	sw $t1, -4($t0)
	sw $t1, 4($t0)
	sw $t1, -132($t0)
	sw $t1, -124($t0)
	sw $t1, 128($t0)
	
	# respawn character
	jal spawn_character_start
	
	# Pop header return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	li $t0, BASE_ADDRESS # locate origin
	jr $ra # return
	
next_level:
	li $t0, BASE_ADDRESS # locate origin
	
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4
	
	jal clear_game_area
	
	addi $t0, $t0, 448 # 384 (Three lines down), 48 (12 pixels over)
	
	addi $t8, $t8, 1
	bne $t8, 2, l_3
	
	li $t1, TURQUOISE
	#(|) level indication line 1 - 3
	sw $t1, -80($t0)
	sw $t1, 48($t0)
	sw $t1, 176($t0)
	
	j loadtime
l_3:
	bne $t8, 3, loadtime
	li $t1, GLOVE
	#(|) level indication line 1 - 3
	sw $t1, -76($t0)
	sw $t1, 52($t0)
	sw $t1, 180($t0)
loadtime:
	j load

you_lose:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	li $t8 -1 # Non-level
	jal clear_screen # clear the screen
	
	addi $t0, $t0, 396 # offset 3 pixels down and 3 pixels right
	
	# Print game over
	li $t1, GLOVE
	# Line 1 - game
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 40($t0)
	sw $t1, 56($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	
	# Line 2 - game
	sw $t1, 128($t0)
	sw $t1, 148($t0)
	sw $t1, 160($t0)
	sw $t1, 168($t0)
	sw $t1, 172($t0)
	sw $t1, 180($t0)
	sw $t1, 184($t0)
	sw $t1, 192($t0)
	
	# Line 3 - game
	sw $t1, 256($t0)
	sw $t1, 264($t0)
	sw $t1, 268($t0)
	sw $t1, 276($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 288($t0)
	sw $t1, 296($t0)
	sw $t1, 304($t0)
	sw $t1, 312($t0)
	sw $t1, 320($t0)
	sw $t1, 324($t0)
	sw $t1, 328($t0)
	
	# Line 4 - game
	sw $t1, 384($t0)
	sw $t1, 396($t0)
	sw $t1, 404($t0)
	sw $t1, 416($t0)
	sw $t1, 424($t0)
	sw $t1, 440($t0)
	sw $t1, 448($t0)
	
	# Line 5 - game
	sw $t1, 512($t0)
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 524($t0)
	sw $t1, 532($t0)
	sw $t1, 544($t0)
	sw $t1, 552($t0)
	sw $t1, 568($t0)
	sw $t1, 576($t0)
	sw $t1, 580($t0)
	sw $t1, 584($t0)
	sw $t1, 588($t0)
	
	# down 6 pixels
	addi $t0, $t0, 768
	
	# Line 1 - over
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 24($t0)
	sw $t1, 40($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	
	# Line 2 - over
	sw $t1, 128($t0)
	sw $t1, 144($t0)
	sw $t1, 152($t0)
	sw $t1, 168($t0)
	sw $t1, 176($t0)
	sw $t1, 196($t0)
	sw $t1, 208($t0)
	
	# Line 3 - over
	sw $t1, 256($t0)
	sw $t1, 272($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 292($t0)
	sw $t1, 296($t0)
	sw $t1, 304($t0)
	sw $t1, 308($t0)
	sw $t1, 312($t0)
	sw $t1, 324($t0)
	sw $t1, 328($t0)
	sw $t1, 332($t0)
	sw $t1, 336($t0)
	
	# Line 4 - over
	sw $t1, 384($t0)
	sw $t1, 400($t0)
	sw $t1, 412($t0)
	sw $t1, 416($t0)
	sw $t1, 420($t0)
	sw $t1, 432($t0)
	sw $t1, 452($t0)
	sw $t1, 460($t0)
	
	# Line 5 - over
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 524($t0)
	sw $t1, 528($t0)
	sw $t1, 544($t0)
	sw $t1, 560($t0)
	sw $t1, 564($t0)
	sw $t1, 568($t0)
	sw $t1, 572($t0)
	sw $t1, 580($t0)
	sw $t1, 592($t0)
	
	# down 6 pixels
	addi $t0, $t0, 768
	
	# draw line
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	
	# down 2 pixels
	addi $t0, $t0, 256
	
	# restart
	# Line 1 - restart
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	
	# Line 2 - restart
	sw $t1, 156($t0)
	sw $t1, 168($t0)
	
	# Line 3 - restart
	sw $t1, 280($t0)
	sw $t1, 292($t0)
	sw $t1, 296($t0)
	sw $t1, 300($t0)
	sw $t1, 304($t0)
	sw $t1, 308($t0)
	
	# Line 4 - restart
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 396($t0)
	sw $t1, 400($t0)
	sw $t1, 408($t0)
	sw $t1, 424($t0)
	sw $t1, 428($t0)
	sw $t1, 432($t0)
	
	# Line 5 - restart
	sw $t1, 512($t0)
	sw $t1, 540($t0)
	sw $t1, 556($t0)
	
	# down 7 pixels
	addi $t0, $t0, 896
	
	#quit
	# Line 1 - quit
	sw $t1, 56($t0)
	sw $t1, 68($t0)
	
	# Line 2 - quit
	sw $t1, 192($t0)
	sw $t1, 196($t0)
	sw $t1, 200($t0)
	
	# Line 3 - quit
	sw $t1, 256($t0)
	sw $t1, 260($t0)
	sw $t1, 268($t0)
	sw $t1, 272($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 296($t0)
	sw $t1, 304($t0)
	sw $t1, 312($t0)
	sw $t1, 324($t0)
	
	# Line 4 - quit
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 408($t0)
	sw $t1, 412($t0)
	sw $t1, 424($t0)
	sw $t1, 428($t0)
	sw $t1, 432($t0)
	sw $t1, 440($t0)
	sw $t1, 452($t0)
	
	# Line 5 - quit
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 540($t0)
	sw $t1, 544($t0)
	
	# Line 6 - quit
	sw $t1, 644($t0)
	sw $t1, 668($t0)
	
	# go back to gameloop
	li $t0, BASE_ADDRESS # locate origin
	j gameloop
	
you_win:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	li $t8 -1 # Non-level
	jal clear_screen # clear the screen
	
	addi $t0, $t0, 396 # offset 3 pixels down and 3 pixels right
	
	# Print you win
	li $t1, GLOVE
	# Line 1 - you
	sw $t1, 0($t0)
	sw $t1, 16($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 48($t0)
	sw $t1, 64($t0)
	
	# Line 2 - you
	sw $t1, 132($t0)
	sw $t1, 140($t0)
	sw $t1, 152($t0)
	sw $t1, 168($t0)
	sw $t1, 176($t0)
	sw $t1, 192($t0)
	
	# Line 3 - you
	sw $t1, 264($t0)
	sw $t1, 280($t0)
	sw $t1, 296($t0)
	sw $t1, 304($t0)
	sw $t1, 320($t0)
	
	# Line 4 - you
	sw $t1, 392($t0)
	sw $t1, 408($t0)
	sw $t1, 424($t0)
	sw $t1, 432($t0)
	sw $t1, 448($t0)
	
	# Line 5 - you
	sw $t1, 520($t0)
	sw $t1, 536($t0)
	sw $t1, 540($t0)
	sw $t1, 544($t0)
	sw $t1, 548($t0)
	sw $t1, 564($t0)
	sw $t1, 568($t0)
	sw $t1, 572($t0)
	
	# down 6 pixels
	addi $t0, $t0, 768
	
	# Line 1 - win
	sw $t1, 0($t0)
	sw $t1, 16($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 48($t0)
	sw $t1, 64($t0)
	
	# Line 2 - win
	sw $t1, 128($t0)
	sw $t1, 144($t0)
	sw $t1, 160($t0)
	sw $t1, 176($t0)
	sw $t1, 180($t0)
	sw $t1, 192($t0)
	
	# Line 3 - win
	sw $t1, 256($t0)
	sw $t1, 264($t0)
	sw $t1, 272($t0)
	sw $t1, 288($t0)
	sw $t1, 304($t0)
	sw $t1, 312($t0)
	sw $t1, 320($t0)
	
	# Line 4 - win
	sw $t1, 384($t0)
	sw $t1, 392($t0)
	sw $t1, 400($t0)
	sw $t1, 416($t0)
	sw $t1, 432($t0)
	sw $t1, 444($t0)
	sw $t1, 448($t0)
	
	# Line 5 - win
	sw $t1, 516($t0)
	sw $t1, 524($t0)
	sw $t1, 536($t0)
	sw $t1, 540($t0)
	sw $t1, 544($t0)
	sw $t1, 548($t0)
	sw $t1, 552($t0)
	sw $t1, 560($t0)
	sw $t1, 576($t0)
	
	# down 6 pixels
	addi $t0, $t0, 768
	
	# draw line
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	sw $t1, 56($t0)
	sw $t1, 60($t0)
	sw $t1, 64($t0)
	sw $t1, 68($t0)
	sw $t1, 72($t0)
	sw $t1, 76($t0)
	sw $t1, 80($t0)
	
	# down 2 pixels
	addi $t0, $t0, 256
	
	# restart
	# Line 1 - restart
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	
	# Line 2 - restart
	sw $t1, 156($t0)
	sw $t1, 168($t0)
	
	# Line 3 - restart
	sw $t1, 280($t0)
	sw $t1, 292($t0)
	sw $t1, 296($t0)
	sw $t1, 300($t0)
	sw $t1, 304($t0)
	sw $t1, 308($t0)
	
	# Line 4 - restart
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 396($t0)
	sw $t1, 400($t0)
	sw $t1, 408($t0)
	sw $t1, 424($t0)
	sw $t1, 428($t0)
	sw $t1, 432($t0)
	
	# Line 5 - restart
	sw $t1, 512($t0)
	sw $t1, 540($t0)
	sw $t1, 556($t0)
	
	# down 7 pixels
	addi $t0, $t0, 896
	
	#quit
	# Line 1 - quit
	sw $t1, 56($t0)
	sw $t1, 68($t0)
	
	# Line 2 - quit
	sw $t1, 192($t0)
	sw $t1, 196($t0)
	sw $t1, 200($t0)
	
	# Line 3 - quit
	sw $t1, 256($t0)
	sw $t1, 260($t0)
	sw $t1, 268($t0)
	sw $t1, 272($t0)
	sw $t1, 280($t0)
	sw $t1, 284($t0)
	sw $t1, 296($t0)
	sw $t1, 304($t0)
	sw $t1, 312($t0)
	sw $t1, 324($t0)
	
	# Line 4 - quit
	sw $t1, 384($t0)
	sw $t1, 388($t0)
	sw $t1, 408($t0)
	sw $t1, 412($t0)
	sw $t1, 424($t0)
	sw $t1, 428($t0)
	sw $t1, 432($t0)
	sw $t1, 440($t0)
	sw $t1, 452($t0)
	
	# Line 5 - quit
	sw $t1, 516($t0)
	sw $t1, 520($t0)
	sw $t1, 540($t0)
	sw $t1, 544($t0)
	
	# Line 6 - quit
	sw $t1, 644($t0)
	sw $t1, 668($t0)
	
	li $t0, BASE_ADDRESS # locate origin
	
	j gameloop

homescreen:
	# Pop return address off stack
	lw $ra, 0($sp)
	sw $zero, 0($sp)
	addi $sp, $sp, 4

	li $t0, BASE_ADDRESS # locate origin
	jal clear_screen # clear the screen
	
	addi $t0, $t0, 140 # offset 1 pixels down and 3 pixels right
	
	# Print you win
	li $t1, GLOVE
	
	#Lines
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 12($t0)
	sw $t1, 28($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 12($t0)
	sw $t1, 28($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	
	#next line
	addi $t0, $t0, 256
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 16($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 8($t0)
	sw $t1, 16($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 8($t0)
	sw $t1, 16($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 8($t0)
	sw $t1, 16($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 4($t0)
	sw $t1, 12($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 256
	
	#Lines
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 16($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 16($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 16($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 256
	
	#Lines
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 16($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 256
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 44($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 12($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 16($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 36($t0)
	sw $t1, 40($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	sw $t1, 52($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 12($t0)
	sw $t1, 44($t0)
	sw $t1, 48($t0)
	
	#next line
	addi $t0, $t0, 128
	
	#Lines
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 44($t0)
	
	li $t0, BASE_ADDRESS # locate origin
	j gameloop
#------------
	# sleep
#	li $v0, 32
#	li $a0, WAIT # sleep for WAIT time
#	syscall
	
	
