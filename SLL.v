


module SLL(out, in, shamt);

  input [31:0] in;
  input [4:0] shamt;
  output [31:0] out;

  wire [31:0] shift1, shift2, shift3, shift4, shift5;

  assign shift1 = shamt[4] ? {in[15:0], 16'b0} : in;
  
  assign shift2 = shamt[3] ? {shift1[23:0], 8'b0} : shift1;
  
  assign shift3 = shamt[2] ? {shift2[27:0], 4'b0} : shift2;
  
  assign shift4 = shamt[1] ? {shift3[29:0], 2'b0} : shift3;
  
  assign shift5 = shamt[0] ? {shift4[30:0], 1'b0} : shift4;
  
  assign out = shift5;
  

endmodule