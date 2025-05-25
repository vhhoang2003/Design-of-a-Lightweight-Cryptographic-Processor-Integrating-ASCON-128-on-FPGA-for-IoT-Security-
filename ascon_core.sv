/*
------------------------------------------------------------------------------
--  Project     : ASCON-128 FPGA Implementation
--  Author      : Vu Hieu Hoang
--  Affiliation : Ho Chi Minh Metropolitan - Viet Nam
--  File        : ascon_core.sv
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

module ascon_core (
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic mode, // 0 = encrypt, 1 = decrypt
    input  logic [`KEY_WIDTH-1:0]   key,
    input  logic [`NONCE_WIDTH-1:0] nonce,
    input  logic [`RATE-1:0]        data_in,
    output logic [`RATE-1:0]        data_out,
    output logic done
);

    // FSM control signals
    logic        fsm_enable;
    logic        fsm_round_start;
    logic [2:0]  fsm_phase;
    logic [3:0]  fsm_total_rounds;
    logic        fsm_done;
    logic        fsm_busy;

    // Round status
    logic        round_done;

    // Datapath output
    logic [`RATE-1:0] datapath_out;

    // FSM instance
    ascon_fsm_control fsm (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .busy(fsm_busy),
        .round_done(round_done),
        .done(fsm_done),
        .enable(fsm_enable),
        .round_start(fsm_round_start),
        .phase(fsm_phase),
        .total_rounds(fsm_total_rounds)
    );

    // Datapath
    ascon_datapath datapath (
        .clk(clk),
        .rst(rst),
        .phase(fsm_phase),
        .enable(fsm_enable),
        .round_start(fsm_round_start),
        .total_rounds(fsm_total_rounds),
        .data_in(data_in),
        .data_out(datapath_out),
        .round_done(round_done),
        .key(key),
        .nonce(nonce)
    );

    // Output assignment
    assign data_out = datapath_out;
    assign done     = fsm_done;

endmodule
