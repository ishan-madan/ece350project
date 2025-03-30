

module reg32bits(q, d, clk, enable, reset); 
    
    input clk, enable, reset; 
    input[31:0] d; 
    output[31:0] q; 

    dffe_ref register[31:0](q, d, clk, enable, reset); 

endmodule  