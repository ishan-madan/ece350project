`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to generate the bitstream to upload to the FPGA.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v and memory modules to work with the 
 * provided Wrapper interface.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must change line 36 to add the memory file of the test you created using the assembler
 * For example, you would add sample inside of the quotes on line 38 after assembling sample.s
 *
 **/

module Wrapper (input CLK100MHZ, input BTNU, input BTNL, input BTNR, input BTND, input [15:0] SW, output reg [15:0] LED, output Servo1, output Servo2, output Servo3);

	wire clock, reset;
	wire clk_50mhz;
    wire locked;
    assign clock = clk_50mhz;
	assign reset = BTNU;
	clk_wiz_0 pll(
        .clk_out1(clk_50mhz),
        .reset(1'd0),
        .locked(locked),
        .clk_in1(CLK100MHZ)
    );

	wire rwe, mwe;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData, 
		rData, regA, regB,
		memAddr, memDataIn, memDataOut;


	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "threeServo";
	
	// Main Processing Unit
	processor CPU(.clock(clock), .reset(reset), 
								
		// ROM
		.address_imem(instAddr), .q_imem(instData),
									
		// Regfile
		.ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
		.ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
									
		// RAM
		.wren(mwe), .address_dmem(memAddr), 
		.data(memDataIn), .q_dmem(memDataOut)); 
	
	// Instruction Memory (ROM)
	ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
	InstMem(.clk(clock), 
		.addr(instAddr[11:0]), 
		.dataOut(instData));
	
	// Register File
	regfile RegisterFile(.clock(clock), 
		.ctrl_writeEnable(rwe), .ctrl_reset(reset), 
		.ctrl_writeReg(rd),
		.ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
						
	// Processor Memory (RAM)
	RAM ProcMem(.clk(clock), 
		.wEn(mwe), 
		.addr(memAddr[11:0]), 
		.dataIn(memDataIn), 
		.dataOut(memDataOut_temp));
		
	reg[31:0] button_press_1, button_press_2, button_press_3;
	
	reg[9:0] servo1_duty_cycle, servo2_duty_cycle, servo3_duty_cycle;
	
	wire read_button_1, read_button_2, read_button_3;
	
	assign read_button_1 = (memAddr[11:0] == 12'd7);
	assign read_button_2 = (memAddr[11:0] == 12'd8);
	assign read_button_3 = (memAddr[11:0] == 12'd9);
	
	always @(posedge clock) begin
        if (read_button_1) begin
           button_press_1[31:0] <= {31'b0, BTNR};
        end
        
        if (read_button_2) begin
           button_press_2[31:0] <= {31'b0, BTNL};
        end

        if (read_button_3) begin
           button_press_3[31:0] <= {31'b0, BTND};
        end
        
        if (memAddr[11:0] == 12'd11 && mwe == 1'd1) begin
            servo1_duty_cycle <= memDataIn[9:0];
        end
        
        if (memAddr[11:0] == 12'd12 && mwe == 1'd1) begin
            servo2_duty_cycle <= memDataIn[9:0];
        end
        
        if (memAddr[11:0] == 12'd13 && mwe == 1'd1) begin
            servo3_duty_cycle <= memDataIn[9:0];
        end
	end
	
	// intercepts the real value and forces our own value in
	assign memDataOut = (memAddr[11:0] == 12'd7) ? button_press_1 : 
	                    (memAddr[11:0] == 12'd8) ? button_press_2 :
	                    (memAddr[11:0] == 12'd9) ? button_press_3 : 
	                    memDataOut_temp;

    
    
    ServoController servoCont1(clk_50mhz, servo1_duty_cycle, Servo1);
    ServoController servoCont2(clk_50mhz, servo2_duty_cycle, Servo2);
    ServoController servoCont3(clk_50mhz, servo3_duty_cycle, Servo3);
    
    always @(posedge clock) begin
//        if (memAddr[11:0] == 12'd6) begin
//	       LED[0] <= memDataIn[0];
//	   end
        LED[9:0] <= servo3_duty_cycle;
	end
    
endmodule
