`timescale 1ns / 1ps
`include "utility.vh"
module simon #(parameter n=`N, m=`M)
(clk, rst, plaintext, key, ciphertext, en, done);
    input clk, rst, en;
    input [2*n-1:0] plaintext;
    input [n*m-1:0] key;
    output reg [2*n-1:0] ciphertext;
    output done;
    localparam s_idle = 2'b00;
    localparam s_enable = 2'b01;
    localparam s_busy = 2'b10;
    localparam s_done = 2'b11;
    localparam NUM_ROUNDS = T(n,m);
    
    reg [1:0] current_state; 
    wire [1:0] next_state;
    reg [7:0] current_counter;
    wire [7:0] next_counter;
    reg [2*n-1:0] x;
    wire [2*n-1:0] next_x, y;
    wire [n-1:0] k;
    wire [n*m-1:0] key_in;
    wire [n-1:0]key_i;
    reg [n-1:0] key_schedule [NUM_ROUNDS-1:0];
    wire [2*n-1:0] next_ciphertext;
    round #(.n(n),.m(m)) r (.x(x),.y(y),.k(k));
    key_expansion #(.n(n),.m(m)) key_ex(.key(key_in), .i(next_counter), .key_i(key_i));
    reg [7:0] init_counter =0;
    always @(posedge(clk))
    begin
        if (rst) begin
            current_counter <= 8'h00;
            current_state <= s_idle;
            x <= 0;
            ciphertext <= 0;
            for (integer i = 0; i < NUM_ROUNDS; i = i + 1) begin
                key_schedule[i] <= 0;
            end
        end
        else begin
            current_state <= next_state;
            current_counter <= next_counter;
            x <= next_x;
            ciphertext <= next_ciphertext;
            if (current_state == s_enable) begin
                key_schedule[0] <= key[n-1:0];
            end
            else if(current_state == s_busy)
            begin
                key_schedule[next_counter] <= key_i; 
            end
       end
    end
    assign k = (current_counter<m)? key[(current_counter+1)*(n)-1-:n] : key_schedule[current_counter];
    assign key_in = (current_counter <m)? key: {key_schedule[current_counter],key_schedule[current_counter-1],key_schedule[current_counter-2],key_schedule[current_counter-3]};
    assign next_counter = (current_state==s_enable)?0:(current_state===s_busy) ? (current_counter +1) : current_counter; 
    assign next_state = (rst==1)?
                        s_idle:(en==1)?
                        s_enable:(current_state==s_enable)?
                        s_busy:(current_state==s_busy && current_counter<(NUM_ROUNDS-1))?
                        s_busy:(current_state==s_busy && current_counter>=(NUM_ROUNDS-1))?
                        s_done:(current_state==s_done)?s_done:s_idle;
    assign done = (current_state==s_done)?1:0;
    assign next_x = (current_state==s_enable)? plaintext:y;
    assign next_ciphertext = (en==1)? 0: (current_state==s_busy && next_state==s_done) ? y: ciphertext;
    
    //Functions    
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