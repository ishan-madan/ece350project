



module processor(
    clock,
    reset,

    address_imem,
    q_imem,

    address_dmem,
    data,
    wren,
    q_dmem,

    ctrl_writeEnable,
    ctrl_writeReg,
    ctrl_readRegA,
    ctrl_readRegB,
    data_writeReg,
    data_readRegA,
    data_readRegB
);

    //-------------------------------------------------------------------------
    // I/O
    //-------------------------------------------------------------------------
    input clock, reset;

    // Imem
    output [31:0] address_imem;
    input [31:0]  q_imem;

    // Dmem
    output [31:0] address_dmem, data;
    output        wren;
    input [31:0]  q_dmem;

    // Regfile
    output        ctrl_writeEnable;
    output [4:0]  ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input  [31:0] data_readRegA, data_readRegB;

    //-------------------------------------------------------------------------
    // Internal wires
    //-------------------------------------------------------------------------
    wire negClock;
    not invert_clk(negClock, clock);

    wire flush = EX_isJump | EX_isJal | EX_isJR | EX_branchTaken;
    wire clr_pipe = reset | flush;

    wire branchInID; 
    assign branchInID = ID_isBLT | ID_isBNE | ID_isBex | ID_isJR; 

    wire lwUseStall;
    assign lwUseStall = EX_isLW && (EX_rdExt[4:0] != 5'd0) &&
                        ((EX_rdExt[4:0] == ctrl_readRegA) ||
                         (EX_rdExt[4:0] == ctrl_readRegB));

    wire lwBranchStall;
    assign lwBranchStall = branchInID && lwUseStall;

    wire stall;
    assign stall = EX_isLW & FD_valid & ((~FD_isLW) || ID_isSW);

    // PC
    wire [31:0] PC_cur, PC_next, PC_plus_one;
    CLA_32 pc_adder(.S(PC_plus_one), .Cout(), .A(PC_cur), .B(32'd1), .Cin(1'b0));

    // Pipeline: IF=>ID
    wire [31:0] IF_instr_in, IF_instr;

    // ID signals
    wire [4:0] ID_opcode;
    wire ID_isRtype, ID_isAddi, ID_isLW, ID_isSW;
    wire ID_isJump, ID_isJal, ID_isJR;
    wire ID_isBLT, ID_isBNE;
    wire ID_isBex, ID_isSetx;
    wire [31:0] ID_jumpTarget;
    wire [31:0] ID_pcPlusOne;  

    // Pipeline: ID=>EX
    wire [31:0] EX_rsVal, EX_rtVal;
    wire [31:0] EX_rdExt, EX_aluOpExt, EX_shamtExt;
    wire [31:0] EX_immediateExt;
    wire EX_isRtype, EX_isAddi, EX_isLW, EX_isSW;
    wire EX_isJump, EX_isJal, EX_isJR;
    wire EX_isBLT, EX_isBNE;
    wire EX_isBex, EX_isSetx;
    wire [31:0] EX_jumpTarget;
    wire [31:0] EX_pcPlusOne;
        
    // EX outputs
    wire [31:0] ex_result;
    wire ex_isNotEqual, ex_isLessThan, ex_overflow;
    wire [31:0] signImm;
    // wire [31:0] operandA, operandB; // ALUbypass
    wire [4:0]  aluOPfinal, ex_shamt;

    // Branch signals
    wire EX_branchTaken;
    wire [31:0] EX_branchTarget;

    // Pipeline: EX=>MEM
    wire [31:0] MEM_aluResult;
    wire [31:0] MEM_branchTarget;
    wire MEM_branchTaken;
    wire [31:0] MEM_destRegExt;
    wire [4:0]  MEM_destReg;
    wire [31:0] MEM_storeData;
    wire MEM_isLW, MEM_isSW;
    wire MEM_isJal;             
    wire MEM_isSetx;
    wire [31:0] MEM_pcPlusOne;  
    wire [31:0] MEM_jumpTarget;

    // Pipeline: MEM=>WB
    wire [31:0] WB_dmemOut;
    wire [31:0] WB_aluResult;
    wire [31:0] WB_destRegExt;
    wire [4:0]  WB_destReg;
    wire WB_isLW;
    wire [31:0] WB_writeData;
    wire WB_regWrite;
    wire WB_isJal;     
    wire WB_isSetx;      
    wire [31:0] WB_pcPlusOne;
    wire [31:0] WB_jumpTarget;

    // Write enable signals
    wire EX_regWrite, MEM_regWrite;

    // MultDiv wires 
    wire busy;
    wire ready; // data_result_RDY from multdiv call (are we done running multdiv?)
    wire ctrl_MULT = (aluOPfinal == 5'b00110) && ~busy; 
    wire ctrl_DIV = (aluOPfinal == 5'b00111) && ~busy; 
    wire activateMultDiv = ctrl_MULT | ctrl_DIV;
    wire [31:0] md_out;
    wire multdiv_excep; 
    dffe_ref is_MD_busy(
        .q(busy),
        .d(activateMultDiv),
        .clk(clock),
        .en(activateMultDiv | ready),
        .clr(reset)
    );

    //-------------------------------------------------------------------------
    // IF Stage
    //-------------------------------------------------------------------------
    wire FD_valid;
    assign FD_valid = (IF_instr != 32'b0); 
    wire FD_isLW;
    assign FD_isLW = (IF_instr[31:27] == 5'b01000);  // True if the fetched instruction is lw

    // PC Register
    reg32bits pc_reg(.q(PC_cur), .d(PC_next), .clk(negClock), .enable((~busy) & (~stall)), .reset(reset)); // PC_next for final_PC_next

    assign address_imem = PC_cur;  // Output PC to imem

    assign IF_instr_in = flush ? 32'b0 : q_imem;  // Instruction fetch input (will flush in EX)

    reg32bits IF_latch(.q(IF_instr), .d(IF_instr_in), .clk(negClock), .enable((~busy) & (~stall)), .reset(clr_pipe));

    //-------------------------------------------------------------------------
    // ID Stage
    //-------------------------------------------------------------------------
    wire [31:0] ID_pcPlusOne_in;
    CLA_32 pc_adder2(.S(ID_pcPlusOne_in), .Cout(), .A(PC_cur), .B(32'd1), .Cin(1'b0));
    reg32bits id_pcplusone_reg(.q(ID_pcPlusOne), .d(ID_pcPlusOne_in), .clk(negClock), .enable(~busy | ready), .reset(clr_pipe));

    // Extract opcode
    assign ID_opcode = IF_instr[31:27];
    // Decode
    assign ID_isRtype = (ID_opcode == 5'b00000);
    assign ID_isAddi  = (ID_opcode == 5'b00101);
    assign ID_isLW    = (ID_opcode == 5'b01000);
    assign ID_isSW    = (ID_opcode == 5'b00111);
    assign ID_isBLT   = (ID_opcode == 5'b00110);
    assign ID_isBNE   = (ID_opcode == 5'b00010);
    assign ID_isJump  = (ID_opcode == 5'b00001);
    assign ID_isJal   = (ID_opcode == 5'b00011);
    assign ID_isJR    = (ID_opcode == 5'b00100);
    assign ID_isBex   = (ID_opcode == 5'b10110);
    assign ID_isSetx  = (ID_opcode == 5'b10101);
    
    // Jump target from instruction
    assign ID_jumpTarget = {5'b00000, IF_instr[26:0]};

    // R-type 
    wire [4:0] rtype_rd = IF_instr[26:22];
    wire [4:0] rtype_rs = IF_instr[21:17];
    wire [4:0] rtype_rt = IF_instr[16:12];

    // I-type 
    wire [4:0] itype_rd = IF_instr[26:22];
    wire [4:0] itype_rs = IF_instr[21:17];
    wire [16:0] itype_imm= IF_instr[16:0];

    // ALU bits
    wire [4:0] ID_shamt  = IF_instr[11:7];
    wire [4:0] ID_ALUop  = IF_instr[6:2];
    wire [16:0] ID_imm   = IF_instr[16:0];
    wire [1:0] ID_zeroes = IF_instr[1:0];

    //  readRegA, readRegB
    assign ctrl_readRegA = (ID_isBex) ? 5'd30 : (ID_isJR) ? IF_instr[26:22] : (ID_isRtype) ? rtype_rs : itype_rs;
    assign ctrl_readRegB = (ID_isRtype) ? rtype_rt : (ID_isJR) ? 5'd0 : itype_rd;


    //-------------------------------------------------------------------------
    // ID -> EX pipeline registers
    //-------------------------------------------------------------------------

    // Latch register file 
    reg32bits ex_rsVal(.q(EX_rsVal), .d(stall ? 32'b0 : data_readRegA), .clk(negClock), .enable((~busy | ready)), .reset(reset));  
    reg32bits ex_rtVal(.q(EX_rtVal), .d(stall ? 32'b0 : data_readRegB), .clk(negClock), .enable((~busy | ready)), .reset(reset));  

    reg32bits ex_rd_reg(.q(EX_rdExt), .d(stall ? 32'b0 : {27'b0, rtype_rd}), .clk(negClock), .enable((~busy | ready)), .reset(reset));  
    reg32bits ex_aluop_reg(.q(EX_aluOpExt), .d(stall ? 32'b0 : {27'b0, ID_ALUop}), .clk(negClock), .enable((~busy | ready)), .reset(reset));  
    reg32bits ex_shamt_reg(.q(EX_shamtExt), .d(stall ? 32'b0 : {27'b0, ID_shamt}), .clk(negClock), .enable((~busy | ready)), .reset(reset));  

    // Latch immediate
    reg32bits ex_imm_reg(.q(EX_immediateExt), .d(stall ? 32'b0 : {15'b0, ID_imm}), .clk(negClock), .enable((~busy | ready)), .reset(reset));  

    // Latch control bits
    dffe_ref dffe_rtype(.q(EX_isRtype), .d(stall ? 1'b0 : ID_isRtype), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_addi(.q(EX_isAddi), .d(stall ? 1'b0 : ID_isAddi), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_lw(.q(EX_isLW), .d(stall ? 1'b0 : ID_isLW), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_sw(.q(EX_isSW), .d(stall ? 1'b0 : ID_isSW), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_blt(.q(EX_isBLT), .d(stall ? 1'b0 : ID_isBLT), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_bne(.q(EX_isBNE), .d(stall ? 1'b0 : ID_isBNE), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_jump(.q(EX_isJump), .d(stall ? 1'b0 : ID_isJump), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_jal(.q(EX_isJal), .d(stall ? 1'b0 : ID_isJal), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_jr(.q(EX_isJR), .d(stall ? 1'b0 : ID_isJR), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_bex(.q(EX_isBex), .d(stall ? 1'b0 : ID_isBex), .clk(negClock), .en((~busy | ready)), .clr(reset));  
    dffe_ref dffe_setx(.q(EX_isSetx), .d(stall ? 1'b0 : ID_isSetx), .clk(negClock), .en((~busy | ready)), .clr(reset));  

    // Latch PC+1 for jal)
    reg32bits ex_pcplusone(.q(EX_pcPlusOne), .d(stall ? 32'b0 : ID_pcPlusOne), .clk(negClock), .enable((~busy | ready)), .reset(reset));  

    // Latch jumpTarget for EX
    reg32bits ex_jt(.q(EX_jumpTarget), .d(stall ? 32'b0 : ID_jumpTarget), .clk(negClock), .enable((~busy | ready)), .reset(reset));  

    // ALU bypass latching for register numbers
    wire [31:0] EX_readRegA_ext, EX_readRegB_ext;
    reg32bits ex_readRegA_reg(.q(EX_readRegA_ext), .d(stall ? 32'b0 : {27'b0, ctrl_readRegA}), .clk(negClock), .enable((~busy | ready)), .reset(reset));  
    reg32bits ex_readRegB_reg(.q(EX_readRegB_ext), .d(stall ? 32'b0 : {27'b0, ctrl_readRegB}), .clk(negClock), .enable((~busy | ready)), .reset(reset));  
    wire [4:0] EX_readRegA = EX_readRegA_ext[4:0];
    wire [4:0] EX_readRegB = EX_readRegB_ext[4:0];

    //-------------------------------------------------------------------------
    // EX Stage
    //-------------------------------------------------------------------------

    // ALU inputs
    assign signImm  = {{15{EX_immediateExt[16]}}, EX_immediateExt[16:0]};

    // start memory bypass
    wire [31:0] bypassed_operandA =
        (EX_readRegA == 5'd30 && MEM_exception_code != 32'b0) ? MEM_exception_code :  // exception bypass for r30
        (EX_readRegA == 5'd30 && WB_exception_code != 32'b0) ? WB_exception_code :      // exception bypass for r30
        (MEM_regWrite && (MEM_destReg != 5'd0) && (MEM_destReg == EX_readRegA)) ? ((MEM_isLW) ? q_dmem : MEM_aluResult) :
        (WB_regWrite && (WB_destReg != 5'd0) && (WB_destReg == EX_readRegA)) ? (WB_isLW ? WB_dmemOut : WB_aluResult) :
        EX_rsVal;

    wire [31:0] bypassed_operandB =
        (EX_readRegB == 5'd30 && MEM_exception_code != 32'b0) ? MEM_exception_code :  //  exception bypass for r30
        (EX_readRegB == 5'd30 && WB_exception_code != 32'b0) ? WB_exception_code :      // exception bypass for r30
        (EX_isAddi | EX_isLW | EX_isSW) ? signImm :
        (MEM_regWrite && (MEM_destReg != 5'd0) && (MEM_destReg == EX_readRegB)) ? ((MEM_isLW) ? q_dmem : MEM_aluResult) :
        (WB_regWrite && (WB_destReg != 5'd0) && (WB_destReg == EX_readRegB)) ? (WB_isLW ? WB_dmemOut : WB_aluResult) :
        EX_rtVal;
    // end memory bypass

    assign aluOPfinal = EX_isRtype ? EX_aluOpExt[4:0] : 5'b00000;
    assign ex_shamt = EX_shamtExt[4:0];

    alu mainALU(
        .data_operandA(bypassed_operandA), 
        .data_operandB(bypassed_operandB), 
        .ctrl_ALUopcode(aluOPfinal),
        .ctrl_shiftamt(ex_shamt),
        .data_result(ex_result),
        .isNotEqual(ex_isNotEqual),
        .isLessThan(ex_isLessThan),
        .overflow(ex_overflow)
    );

    multdiv md_ALU(
        .data_operandA(bypassed_operandA), 
        .data_operandB(bypassed_operandB), 
        .ctrl_MULT(ctrl_MULT),
        .ctrl_DIV(ctrl_DIV),
        .clock(clock),
        .data_result(md_out),
        .data_exception(multdiv_excep),
        .data_resultRDY(ready)
    );
    wire [31:0] aluFinal = busy ? md_out : ex_result;

    wire EX_alu_overflow = ex_overflow; 
    wire EX_md_excep = multdiv_excep;

    wire add_overflow;
    assign add_overflow = ((bypassed_operandA[31] == 0) && (bypassed_operandB[31] == 0) && (aluFinal[31] == 1)) ||
                          ((bypassed_operandA[31] == 1) && (bypassed_operandB[31] == 1) && (aluFinal[31] == 0));

    wire [4:0] EX_code_alu = (EX_isAddi && EX_alu_overflow) ?                5'd2 :  // addi exception 
                             ((aluOPfinal == 5'b00000) && (EX_alu_overflow || add_overflow)) ? 5'd1 :  // add exception 
                             ((aluOPfinal == 5'b00001) && EX_alu_overflow) ? 5'd3 :  // sub exception
                             5'd0; 
    wire [4:0] EX_code_md = EX_md_excep ? ((aluOPfinal == 5'b00110) ? 5'd4 : 
                                           (aluOPfinal == 5'b00111) ? 5'd5 : 5'd0) : 5'd0;

    wire [4:0] EX_exception_code = (EX_code_alu != 5'd0) ? EX_code_alu : EX_code_md;

    // start mem bypass -> just added on to branch bypass abovee^
    // Branch bypass
    wire [31:0] bypassed_branch_rsVal =
        (EX_readRegA == 5'd30 && MEM_exception_code != 32'b0) ? MEM_exception_code :
        (EX_readRegA == 5'd30 && WB_exception_code != 32'b0) ? WB_exception_code :
        (EX_readRegA == 5'd30 && MEM_isSetx) ? MEM_jumpTarget :
        (EX_readRegA == 5'd30 && WB_isSetx) ? WB_jumpTarget :
        (MEM_regWrite && (MEM_destReg != 5'd0) && (MEM_destReg == EX_readRegA)) ? ((MEM_isLW) ? q_dmem : MEM_aluResult) :
        (WB_regWrite && (WB_destReg != 5'd0) && (WB_destReg == EX_readRegA)) ? (WB_isLW ? WB_dmemOut : WB_aluResult) :
        EX_rsVal;

    wire [31:0] bypassed_branch_rtVal =
        (MEM_regWrite && (MEM_destReg != 5'd0) && (MEM_destReg == EX_readRegB)) ? ((MEM_isLW) ? q_dmem : MEM_aluResult) :
        (WB_regWrite && (WB_destReg != 5'd0) && (WB_destReg == EX_readRegB)) ? (WB_isLW ? WB_dmemOut : WB_aluResult) :
        EX_rtVal;

    wire [31:0] branch_operandA;
    wire [31:0] branch_operandB;
    assign branch_operandA = lwBranchStall ? ((MEM_isLW) ? q_dmem : MEM_aluResult) : bypassed_branch_rsVal;
    assign branch_operandB = lwBranchStall ? ((MEM_isLW) ? q_dmem : MEM_aluResult) : bypassed_branch_rtVal;

    // Use the branch bypass muxes for the less-than ALU
    wire signed [31:0] s_rsVal = branch_operandA;
    wire signed [31:0] s_rtVal = branch_operandB;
    // end mem bypass

    wire [31:0] dummyDataResult;
    wire dummyIsNotEqual, dummyOverflow;
    wire isLessThan;

    alu lessThanALU(
        .data_operandA(s_rtVal),
        .data_operandB(s_rsVal),
        .ctrl_ALUopcode(5'b00001), 
        .ctrl_shiftamt(5'b0),
        .data_result(dummyDataResult), 
        .isNotEqual(dummyIsNotEqual),   
        .isLessThan(isLessThan),
        .overflow(dummyOverflow)   
    );
    wire EX_bltTaken = EX_isBLT & isLessThan;
    wire EX_bneTaken = EX_isBNE & (s_rtVal != s_rsVal);

    // bex bypass ??
    wire doBEX = EX_isBex & (bypassed_branch_rsVal != 32'b0);
    assign EX_branchTaken = EX_bltTaken | EX_bneTaken | doBEX;

    // Branch target
    wire [31:0] branchTarget_blt_bne;
    CLA_32 br_adder(.S(branchTarget_blt_bne), .Cout(), .A(EX_pcPlusOne), .B(signImm), .Cin(1'b0));
    wire [31:0] finalBranchTarget = doBEX ? EX_jumpTarget : branchTarget_blt_bne;

    wire EX_isJumpType = EX_isJump | EX_isJal | EX_isJR;  
   
    wire [31:0] PC_cur_plus_one;
    CLA_32 pc_adder1(.S(PC_cur_plus_one), .Cout(), .A(PC_cur), .B(32'd1), .Cin(1'b0));

    // jr bypass
    wire [31:0] bypassed_jr_val = 
        (MEM_regWrite && (MEM_destReg != 5'd0) && (MEM_destReg == EX_readRegA))
            ? ((MEM_isLW) ? q_dmem : MEM_aluResult)
        : (WB_regWrite && (WB_destReg != 5'd0) && (WB_destReg == EX_readRegA))
            ? ((WB_isLW) ? WB_dmemOut : WB_aluResult)
        : EX_rsVal;
    // end jr bypass

    assign PC_next =
        (EX_isJR)            ? bypassed_jr_val : // jr bypass change 
        (EX_isJumpType)      ? EX_jumpTarget :
        (EX_branchTaken)     ? finalBranchTarget : (PC_cur_plus_one);

    // Flush IF on a jump or branch
    assign IF_instr_in = (EX_isJumpType || EX_branchTaken) ? 32'b0 : q_imem;

    wire [31:0] MEM_exception_code, WB_exception_code;
    wire [31:0] EX_exception_code_ext = {27'b0, EX_exception_code};

    reg32bits ex_mem_excep(
        .q(MEM_exception_code), 
        .d(EX_exception_code_ext),
        .clk(negClock), 
        .enable(1'b1), 
        .reset(reset)
    );

    reg32bits mem_wb_excep(
        .q(WB_exception_code),
        .d(MEM_exception_code),
        .clk(negClock),
        .enable(1'b1),
        .reset(reset)
    );

    //-------------------------------------------------------------------------
    // EX -> MEM
    //-------------------------------------------------------------------------

    reg32bits aluResult_reg(.q(MEM_aluResult), .d(aluFinal), .clk(negClock), .enable(~busy | ready), .reset(reset));

    wire [4:0] EX_destReg = EX_rdExt[4:0];
    wire [31:0] EX_destRegExt = {27'b0, EX_destReg};
    reg32bits mem_destReg(.q(MEM_destRegExt), .d(EX_destRegExt), .clk(negClock), .enable(~busy | ready), .reset(reset));
    assign MEM_destReg = MEM_destRegExt[4:0];

    // start mem bypass
    wire [31:0] bypassed_store_data = 
        (MEM_regWrite && (MEM_destReg != 5'd0) && (MEM_destReg == EX_readRegB)) ? ((MEM_isLW) ? q_dmem : MEM_aluResult) :
        (WB_regWrite && (WB_destReg != 5'd0) && (WB_destReg == EX_readRegB)) ? (WB_isLW ? WB_dmemOut : WB_aluResult) :
        EX_rtVal;
    // end mem bypass

    // Store data
    reg32bits mem_storeData_reg(.q(MEM_storeData), .d(bypassed_store_data), .clk(negClock), .enable(~busy | ready), .reset(reset)); 

    dffe_ref mem_lw(.q(MEM_isLW), .d(EX_isLW), .clk(negClock), .en(~busy | ready), .clr(reset));
    dffe_ref mem_sw(.q(MEM_isSW), .d(EX_isSW), .clk(negClock), .en(~busy | ready), .clr(reset));
    dffe_ref mem_jal(.q(MEM_isJal), .d(EX_isJal), .clk(negClock), .en(~busy | ready), .clr(reset));
    dffe_ref mem_setx(.q(MEM_isSetx), .d(EX_isSetx), .clk(negClock), .en(~busy | ready), .clr(reset));

    reg32bits mem_jt(.q(MEM_jumpTarget), .d(EX_jumpTarget), .clk(negClock), .enable(~busy | ready), .reset(reset));
    reg32bits mem_pcplusone(.q(MEM_pcPlusOne), .d(EX_pcPlusOne), .clk(negClock), .enable(~busy | ready), .reset(reset));

    // RegWrite
    assign EX_regWrite = EX_isRtype | EX_isAddi | EX_isLW; // bex bypass??
    dffe_ref mem_regWrite(.q(MEM_regWrite), .d(EX_regWrite), .clk(negClock), .en(~busy | ready), .clr(reset));

    //-------------------------------------------------------------------------
    // MEM Stage
    //-------------------------------------------------------------------------

    // Memory assigns
    assign wren = MEM_isSW;
    assign data = MEM_storeData;
    assign address_dmem = MEM_aluResult;

    //-------------------------------------------------------------------------
    // MEM -> WB
    //-------------------------------------------------------------------------

    // Dmem out
    reg32bits wb_dmemReg(.q(WB_dmemOut), .d(q_dmem), .clk(negClock), .enable(~busy | ready), .reset(reset));
    reg32bits wb_aluResult_reg(.q(WB_aluResult), .d(MEM_aluResult), .clk(negClock), .enable(~busy | ready), .reset(reset));
    reg32bits wb_destReg(.q(WB_destRegExt), .d(MEM_destRegExt), .clk(negClock), .enable(~busy | ready), .reset(reset));
    assign WB_destReg = WB_destRegExt[4:0];

    dffe_ref wb_lw(.q(WB_isLW), .d(MEM_isLW), .clk(negClock), .en(~busy | ready), .clr(reset));
    dffe_ref wb_jal(.q(WB_isJal), .d(MEM_isJal), .clk(negClock), .en(~busy | ready), .clr(reset));

    reg32bits wb_pcplusone(.q(WB_pcPlusOne), .d(MEM_pcPlusOne),.clk(negClock), .enable(~busy | ready), .reset(reset));

    dffe_ref wb_setx(.q(WB_isSetx), .d(MEM_isSetx), .clk(negClock), .en(~busy | ready), .clr(reset));

    reg32bits wb_jt(.q(WB_jumpTarget), .d(MEM_jumpTarget), .clk(negClock), .enable(~busy | ready), .reset(reset));

    dffe_ref wb_regWrite(.q(WB_regWrite), .d(MEM_regWrite), .clk(negClock), .en(~busy | ready), .clr(reset));

    //-------------------------------------------------------------------------
    // WB Stage
    //-------------------------------------------------------------------------

    // Mux: lw data vs ALU
    wire [31:0] normalWBdata;
    mux_2 mux_wb_data(.out(normalWBdata), .select(WB_isLW), .in0(WB_aluResult), .in1(WB_dmemOut));

    // jal: if WB_isJal, write WB_pcPlusOne to $31
    wire [31:0] finalWBdata = (WB_isJal) ? WB_pcPlusOne : normalWBdata;
    wire [4:0] finalWBreg  = (WB_isJal) ? 5'd31 : WB_destReg;

    wire doSetx = WB_isSetx;
    wire [31:0] setx_data = WB_jumpTarget; 

    wire [31:0] finalWBdata2 = doSetx ? setx_data : finalWBdata;
    wire [4:0] finalWBreg2  = doSetx ? 5'd30 : finalWBreg;

    wire doException = (WB_exception_code != 5'd0);

    wire [31:0] finalWBdata3 = doException ? {27'b0, WB_exception_code} : finalWBdata2;
    wire [4:0] finalWBreg3  = doException ? 5'd30 : finalWBreg2;

    // Write to RegFile
    assign ctrl_writeReg = finalWBreg3;
    assign data_writeReg = finalWBdata3;
    assign ctrl_writeEnable = WB_regWrite || WB_isJal || doSetx || doException;

endmodule