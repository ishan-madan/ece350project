module ServoController(
    input        clk, 		    // System Clock Input 100 Mhz
//    input button,	    // Position control switches
    input [9:0] duty_cycle, 
    output       servoSignal    // Signal to the servo
    );	
        
//    wire[9:0] duty_cycle;
    
//    assign duty_cycle = (button * 72) + 40;
    
    PWMSerializer #(.PERIOD_WIDTH_NS(20000000), .SYS_FREQ_MHZ(50)) servoSer(clk, 1'b0, duty_cycle, servoSignal);
    
endmodule

// when you write to teh memory address, you
// can write a specific value (in this case we will writ ethe duty cycle value). 
//  then you can set a register to x amount of cycles and every cycle until it hits 0, 
// keep the duty cycle value at the memory address at the open value.
// once it hits zero, set the duty cycle value at the mem addy to the closed duty cycle value

// the value that we are sw is memdata in. ex: if 