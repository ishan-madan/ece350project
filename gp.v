

module gp(P, G, A, B);

input A, B; 
output P, G; 

or propagate(P, A, B); 
and generat_e(G, A, B); 

endmodule

