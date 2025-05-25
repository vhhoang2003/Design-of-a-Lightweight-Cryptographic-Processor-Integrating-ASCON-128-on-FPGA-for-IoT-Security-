/*
------------------------------------------------------------------------------
--  Project     : ASCON-128 FPGA Implementation
--  Author      : Vu Hieu Hoang
--  Affiliation : Ho Chi Minh Metropolitan - Viet Nam
--  File        : ascon_fsm_control.sv
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

module ascon_fsm_control (
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic mode,  // 0 = encrypt, 1 = decrypt
    input  logic busy,        // từ asconp_round
    input  logic round_done,  // từ asconp_round
    output logic done,
    output logic enable,      // cấp phép cho datapath
    output logic round_start, // trigger round
    output logic [2:0] phase,
    output logic [3:0] total_rounds
);

    typedef enum logic [2:0] {
        IDLE     = 3'd0,
        INIT     = 3'd1,
        ABSORB   = 3'd2,
        PROCESS  = 3'd3,  // ENCRYPT or DECRYPT
        FINAL    = 3'd4,
        DONE     = 3'd5
    } state_t;

    state_t state, next_state;

    // Phase output = current state
    assign phase = state;

    // ASCON thường dùng P12 → 12 round
    assign total_rounds = 4'd12;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always_comb begin
        next_state   = state;
        enable       = 0;
        round_start  = 0;
        done         = 0;

        case (state)
            IDLE: begin
                if (start)
                    next_state = INIT;
            end

            INIT: begin
                enable = 1;
                round_start = 1;
                if (round_done)
                    next_state = ABSORB;
            end

            ABSORB: begin
                enable = 1;
                round_start = 1;
                if (round_done)
                    next_state = PROCESS;
            end

            PROCESS: begin
                enable = 1;
                round_start = 1;
                if (round_done)
                    next_state = FINAL;
            end

            FINAL: begin
                enable = 1;
                round_start = 1;
                if (round_done)
                    next_state = DONE;
            end

            DONE: begin
                done = 1;
                next_state = IDLE;
            end
        endcase
    end

endmodule
