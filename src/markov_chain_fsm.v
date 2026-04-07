// ==========================================================
// Design by:       Arellano Nordahl Jose Luis
// Date:            04/06/2026
// Version;         v1.0
// Description:     Finite State Maachine for the Markov Chains
// =============================================================

module markov_chain_fsm
(
    // ========== Inputs ==========
    input  wire         clk,
    input  wire         reset_n,
    input  wire         BPM_sel,
    input  wire[1:0]    quaver_prob_sel, 
    input  wire[15:0]   rnd,
    // ========= Outputs =========
    output wire[]       note
);
    // ========== Parameters ==========
    // -- Notes FSM states
    parameter MUTE  =   3'b000;
    parameter DO    =   3'b001; 
    parameter RE    =   3'b010; 
    parameter MI    =   3'b011;
    parameter LA    =   3'b100;

    // -- Durations FSM states
    parameter  QUAVER       =   2'b00;  // 1 quaver 
    parameter  CROTCHET     =   2'b01;  // 2 quaver
    parameter  MINIM        =   2'b10;  // 4 quaevr
    parameter  SEMIBREVE    =   2'b11;  // 8 quaver
    
    // ========== Registers =========
    reg[20:0] BPM_conuter;
    reg[3:0]  quaver_cycles_target[3:0];
    reg[3:0]  quaver_cycles_done[3:0];
    reg[1:0]  duration_FSM_state[1:0];
    reg[15:0]  mrkov_matrix_duration[0:3][0:3];  // -- ROM 4x4 each   
    reg  duration_done;
    reg  note_FSM_state[];

    // ========== Wires ==========

    // ========== Concurrent Assigments ==========
    // -- Frequncy divider duration of a quaver.
    always @(posedge clk)
    begin
        if !reset_n
        begin
            BPM_counter <= 0;
        end
        else if BPM_sel == 0 
        begin
            if BPM_counter > 21'h10000      // 120 BPM  
            begin
                BPM_counter <= 0;
                enable <= 0,
            end
        end
        else if BPM_sel == 1
        begin
            if BPM_counter == 21'h20000     // 60 BPM 
            begin
                BPM_counter <= 0;
                enable <= 0;
            end
        end
        else if BPM_counter[19] == 1  
        begin
            enable <= 1;
            BPM_counter <= BPM_counter+1;
        end 
        else
        begin
            BPM_conuter <= BMP_counter+1;
        end
    end
    
    // FSM Duratio
    always @(posedge clk)
    begin
        if !reset
        begin
            // -- initialize to a crotchet
            quaver_cycles_target    <=  2;              
            duration_FSM_state      <=  2'b01;        
            quaver_cycles_done      <-  0;             
        end

        else if enable 
            case(duration_FSM_state)
                QUAVER:   begin
                    if quaver_cycles_done == quaver_cycles_target
                    begin
                        quaver_cycles_done  <= 0;                            // -- Restart cycles for the next duraiton
                        duration_done       <= 1;                            // -- Indicates duration has finished
                        // -- Change of state based on MSByte of rnd
                        
                    end
                    else
                    begin
                        quaver_cycles_done <= quaver_cycles_done+1;
                    end
                end

                CROTCHET: begin
                end

                MINIM: begin
                end

                SEMIBREVE: begin
                end
            endcase
        begin
            

        end
    end
    // FSM Notes
    

endmodule
