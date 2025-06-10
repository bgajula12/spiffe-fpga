
module aes_core (
    input  wire         clk,
    input  wire         reset_n,
    input  wire [255:0] key,         // 256-bit AES key
    input  wire [127:0] plaintext,   // Input block (e.g., counter block)
    input  wire         start,       // Signal to start encryption
    output reg  [127:0] ciphertext,  // Encrypted output
    output reg          ready        // Asserted when output is valid
);

    // Internal registers (for demonstration)
    reg [3:0] round_counter;
    reg processing;

    // Placeholder round key schedule and block
    reg [127:0] block;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            round_counter <= 4'd0;
            processing    <= 1'b0;
            ready         <= 1'b0;
            ciphertext    <= 128'd0;
        end else begin
            if (start && !processing) begin
                // Start encryption
                processing    <= 1'b1;
                round_counter <= 4'd0;
                block         <= plaintext ^ key[255:128]; // Initial AddRoundKey
                ready         <= 1'b0;
            end else if (processing) begin
                round_counter <= round_counter + 1;

                // Placeholder for AES round logic
                block <= block ^ key[127:0]; // Fake logic for now

                if (round_counter == 4'd13) begin
                    ciphertext <= block;
                    ready      <= 1'b1;
                    processing <= 1'b0;
                end
            end else begin
                ready <= 1'b0;
            end
        end
    end
endmodule


module aes_gcm_decrypt (
    input wire clk,
    input wire reset_n,
    input wire [255:0] key,
    input wire [255:0] iv,
    input wire [31:0] ciphertext,
    input wire ciphertext_valid,
    output reg [31:0] plaintext,
    output reg plaintext_valid,
    output reg tag_valid,
    output reg complete
);
    //Internal states
    reg [31:0] counter;           //counter input to AES
    reg [31:0] data_count;
    reg [127:0] aes_output;     //output from AES block
    reg busy;
    reg start_aes;
    wire aes_ready;

   // AES block instantiation
    aes_core aes_inst (
        .clk(clk),
        .reset_n(reset_n),
        .key(key),
        .plaintext(counter_block),     // In CTR mode, AES input is the counter block
        .start(start_aes),
        .ciphertext(aes_output),
        .ready(aes_ready)
    );

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 32'd0;
            data_count <= 32'd0;
            busy <= 1'b0;
            complete <= 1'b0;
            plaintext <= 32'd0;
            plaintext_valid <= 1'b0;
            tag_valid <= 1'b0;
            start_aes <= 1'b0;
        end else begin
            plaintext_valid <= 1'b0;
            start_aes <= 1'b0;

            if (ciphertext_valid && !busy) begin
                busy <= 1'b1;
                data_count <= 32'd1;
                counter <= { iv, 32'd1};
                start_aes <= 1'b1;
                complete <= 1'b0;
            end else if (ciphertext_valid && busy && aes_ready) begin
                data_count <= data_count + 32'd1;
                counter <= {iv, data_count + 1};
                start_aes <= 1'b1;

                // In a real implementation, this would decrypt using AES-GCM
                // For simplicity, we just XOR with a derived key byte
                plaintext <= ciphertext ^ aes_output [127:96];
                plaintext_valid <= 1'b1;
            end else if (busy && !ciphertext_valid && aes_ready) begin
                counter <= counter + 32'd1;
            end else if (busy && counter >= 32'd100) begin
                tag_valid <= 1'b1;  // Simplified - would verify authentication tag
                complete <= 1'b1;
                busy <= 1'b0;
            end
        end
    end
endmodule
