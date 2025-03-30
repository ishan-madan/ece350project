module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
        
    input [31:0] data_operandA, data_operandB;
    input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

    output [31:0] data_result;
    output isNotEqual, isLessThan, overflow;

    // add & subtract
    wire [31:0] B_sub = ~data_operandB; 
    wire sub_or_add = ctrl_ALUopcode[0]; 
    wire [31:0] B_selected = sub_or_add ? B_sub : data_operandB;
    wire Cin = sub_or_add;  
    wire [31:0] w_CLA;       
    wire w_CLA_out;
    CLA_32 adder(w_CLA, w_CLA_out, data_operandA, B_selected, Cin);

    // bitwise and/or
    wire [31:0] w_or, w_and; 
    bitwise_and b_and(w_and[31:0], data_operandA[31:0], data_operandB[31:0]);
    bitwise_or b_or(w_or[31:0], data_operandA[31:0], data_operandB[31:0]);

    // SLL and SRA
    wire [31:0] w_SLL, w_SRA;
    SLL shiftLeft(w_SLL, data_operandA, ctrl_shiftamt); 
    SRA shiftRight(w_SRA, data_operandA, ctrl_shiftamt);

    // isNotEqual
    or not_equal(isNotEqual, w_CLA[0], w_CLA[1], w_CLA[2], w_CLA[3], w_CLA[4], w_CLA[5], w_CLA[6], w_CLA[7], w_CLA[8], w_CLA[9], w_CLA[10], w_CLA[11], w_CLA[12], w_CLA[13], w_CLA[14], w_CLA[15], w_CLA[16], w_CLA[17], w_CLA[18], w_CLA[19], w_CLA[20], w_CLA[21], w_CLA[22], w_CLA[23], w_CLA[24], w_CLA[25], w_CLA[26], w_CLA[27], w_CLA[28], w_CLA[29], w_CLA[30], w_CLA[31]); 

    // isLessThan
    wire w_posB, w_negA_and_posB, w_negA_or_posB, w_lessthan;
    not posB(w_posB, data_operandB[31]);
    and negA_and_posB(w_negA_and_posB, data_operandA[31], w_posB);
    or negA_or_posB(w_negA_or_posB, data_operandA[31], w_posB);
    and lessThanTerm(w_lessthan, w_CLA[31], w_negA_or_posB);
    or or_final(isLessThan, w_negA_and_posB, w_lessthan);

    // overflow
    wire w_same_sign1, w_same_sign2;
    xnor AB_same_sign(w_same_sign1, data_operandA[31], B_selected[31]);
    xor resultsign(w_same_sign2, w_CLA[31], B_selected[31]);
    and overflow_check(overflow, w_same_sign1, w_same_sign2);

    // final output 
    mux_8 final(data_result, ctrl_ALUopcode[2:0], w_CLA, w_CLA, w_and, w_or, w_SLL, w_SRA, 0, 0); 


endmodule