/*
------------------------------------------------------------------------------
--  Project     : ASCON-128 FPGA Implementation
--  Author      : Vu Hieu Hoang
--  Affiliation : Ho Chi Minh Metropolitan - Viet Nam
--  File        : ascon_round.sv
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

module asconp_round (
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic [3:0] round_count,  // total rounds (e.g. 12 or 6)
    input  logic [63:0] x0_in,
    input  logic [63:0] x1_in,
    input  logic [63:0] x2_in,
    input  logic [63:0] x3_in,
    input  logic [63:0] x4_in,
    output logic [63:0] x0_out,
    output logic [63:0] x1_out,
    output logic [63:0] x2_out,
    output logic [63:0] x3_out,
    output logic [63:0] x4_out,
    output logic done,
    output logic busy
);

    // --- Internal signals ---
    typedef enum logic [1:0] {
        IDLE,
        RUN,
        DONE
    } state_t;

    state_t state, next_state;

    logic [3:0] round;
    logic [63:0] x0, x1, x2, x3, x4;

    // --- Round constants ---
    function automatic logic [63:0] rc(input logic [3:0] r);
        return 64'h0F0E0D0C0B0A0908 >> (r * 4); // simplified constant (can replace with official)
    endfunction

    // --- State machine ---
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            round <= 0;
        end else begin
            state <= next_state;
            if (state == RUN)
                round <= round + 1;
            else if (state == IDLE)
                round <= 0;
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE:  if (start) next_state = RUN;
            RUN:   if (round == round_count - 1) next_state = DONE;
            DONE:  next_state = IDLE;
        endcase
    end

    assign done = (state == DONE);
    assign busy = (state == RUN);

    // --- Permutation Core (simplified) ---
    // You can replace this logic with official Ascon S-box + Linear Layer

     logic [63:0] t0, t1, t2, t3, t4;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            x0 <= 0; x1 <= 0; x2 <= 0; x3 <= 0; x4 <= 0;
        end else if (state == IDLE && start) begin
            x0 <= x0_in;
            x1 <= x1_in;
            x2 <= x2_in;
            x3 <= x3_in;
            x4 <= x4_in;
        end else if (state == RUN) begin
            // Add Round Constant (simplified)
            x2 <= x2 ^ rc(round);

            // Substitution layer (χ – simplified version)
            t0 = x0 ^ (~x1 & x2);
            t1 = x1 ^ (~x2 & x3);
            t2 = x2 ^ (~x3 & x4);
            t3 = x3 ^ (~x4 & x0);
            t4 = x4 ^ (~x0 & x1);
            x0 <= t0;
            x1 <= t1;
            x2 <= t2;
            x3 <= t3;
            x4 <= t4;

            // Linear diffusion (π, ρ – simplified rotations)
            x0 <= {x0[18:0], x0[63:19]}; // ROTR19
            x1 <= {x1[60:0], x1[63:61]}; // ROTR3
            x2 <= {x2[27:0], x2[63:28]}; // ROTR28
            x3 <= {x3[39:0], x3[63:40]}; // ROTR24
            x4 <= {x4[61:0], x4[63:62]}; // ROTR2
        end
    end

    // Output assignment
    assign x0_out = x0;
    assign x1_out = x1;
    assign x2_out = x2;
    assign x3_out = x3;
    assign x4_out = x4;

endmodule
