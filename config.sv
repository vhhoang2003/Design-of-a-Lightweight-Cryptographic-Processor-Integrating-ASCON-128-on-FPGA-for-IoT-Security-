/*
------------------------------------------------------------------------------
--  Project     : ASCON-128 FPGA Implementation
--  Author      : Vu Hieu Hoang
--  Affiliation : Ho Chi Minh Metropolitan - Viet Nam
--  File        : config.sv
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


`define RATE        64
`define KEY_WIDTH   128
`define NONCE_WIDTH 128
`define TAG_WIDTH   128
`define STATE_WIDTH 320
