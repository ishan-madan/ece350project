

module CLA_8(S, Cout, A, B, Cin, G_block, P_block);
 
  input [7:0] A, B;
  input Cin;

  output [7:0] S;
  output Cout;
  output G_block, P_block;

  wire [7:0] P, G;
  wire c1, c2, c3, c4, c5, c6, c7, c8;

  gp gp0(P[0], G[0], A[0], B[0]);
  gp gp1(P[1], G[1], A[1], B[1]);
  gp gp2(P[2], G[2], A[2], B[2]);
  gp gp3(P[3], G[3], A[3], B[3]);
  gp gp4(P[4], G[4], A[4], B[4]);
  gp gp5(P[5], G[5], A[5], B[5]);
  gp gp6(P[6], G[6], A[6], B[6]);
  gp gp7(P[7], G[7], A[7], B[7]);

  wire w0;
  and and0(w0, Cin, P[0]);
  or or0(c1, G[0], w0);

  wire w1, w2;
  and and1(w1, Cin, P[0], P[1]);
  and and2(w2, G[0], P[1]);
  or or1(c2, G[1], w1, w2);

  wire w3, w4, w5;
  and and3(w3, Cin, P[0], P[1], P[2]);
  and and4(w4, G[0], P[1], P[2]);
  and and5(w5, G[1], P[2]);
  or or2(c3, G[2], w3, w4, w5);

  wire w6, w7, w8, w9;
  and and6(w6, Cin, P[0], P[1], P[2], P[3]);
  and and7(w7, G[0], P[1], P[2], P[3]);
  and and8(w8, G[1], P[2], P[3]);
  and and9(w9, G[2], P[3]);
  or or3(c4, G[3], w6, w7, w8, w9);

  wire w10, w11, w12, w13, w14;
  and and10(w10, Cin, P[0], P[1], P[2], P[3], P[4]);
  and and11(w11, G[0], P[1], P[2], P[3], P[4]);
  and and12(w12, G[1], P[2], P[3], P[4]);
  and and13(w13, G[2], P[3], P[4]);
  and and14(w14, G[3], P[4]);
  or or4(c5, G[4], w10, w11, w12, w13, w14);

  wire w15, w16, w17, w18, w19, w20;
  and and15(w15, Cin, P[0], P[1], P[2], P[3], P[4], P[5]);
  and and16(w16, G[0], P[1], P[2], P[3], P[4], P[5]);
  and and17(w17, G[1], P[2], P[3], P[4], P[5]);
  and and18(w18, G[2], P[3], P[4], P[5]);
  and and19(w19, G[3], P[4], P[5]);
  and and20(w20, G[4], P[5]);
  or or5(c6, G[5], w15, w16, w17, w18, w19, w20);

  wire w21, w22, w23, w24, w25, w26, w27;
  and and21(w21, Cin, P[0], P[1], P[2], P[3], P[4], P[5], P[6]);
  and and22(w22, G[0], P[1], P[2], P[3], P[4], P[5], P[6]);
  and and23(w23, G[1], P[2], P[3], P[4], P[5], P[6]);
  and and24(w24, G[2], P[3], P[4], P[5], P[6]);
  and and25(w25, G[3], P[4], P[5], P[6]);
  and and26(w26, G[4], P[5], P[6]);
  and and27(w27, G[5], P[6]);
  or or6(c7, G[6], w21, w22, w23, w24, w25, w26, w27);

  wire w28, w29, w30, w31, w32, w33, w34, w35;
  and and28(w28, Cin, P[0], P[1], P[2], P[3], P[4], P[5], P[6], P[7]);
  and and29(w29, G[0], P[1], P[2], P[3], P[4], P[5], P[6], P[7]);
  and and30(w30, G[1], P[2], P[3], P[4], P[5], P[6], P[7]);
  and and31(w31, G[2], P[3], P[4], P[5], P[6], P[7]);
  and and32(w32, G[3], P[4], P[5], P[6], P[7]);
  and and33(w33, G[4], P[5], P[6], P[7]);
  and and34(w34, G[5], P[6], P[7]);
  and and35(w35, G[6], P[7]);
  or or7(c8, G[7], w28, w29, w30, w31, w32, w33, w34, w35);

  assign Cout = c8;

  wire t0, t1, t2, t3, t4, t5, t6;
  and and_g0(t0, P[7], P[6], P[5], P[4], P[3], P[2], P[1], G[0]);
  and and_g1(t1, P[7], P[6], P[5], P[4], P[3], P[2], G[1]);
  and and_g2(t2, P[7], P[6], P[5], P[4], P[3], G[2]);
  and and_g3(t3, P[7], P[6], P[5], P[4], G[3]);
  and and_g4(t4, P[7], P[6], P[5], G[4]);
  and and_g5(t5, P[7], P[6], G[5]);
  and and_g6(t6, P[7], G[6]);
  or or_G(G_block, G[7], t6, t5, t4, t3, t2, t1, t0);

  and and_P(P_block, P[7], P[6], P[5], P[4], P[3], P[2], P[1], P[0]);

  xor xor0(S[0], A[0], B[0], Cin);
  xor xor1(S[1], A[1], B[1], c1);
  xor xor2(S[2], A[2], B[2], c2);
  xor xor3(S[3], A[3], B[3], c3);
  xor xor4(S[4], A[4], B[4], c4);
  xor xor5(S[5], A[5], B[5], c5);
  xor xor6(S[6], A[6], B[6], c6);
  xor xor7(S[7], A[7], B[7], c7);

endmodule


