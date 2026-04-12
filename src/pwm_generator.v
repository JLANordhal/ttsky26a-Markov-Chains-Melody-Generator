// =====================================================================================
// Design by:       Arellano Nordahl Jose Luis
// Date:            09/04/2026
// Version:         v1.0 
// Date:            04/09/2026// Description:     PWM Generator with integrated MUTE support.
// =====================================================================================

module pwm_generator
    (
        input  wire          clk,
        input  wire          reset_n,
        input  wire[11:0]    ticks_target,
        output wire          pwm_signal
    );

    localparam  PWM_HIGH    =   1'b1;
    localparam  PWM_LOW     =   1'b0;
    localparam  MUTE_TARGET =   12'd0; 
    
    wire        ticks_done;
    reg[11:0]   current_target;
    reg[11:0]   ticks_counter;
    reg         pwm_state;
    reg         pwm_signal_reg;

    assign pwm_signal = pwm_signal_reg;
    assign ticks_done = (ticks_counter == current_target);
    
    // Ticks Counter logic
    always @(posedge clk)
    begin
        if (!reset_n)
            ticks_counter <= 0;
        else if (ticks_target == MUTE_TARGET || ticks_done)
            ticks_counter <= 0; 
        else
            ticks_counter <= ticks_counter + 1'b1;
    end
    
    // Target update logic with Anti-lock protection
    always @(posedge clk)
    begin
        if (!reset_n)
            current_target <= 12'd1000;
        // Immediate update if entering/exiting MUTE to avoid hang-ups
        else if (ticks_target == MUTE_TARGET || current_target == MUTE_TARGET)
            current_target <= ticks_target;
        // Synchronized update at the end of PWM cycle to prevent jitter
        else if (ticks_done && pwm_state == PWM_LOW)
            current_target <= ticks_target; 
    end

    // FSM for PWM state transitions
    always @(posedge clk)
    begin
        if (!reset_n) begin
            pwm_state      <= PWM_HIGH;
            pwm_signal_reg <= 1'b0;
        end
        // Force MUTE: Keep FSM in LOW state and output at 0
        else if (ticks_target == MUTE_TARGET) begin
            pwm_state      <= PWM_LOW; 
            pwm_signal_reg <= 1'b0;
        end
        else begin
            case(pwm_state)
                PWM_HIGH: begin
                    pwm_signal_reg <= 1'b1;
                    if (ticks_done) pwm_state <= PWM_LOW;
                end
                PWM_LOW: begin
                    pwm_signal_reg <= 1'b0;
                    if (ticks_done) pwm_state <= PWM_HIGH;
                end
            endcase
        end
    end
endmodule