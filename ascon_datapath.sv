
/*
------------------------------------------------------------------------------
--  Project     : ASCON-128 FPGA Implementation
--  Author      : Vu Hieu Hoang
--  Affiliation : Ho Chi Minh Metropolitan - Viet Nam
--  File        : ascon_datapath.sv
--  Description : Lightweight AEAD encryption core for FPGA-based IoT security
--
--  License     : Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)
--                You are free to use, modify, and distribute this code for academic
--                or non-commercial purposes, provided that proper credit is given
--                to the author. Commercial use requires written permission.
--
--  Copyright (c) 2025 Vu Hieu Hoang
------------------------------------------------------------------------------
*/
`include "config.sv"

module ascon_datapath (
    input  logic clk,
    input  logic rst,

    // Điều khiển từ FSM
    input  logic [2:0] phase,          // 0:init, 1:absorb, 2:encrypt, 3:decrypt, 4:final
    input  logic       enable,
    input  logic       round_start,
    input  logic [3:0] total_rounds,   // thường là 12 (P12) hoặc 6 (P6)
    input  logic [`RATE-1:0] data_in,  // plaintext hoặc associated data

    input  logic [`KEY_WIDTH-1:0]   key,
    input  logic [`NONCE_WIDTH-1:0] nonce,
    // Output
    output logic [`RATE-1:0] data_out, // ciphertext hoặc plaintext
    output logic             round_done

);


    // Trạng thái của 5 thanh ghi ASCON
    logic [63:0] x0, x1, x2, x3, x4;

    // Kết nối với round core
    logic [63:0] xr0, xr1, xr2, xr3, xr4;
    logic        busy, done;

    // Round core instantiation
    asconp_round round_unit (
        .clk(clk),
        .rst(rst),
        .start(round_start),
        .round_count(total_rounds),
        .x0_in(x0), .x1_in(x1), .x2_in(x2), .x3_in(x3), .x4_in(x4),
        .x0_out(xr0), .x1_out(xr1), .x2_out(xr2), .x3_out(xr3), .x4_out(xr4),
        .busy(busy),
        .done(done)
    );

    assign round_done = done;

    // Giai đoạn xử lý dữ liệu
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            x0 <= 64'd0;
            x1 <= 64'd0;
            x2 <= 64'd0;
            x3 <= 64'd0;
            x4 <= 64'd0;
            data_out <= 0;
        end else if (enable) begin
            case (phase)

                3'd0: begin  // Initialize
                    x0 <= 64'h80400c0600000000; // IV của ASCON-128
                    x1 <= `KEY_WIDTH == 128 ? key[127:64] : 64'd0;
                    x2 <= `KEY_WIDTH == 128 ? key[63:0]   : 64'd0;
                    x3 <= `NONCE_WIDTH == 128 ? nonce[127:64] : 64'd0;
                    x4 <= `NONCE_WIDTH == 128 ? nonce[63:0]   : 64'd0;
                end

                3'd1: begin  // Absorb AD
                    x0 <= x0 ^ data_in; // XOR AD vào
                end

                3'd2: begin  // Encrypt
                    x0 <= x0 ^ data_in; // XOR Plaintext vào
                    data_out <= x0 ^ data_in; // Ciphertext = x0 ^ m
                end

                3'd3: begin  // Decrypt
                    data_out <= x0 ^ data_in; // m = x0 ^ c
                    x0 <= x0 ^ data_out;      // cập nhật x0
                end

                3'd4: begin  // Final
                    // không làm gì ở đây, sẽ xử lý trong round
                end
            endcase
        end else if (done) begin
            // Cập nhật kết quả sau round
            x0 <= xr0;
            x1 <= xr1;
            x2 <= xr2;
            x3 <= xr3;
            x4 <= xr4;
        end
    end

endmodule
