
# r0 = 0
# r1 is used to chek if servo 1 button is pressed
# r2 is used as our 1 default to check servo
# r3 is servo 1 timer
# r4 is servo 2 timer
# r5 is servo 3 timer

# mem address 7 is for servo 1 button
# mem address 8 is for servo 2 button
# mem address 9 is for servo 3 button

# mem address 11 is for servo 1 timer boolean
# mem address 12 is for servo 2 timer boolean
# mem address 13 is for servo 3 timer boolean



check_buttons:
nop
nop

# checking if servo 1 button is pressed
beq $r3, $r0, check_servo_1_button
nop
nop

servo_1_button_checked:
# check to see if there is still time left on the servo
bne $r3, $r0, subtract_servo_1_time
nop
nop

# check to see if the timer on the servo is equal to 0
servo_1_time_checked:
beq $r3, $r0, turn_off_servo_1
nop
nop

servo_1_timer_off:
#insert code here to check the other servos





j check_buttons






check_servo_1_button:
nop
nop
lw $r1, 7($r0)
nop
nop
addi $r2, $r0, 1
nop
nop
beq $r1, $r2, set_servo_1_timer
nop
nop
j servo_1_button_checked


set_servo_1_timer:
nop
nop
addi $r3, $r1, $r0
nop
nop
sll $r3, $r3, 28
nop
nop
sw $r1, 11($r0)
nop
nop
j servo_1_button_checked


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


turn_off_servo_1:
nop
nop
sw $r0, 11($r0)
nop
nop
j servo_1_timer_off