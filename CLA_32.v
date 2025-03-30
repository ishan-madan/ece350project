


module CLA_32(S, Cout, A, B, Cin);
  
  input [31:0] A, B;
  input Cin;

  output [31:0] S;
  output Cout;

  wire [3:0] G_block, P_block;
  wire c8, c16, c24, c32;

  CLA_8 cla0(S[7:0], , A[7:0], B[7:0], Cin,  G_block[0], P_block[0]);
  CLA_8 cla1(S[15:8], , A[15:8], B[15:8], c8,  G_block[1], P_block[1]);
  CLA_8 cla2(S[23:16], , A[23:16], B[23:16], c16,  G_block[2], P_block[2]);
  CLA_8 cla3(S[31:24], , A[31:24], B[31:24], c24,  G_block[3], P_block[3]);


  wire w1;
  and and1(w1, P_block[0], Cin);
  or  or1(c8, G_block[0], w1);

  wire w2, w3;
  and and2(w2, P_block[1], G_block[0]);
  and and3(w3, P_block[1], P_block[0], Cin);
  or  or2(c16, G_block[1], w2, w3);

  wire w4, w5, w6;
  and and4(w4, P_block[2], G_block[1]);
  and and5(w5, P_block[2], P_block[1], G_block[0]);
  and and6(w6, P_block[2], P_block[1], P_block[0], Cin);
  or  or3(c24, G_block[2], w4, w5, w6);

  wire w7, w8, w9, w10;
  and and7(w7, P_block[3], G_block[2]);
  and and8(w8, P_block[3], P_block[2], G_block[1]);
  and and9(w9, P_block[3], P_block[2], P_block[1], G_block[0]);
  and and10(w10, P_block[3], P_block[2], P_block[1], P_block[0], Cin);
  or  or4(c32, G_block[3], w7, w8, w9, w10);

  assign Cout = c32;

endmodule