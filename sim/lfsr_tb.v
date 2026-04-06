// ==================================================================
// Author:      Arellano Nordahl Jose Luis
// Date:        04/06/2026
// Version:     v1.0
// Description: Simulation file for the lsfr module.
// ==================================================================

`timescale 1ns/1ps

module lfsr_tb;
    
    // ========== Signal declaration ==========
    // ---------- Inputs ----------
    reg         clk;
    reg         reset_n;
    reg[3:0]    seed_low;
    // ---------- Outputs ----------
    wire[7:0]   rnd;

    // ========== Device Under Test ----------
    lfsr dut
    (
        .clk(clk),
        .reset_n(reset_n),
        .seed_low(seed_low),
        .rnd(rnd)
    );

    // ========== Clock generation ==========
    always #50 clk = ~clk;

    // ========== Stimulus Block ==========
    initial begin
        // Waveform dumping for GTKWave
        $dumpfile("lfsr_sim.vcd");
        $dumpvars(0, lfsr_tb);

        // Initialization
        clk = 0;
        reset_n = 0;          // Assert Reset (Active Low)
        seed_low = 4'h5;    // Initial seed fragment (0101)

        // Wait for 2 clock cycles then release reset
        #200 reset_n = 1;     // De-assert Reset

        // Let it run for a few cycles to observe the sequence
        repeat (30) @(posedge clk);

        // Test synchronous reset with a different seed
        $display("Applying synchronous reset with seed 4'hA...");
        @(negedge clk);     // Change inputs on negative edge to avoid race conditions
        reset_n = 0;
        seed_low = 4'hA;    // New seed (1010)
        
        #200 reset_n = 1;     // Release reset again

        // Run for more cycles
        repeat (30) @(posedge clk);

        $display("Simulation finished. Check 'lfsr_sim.vcd' in GTKWave.");
        $finish;            // Stop the simulator
    end

    // --- Monitor---
    // Prints the value of 'rnd' to the console every time it changes
    initial begin
        $monitor("Time: %0t | Reset: %b | LFSR Output: %h (%b)", 
                 $time, reset_n, rnd, rnd);
    end

endmodule
