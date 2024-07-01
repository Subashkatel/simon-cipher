`timescale 1ns / 1ps

`include "utility.vh"

module tb_key_expansion(

    );
    reg clk;
    reg [7:0] i;
    reg [`N-1:0] key_schedule[T(`N,`M)-1:0];
    wire [`N*`M-1:0] key = 64'h1918111009080100;
    reg [`N*`M-1:0] key_input;
    reg [`N-1:0] key_output;
    key_expansion ks(key_input, i, key_output);
    initial begin
        clk = 0;
        for (i = 0; i<`M;i = i +1)
        begin
            key_schedule[i] = key[((i+1)*`N)-1-:`N];
        end
    end
    always begin
        #5 clk = ~clk;
    end
    initial begin
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        while (i<=T(`N,`M))
        begin
            key_input = {key_schedule[i-1],key_schedule[i-2],key_schedule[i-3],key_schedule[i-4]};
            @(posedge clk);
            key_schedule[i] = key_output;
            i = i +1;
        end
        $finish;
    end
    function integer T;
        input integer n;
        input integer m;
        case(n)
            16: T = 32;
            24: T = 36;
            32: T = (m==3)?42:(m==4)?44:-1;
            48: T = (m==2)?52:(m==3)?54:-1;
            64: T = (m==2)?68:(m==3)?69:(m==4)?72:-1;
            default: T =-1;
         endcase        
    endfunction
endmodule
