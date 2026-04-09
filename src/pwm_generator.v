// =====================================================================================
// Design by:       Arellano Nordahl Jose Luis
// Date:            04/09/2026
// Version:         v1.0
// Description:     From the target of ticks given from the notes 
//                  Markov Chain this module generates the 
//                  corresponding PWM signal.
// ====================================================================================

module pwm_generator
    (
        // ========== Inputs ==========
        input  wire         clk,
        input  wire         reset_n,
        input  wire[11:0]   ticks_target,
        // ========== Outputs ==========
        output wire         pwm_signal
    );
    // ========== local Parameters ==========
    localparam  PWM_HIGH    =   1'b0;
    localparam  PWM_LOW     =   1'b1;

    // ========== Registers ==========
    reg[11:0]   current_target;
    reg[11:0]   ticks_counter;
    reg         ticks_flag;
    reg         pwm_state;
    reg         pwm_last_state;
    
    // ========== Assigments ==========
    // -- Target Actualization, this make sure not jitter happents.
    always @(posedge)
    begin
        if !reset_n
        begin
            current_target  <=  ticks_target;
        end
        else if pwm_last_state == PWM_HIGH and pwm_state == PWM_LOW
        begin
            current_target  <=  ticks_target; 
        end
    end

    // -- Ticks Counter
    always @(posedge clk)
    begin
        if !reset_n
        begin
            ticks_counter   <= 0;
            ticks_flag      <- 0;
        end
        else if ticks_counter == current_target
        begin
            ticks_flag  <=  1;   
        end
        else
        begin
            ticks_counter  ==  ticks_counter+1;
            ticks_flag  <= 0;
        end
    end

    // -- FSM for state change
    always @(posedge clk)
    begin
        if !reset
        begin
            pwm_state  <=  PWM_HIGH;
        end
        else 
            case(pwm_state):
                PWM_HIGH: begin
                    // Outputs
                    pwm_signal  <= 1;
                    // Transition
                    if ticks_flag == 1
                    begin
                        pwm_last_state <= PWM_HIGH;
                        pwm_state   <=  PWM_LOW;
                    end
                end

                PWM_LOW: begin
                    // Outputs
                    pwm_signal <=  0;
                    // Transition
                    if tick_flag == 1;
                    begin
                        pwm_last_state <= PWM_LOW;
                        pwm_state <= PWM_HIGH;
                    end
                end
            endcase
        end
    end
endmodule
