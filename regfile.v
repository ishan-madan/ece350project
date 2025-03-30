


module regfile (clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset; // - , Enables writing to a register, Resets all registers
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB; // Selects which register to write to, Select registers to read from
	input [31:0] data_writeReg; // The data to be written

	output [31:0] data_readRegA, data_readRegB; // The data read from two selected registers
	// -------

	// TO DO: - necessary? 
	wire[31:0] writeEnable32;
	assign writeEnable32 = {32{ctrl_writeEnable}}; // make WE 32 bits (for each register)

	wire[31:0] writeReg; 
	assign writeReg = {32{data_writeReg}}; 

	wire[31:0] decodedRD, RDandWE;
	decoder_5to32 decodeRD(decodedRD, ctrl_writeReg); // finds the register to write to 
	and enabledWriteReg[31:0](RDandWE, decodedRD, writeEnable32);

	wire[31:0] w_reg_out[0:31]; 
	
	reg32bits reg0(w_reg_out[0], 32'b0, clock, RDandWE[0], ctrl_reset);

	// the registers with the DFFE (1-31)
	genvar i;
	generate
  		for (i = 1; i < 32; i = i + 1) begin : gen_reg
    		reg32bits registers(
      		.q(w_reg_out[i]),                    
      		.d(writeReg),                       
      		.clk(clock),                         
      		.enable(RDandWE[i]),
      		.reset(ctrl_reset)                    
    		);
  		end
	endgenerate

	// decode the ctrl_readRegs, into 32 bit array 
	wire[31:0] w_readRegA; 
    decoder_5to32 decodeRegA(w_readRegA, ctrl_readRegA);

	generate
  		for (i = 0; i < 32; i = i + 1) begin : gen_tsbA
    		tsb buffersA(
      		data_readRegA,   
      		w_reg_out[i],    
      		w_readRegA[i]     
    		);
  		end
	endgenerate


	wire[31:0] w_readRegB; 
    decoder_5to32 decodeRegB(w_readRegB, ctrl_readRegB);

	generate
  		for (i = 0; i < 32; i = i + 1) begin : gen_tsbB
    		tsb buffersB(
      		data_readRegB,   
      		w_reg_out[i],   
      		w_readRegB[i]     
    		);
  		end
	endgenerate


endmodule
