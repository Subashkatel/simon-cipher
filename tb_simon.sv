`timescale 1ns / 1ps
module tb_simon;
    // Parameters
    parameter n = 32;  // Half the block size (64/2)
    parameter m = 4;   // Key words (128/32)

    // Inputs
    reg clk;
    reg rst;
    reg en;
    reg [2*n-1:0] plaintext;  // 64-bit plaintext
    reg [n*m-1:0] key;        // 128-bit key

    // Outputs
    wire [2*n-1:0] ciphertext;
    wire done;

    // Instantiate the Unit Under Test (UUT)
    simon #(.n(n), .m(m)) uut (
        .clk(clk), 
        .rst(rst), 
        .plaintext(plaintext), 
        .key(key), 
        .ciphertext(ciphertext), 
        .en(en),
        .done(done)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;
    end

    integer mismatch_count;

    initial begin
        // Initialize inputs
        clk = 0;
        rst = 0;
        en = 0;
        plaintext = 0;
        key = 0;
        mismatch_count = 0;

        // Dump waveform
        $dumpfile("waveform_simon.vcd");
        $dumpvars(0, tb_simon);

        // Reset sequence
        rst = 1;
        #10;
        rst = 0;
        #10;

        // Test 1
        key = 128'h1b1a1918131211100b0a090803020100;
        plaintext = 64'h656b696c20646e75;
        run_test(64'h44c8fc20b9dfa07a);

        // Test 2
        key = 128'h0123456789ABCDEF0123456789ABCDEF;
        plaintext = 64'hFEDCBA9876543210;
        run_test(64'hE0EEA3F009ED2BC7);

        // Test 3
        key = 128'h00112233445566778899AABBCCDDEEFF;
        plaintext = 64'h1234567890ABCDEF;
        run_test(64'h76CBE5E41CB96AF8);

        // Test 4
        key = 128'hAABBCCDDEEFF00112233445566778899;
        plaintext = 64'hDEADBEEFDEADBEEF;
        run_test(64'hFF245021662BA2AF);

        // Test 5
        key = 128'hCAFEBABECAFEBABECAFEBABECAFEBABE;
        plaintext = 64'hCAFEBABECAFEBABE;
        run_test(64'h5DB4EBCDBC6188DE);

        // Recursive Test
        key = 128'hFEDCBA98765432100123456789ABCDEF;
        plaintext = 64'h1234567890ABCDEF;
        run_recursive_test(3, 64'h34BE744934FABB4E, 64'h823A057D5B933604, 64'h06372B3E88230685);

        // Finalize
        if (mismatch_count == 0)
            $display("All tests passed!");
        else
            $display("%0d mismatches out of %0d total tests.", mismatch_count, 6);
        $finish;
    end

    task run_test;
        input [2*n-1:0] expected_ciphertext;
        begin
            // Reset before each test
            rst = 1;
            @(posedge clk);
            rst = 0;
            @(posedge clk);

            // Start encryption
            @(posedge clk);
            en = 1;
            @(posedge clk);
            en = 0;

            // Wait for encryption to complete
            while(done != 1) begin
                @(posedge clk);
            end

            // Check the result
            if (ciphertext !== expected_ciphertext) begin
                $display("Mismatch: Expected Ciphertext = %h, Got = %h", expected_ciphertext, ciphertext);
                mismatch_count = mismatch_count + 1;
            end else begin
                $display("Test passed: Ciphertext = %h", ciphertext);
            end

            // Small delay before next test
            #20;
        end
    endtask

    task run_recursive_test;
        input integer num_iterations;
        input [2*n-1:0] expected_ciphertext1;
        input [2*n-1:0] expected_ciphertext2;
        input [2*n-1:0] expected_ciphertext3;
        reg [2*n-1:0] expected_ciphertexts[2:0];
        integer i;
        begin
            expected_ciphertexts[0] = expected_ciphertext1;
            expected_ciphertexts[1] = expected_ciphertext2;
            expected_ciphertexts[2] = expected_ciphertext3;
            for (i = 0; i < num_iterations; i = i + 1) begin
                // Reset before each iteration
                rst = 1;
                @(posedge clk);
                rst = 0;
                @(posedge clk);

                // Start encryption
                en = 1;
                @(posedge clk);
                en = 0;

                // Wait for encryption to complete
                while(done != 1) begin
                    @(posedge clk);
                end

                // Check the result
                if (ciphertext !== expected_ciphertexts[i]) begin
                    $display("Mismatch in recursive test %0d: Expected Ciphertext = %h, Got = %h", i+1, expected_ciphertexts[i], ciphertext);
                    mismatch_count = mismatch_count + 1;
                end else begin
                    $display("Recursive Test %0d passed: Ciphertext = %h", i+1, ciphertext);
                end

                // Update plaintext with the resultant ciphertext for next iteration
                plaintext = ciphertext;

                // Small delay before next iteration
                #20;
            end
        end
    endtask

endmodule