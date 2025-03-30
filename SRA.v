


module SRA(out, in, shamt);
  input [31:0] in;
  input [4:0] shamt;
  output [31:0] out;

  wire [31:0] shift1, shift2, shift3, shift4, shift5;

  assign shift1 = shamt[4] ? {{16{in[31]}}, in[31:16]} : in;

  assign shift2 = shamt[3] ? {{8{shift1[31]}}, shift1[31:8]} : shift1;
  
  assign shift3 = shamt[2] ? {{4{shift2[31]}}, shift2[31:4]} : shift2;
  
  assign shift4 = shamt[1] ? {{2{shift3[31]}}, shift3[31:2]} : shift3;

  assign shift5 = shamt[0] ? {{1{shift4[31]}}, shift4[31:1]} : shift4;
  
  assign out = shift5;

endmodule