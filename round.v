`timescale 1ns / 1ps

`include "utility.vh"

module round #(parameter n=`N, m=`M)
    (x, k, y);
    input [(2*n)-1:0] x;
    input [(n-1):0] k;
    output [(2*n)-1:0] y;
    wire [n-1:0] x_0, x_1, rol_1, rol_8, rol_2;
    
    assign x_0 = x[n-1:0];
    assign x_1 = x[(2*n)-1-:n];
    
    assign y[n-1:0] = x_1;
    
    assign rol_1 = {x_1[0+:(n-1)], x_1[n-1]};
    assign rol_2 = {x_1[0+:(n-2)], x_1[n-1-:2]};
    assign rol_8 = {x_1[0+:(n-8)], x_1[n-1-:8]};
    
    assign y[(2*n)-1-:n] = (((rol_1 & rol_8) ^ x_0) ^ rol_2) ^ k;
endmodule
