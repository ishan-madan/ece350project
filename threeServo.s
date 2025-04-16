# r0 = 0
# r1 is used to chek if servo button is pressed
# r2 is used as our 1 default to check servo
# r3 is servo 1 timer
# r4 is servo 2 timer
# r5 is servo 3 timer
# r6 is the duty cycle for servo 1
# r7 is the duty cycle for servo 2
# r8 is the duty cycle for servo 3

# mem address 7 is for servo 1 button
# mem address 8 is for servo 2 button
# mem address 9 is for servo 3 button

# mem address 11 is for servo 1 duty cycle 
# mem address 12 is for servo 2 duty cycle 
# mem address 13 is for servo 3 duty cycle 



check_buttons:
nop
nop

# checking if servo 1 button is pressed
bne $r3, $r0, servo_1_button_checked
nop
nop

j check_servo_1_button
nop
nop


servo_1_button_checked:
# check to see if there is still time left on the servo
bne $r3, $r0, subtract_servo_1_time
nop
nop

j turn_off_servo_1
nop
nop

servo_1_time_checked:
# checking if servo 2 button is pressed
bne $r4, $r0, servo_2_button_checked
nop
nop

j check_servo_2_button
nop
nop


servo_2_button_checked:
# check to see if there is still time left on the servo
bne $r4, $r0, subtract_servo_2_time
nop
nop

j turn_off_servo_2
nop
nop

servo_2_time_checked:
# checking if servo 3 button is pressed
bne $r5, $r0, servo_3_button_checked
nop
nop

j check_servo_3_button
nop
nop


servo_3_button_checked:
# check to see if there is still time left on the servo
bne $r5, $r0, subtract_servo_3_time
nop
nop

j turn_off_servo_3
nop
nop

servo_3_time_checked:


j check_buttons











# servo button checking code

# servo 1
check_servo_1_button:
nop
nop
lw $r1, 7($r0)
nop
nop
addi $r2, $r0, 1
nop
nop
bne $r1, $r2, servo_1_button_checked
nop
nop
j set_servo_1_timer

# servo 2
check_servo_2_button:
nop
nop
lw $r1, 8($r0)
nop
nop
addi $r2, $r0, 1
nop
nop
bne $r1, $r2, servo_2_button_checked
nop
nop
j set_servo_2_timer

# servo 3
check_servo_3_button:
nop
nop
lw $r1, 9($r0)
nop
nop
addi $r2, $r0, 1
nop
nop
bne $r1, $r2, servo_3_button_checked
nop
nop
j set_servo_3_timer






# servo timer setting code

# servo 1
set_servo_1_timer:
nop
nop
addi $r3, $r1, 1
nop
nop
sll $r3, $r3, 22
nop
nop
# 77 used to be 114
addi $r6, $r0, 77
nop
nop
sw $r6, 11($r0)
nop
nop
j servo_1_button_checked

#servo 2
set_servo_2_timer:
nop
nop
addi $r4, $r1, 1
nop
nop
sll $r4, $r4, 22
nop
nop
# 77 used to be 114
addi $r7, $r0, 77
nop
nop
sw $r7, 12($r0)
nop
nop
j servo_2_button_checked

#servo 3
set_servo_3_timer:
nop
nop
addi $r5, $r1, 1
nop
nop
sll $r5, $r5, 22
nop
nop
# 77 used to be 114
addi $r8, $r0, 77
nop
nop
sw $r8, 13($r0)
nop
nop
j servo_3_button_checked





# servo time subtraction code

# servo 1
subtract_servo_1_time:
nop
nop
addi $r2, $r0, 1
nop
nop
sub $r3, $r3, $r2
nop
nop
j servo_1_time_checked

# servo 2
subtract_servo_2_time:
nop
nop
addi $r2, $r0, 1
nop
nop
sub $r4, $r4, $r2
nop
nop
j servo_2_time_checked

# servo 3
subtract_servo_3_time:
nop
nop
addi $r2, $r0, 1
nop
nop
sub $r5, $r5, $r2
nop
nop
j servo_3_time_checked





# turn off servo code

# servo 1
turn_off_servo_1:
nop
nop
addi $r6, $r0, 40
nop
nop
sw $r6, 11($r0)
nop
nop
j servo_1_time_checked

# servo 2
turn_off_servo_2:
nop
nop
addi $r7, $r0, 40
nop
nop
sw $r7, 12($r0)
nop
nop
j servo_2_time_checked

# servo 3
turn_off_servo_3:
nop
nop
addi $r8, $r0, 40
nop
nop
sw $r8, 13($r0)
nop
nop
j servo_3_time_checked