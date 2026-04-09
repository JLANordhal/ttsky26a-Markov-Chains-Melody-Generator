// ================================================================================
// Design by:   Arellano Nordahl Jose Luis
// Date:        04/06/2026
// Version:     v1.0
// Description: This module generates a pseudorandom number to perform the jumps
//              on the Markov Chains. 
// ================================================================================

module lfsr
(
   // ========== Inputs ==========
   input  wire      clk,
   input  wire      reset_n,
   input  wire      enable,
   input  wire[3:0] seed_low,
   // ========== Outputs ==========
   output wire[15:0] rnd
);

    // ========== Register ========== 
    reg[15:0] shift_reg;

    // ========== Wires ==========
    wire feedback;

    // ========== Assigments ==========    
    
    // Feedback bit that enters the register.
    assign feedback = shift_reg[16]^shift_reg[14]^shift_reg[13]^shift_reg[11];

    // Secuencial process that generates the random number.
    always @(posedge clk)
    begin

        if !reset_n                                       
        begin
            shift_reg   <=  {12'hCA5, seed_low}; 
        end

        else
        begin
            if enable
            begin
                shift_reg   <=  {shift_reg[14:0], feedback};
            end
        end
    end

    // Rnd assign
    assign rnd = shift_reg;

endmodule 
