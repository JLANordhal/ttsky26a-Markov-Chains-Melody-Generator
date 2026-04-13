/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_Melody_Generator_JLANordhal(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out[7:1] = 0; 
  assign uio_out = 0;
  assign uio_oe  = 0;
    
  // ========== List all unused inputs to prevent warnings ==========
  wire _unused = &{uio_in, ui_in[7:6], 1'b0};
  
  // ========== Wires ==========
  wire[15:0]    rnd;
  wire          enable;
  wire[11:0]    ticks_target;
  wire          pwm_signal;
  
  assign uo_out[0] =  pwm_signal;
  // ========== Instances ==========
  // -- LFSR Instance
  lfsr U1_lfsr(
    .clk(clk),
    .reset_n(rst_n),
    .enable(enable),
    .seed_low(ui_in[3:0]),
    .rnd(rnd)
  );
  
  // -- Markov_chain_fsm Instance
  markov_chain_fsm U1_markov_chain_fsm
  (
    .clk(clk),
    .reset_n(rst_n),
    .BPM_sel(ui_in[4]),
    .duration_prob_trans_matrix_sel(ui_in[5]),
    .rnd(rnd),
    .enable_rnd(enable),
    .ticks_target(ticks_target)
  );
  
  // -- PWM_Generator Instance
  pwm_generator U1_pwm_generator
  (
    .clk(clk),
    .reset_n(rst_n),
    .ticks_target(ticks_target),
    .pwm_signal(pwm_signal)
  );
endmodule
