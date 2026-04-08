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
    input  wire         duration_prob_trans_matrix_sel, 
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
    parameter SOL   =   3'b100;
    parameter LA    =   3'b101;

    // -- Durations FSM states
    parameter  QUAVER       =   2'b00;  // 1 quaver 
    parameter  CROTCHET     =   2'b01;  // 2 quaver
    parameter  MINIM        =   2'b10;  // 4 quaevr
    parameter  SEMIBREVE    =   2'b11;  // 8 quaver
    
    // ========== Registers =========
    reg[20:0] BPM_conuter;
    reg[3:0]  quaver_cycles_target;
    reg[3:0]  quaver_cycles_done;
    reg[1:0]  duration_FSM_state;
    reg[15:0] duration_prob_trans_matrix[0:3][0:3];  // -- 4x4 matrix of 16 bits arrays.
    reg       duration_done;
    reg[2:0]  note_FSM_state;
    reg[7:0]  note_prob_trans_matrx[0:5][0:5];      // -- 6x6 matrix of 8 bits arrays.
    
    // ========== Matrix initialization ==========
    // -- Probability transition matrix for the duration Markov chain
    initial
    begin
        // -- QUAVER ROW
        duration_prob_trans_matrix[0][0]    =   16'hAAAA;   // -- From quaver to quaver. 
        duration_prob_trans_matrix[0][1]    =   16'hAAAA;   // -- From quaver to crotchet. 
        duration_prob_trans_matrix[0][2]    =   16'hAAAA;   // -- From quaver to minim.
        duration_prob_trans_matrix[0][3]    =   16'hAAAA;   // -- From quaver to semibreve.
        // -- CROTCHET ROW
        duration_prob_trans_matrix[1][0]    =   16'hAAAA;   // -- From crotchet to quaver.
        duration_prob_trans_matrix[1][1]    =   16'hAAAA;   // -- From crotchet to crotchet.
        duration_prob_trans_matrix[1][2]    =   16'hAAAA;   // -- From crotchet to minim.
        duration_prob_trans_matrix[1][3]    =   16'hAAAA;   // -- From crotchet to semibreve.
        // -- MIMINM ROW
        duration_prob_trans_matrix[2][2]    =   16'hAAAA;   // -- From minim to quvaer.
        duration_prob_trans_matrix[2][2]    =   16'hAAAA;   // -- From minim to crotchet.
        duration_prob_trans_matrix[2][2]    =   16'hAAAA;   // -- From minim to minim.
        duration_prob_trans_matrix[2][2]    =   16'hAAAA;   // -- From minim to semibreve.
        // -- SENMIBREVE ROW
        duration_prob_trans_matrix[3][2]    =   16'hAAAA;   // -- From semibreve to quaver.
        duration_prob_trans_matrix[3][2]    =   16'hAAAA;   // -- From semibreve to crotchet.
        duration_prob_trans_matrix[3][2]    =   16'hAAAA;   // -- From semibreve to minim.
        duration_prob_trans_matrix[3][2]    =   16'hAAAA;   // -- From semibreve to semibreve.
    end 

    // -- Probability transition matrix for the note Markov chain
    initial begin
        // -- MUTE ROW  
        note_prob_trans_matrix[0][0]    =   8'hAA;   // -- From mute to mute. 
        note_prob_trans_matrix[0][1]    =   8'hAA;   // -- From mute to Do. 
        note_prob_trans_matrix[0][2]    =   8'hAA;   // -- From mute to Re.
        note_prob_trans_matrix[0][3]    =   8'hAA;   // -- From mute to Mi.
        note_prob_trans_matrix[0][4]    =   8'hAA;   // -- From mute to Sol. 
        note_prob_trans_matrix[0][5]    =   8'hAA;   // -- From mute to La.
        // -- DO ROW
        note_prob_trans_matrix[1][0]    =   8'hAA;   // -- From Do to mute. 
        note_prob_trans_matrix[1][1]    =   8'hAA;   // -- From Do to Do. 
        note_prob_trans_matrix[1][2]    =   8'hAA;   // -- From Do to Re.
        note_prob_trans_matrix[1][3]    =   8'hAA;   // -- From Do to Mi.
        note_prob_trans_matrix[1][4]    =   8'hAA;   // -- From Do to Sol. 
        note_prob_trans_matrix[1][5]    =   8'hAA;   // -- From Do to La.
        // -- RE ROW
        note_prob_trans_matrix[2][0]    =   8'hAA;   // -- From Re to mute. 
        note_prob_trans_matrix[2][1]    =   8'hAA;   // -- From Re to Do. 
        note_prob_trans_matrix[2][2]    =   8'hAA;   // -- From Re to Re.
        note_prob_trans_matrix[2][3]    =   8'hAA;   // -- From Re to Mi.
        note_prob_trans_matrix[2][4]    =   8'hAA;   // -- From Re to Sol. 
        note_prob_trans_matrix[2][5]    =   8'hAA;   // -- From Re to La.
        // -- MI ROW
        note_prob_trans_matrix[3][0]    =   8'hAA;   // -- From Mi to mute. 
        note_prob_trans_matrix[3][1]    =   8'hAA;   // -- From Mi to Do. 
        note_prob_trans_matrix[3][2]    =   8'hAA;   // -- From Mi to Re.
        note_prob_trans_matrix[3][3]    =   8'hAA;   // -- From Mi to Mi.
        note_prob_trans_matrix[3][4]    =   8'hAA;   // -- From Mi to Sol. 
        note_prob_trans_matrix[3][5]    =   8'hAA;   // -- From Mi to La.
        // -- SOL ROW
        note_prob_trans_matrix[4][0]    =   8'hAA;   // -- From Sol to mute. 
        note_prob_trans_matrix[4][1]    =   8'hAA;   // -- From Sol to Do. 
        note_prob_trans_matrix[4][2]    =   8'hAA;   // -- From Sol to Re.
        note_prob_trans_matrix[4][3]    =   8'hAA;   // -- From Sol to Mi.
        note_prob_trans_matrix[4][4]    =   8'hAA;   // -- From Sol to Sol. 
        note_prob_trans_matrix[4][5]    =   8'hAA;   // -- From Sol to La.
        // -- LA row
        note_prob_trans_matrix[5][0]    =   8'hAA;   // -- From La to mute. 
        note_prob_trans_matrix[5][1]    =   8'hAA;   // -- From La to Do. 
        note_prob_trans_matrix[5][2]    =   8'hAA;   // -- From La to Re.
        note_prob_trans_matrix[5][3]    =   8'hAA;   // -- From La to Mi.
        note_prob_trans_matrix[5][4]    =   8'hAA;   // -- From La to Sol. 
        note_prob_trans_matrix[5][5]    =   8'hAA;   // -- From La to La.
    end

    // ========== Wires ==========

    // ========== Concurrent Assigments ==========
    // -- Frequncy divider duration of a quaver.
    always @(posedge clk)
    begin
        if !reset_n
        begin
            BPM_counter <= 0;
        end
        else if !BPM_sel 
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
        if !reset                                  // -- Synchronus reset.
        begin
            // -- initialize to crotchet state
            quaver_cycles_target    <=  2;              
            duration_FSM_state      <=  2'b01;        
            quaver_cycles_done      <-  0;             
        end

        else if enable                             // -- Quaver cycle starts.
            // -- Defaults values
            duration_done   <=  0;                 // -- Kept up just for 1 cycle.

            // -- FSM output & transition logic
            case(duration_FSM_state)
                QUAVER:   begin
                    if quaver_cycles_done == quaver_cycles_target            // -- All cycles complete?
                    begin                                                    // -- Yes
                        quaver_cycles_done  <= 0;                            // -- Restart cycles for the next duraiton
                        duration_done       <= 1;                            // -- Indicates duration has finished
                        // -- Change of state based on MSByte of rnd
                        if !duration_prob_trans_matrix_sel                                 // -- Matrix A is selected:higher slower notes probability
                        begin
                            if rnd[15:8] == duration_prob_trans_matrix[0][0][15:8]         // -- Stays on quaver.
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if rnd[15:8] == duration_prob_tran_matrix[0][1][15:8]     // -- Transition to crotchet.
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[0][2][15:8]    // -- Transition to minim. 
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[0][3][15:8]    // -- transition to semibreve.
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                        else                                                               // -- Matrix B is selected:higher longer notes probability
                        begin
                            if rnd[15:8] == duration_prob_trans_matrix[0][0][7:0]          // -- Stays on quaver.
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if rnd[15:8] == duration_prob_tran_matrix[0][1][7:0]      // -- Transition to crotchet.
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[0][2][7:0]      // -- Transition to minim. 
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[0][3][7:0]      // -- transition to semibreve.
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                    end
                    else  // No, cycles not completed
                    begin
                        quaver_cycles_done <= quaver_cycles_done+1;         // -- increment cycles done
                    end
                end

                CROTCHET: begin
                    if quaver_cycles_done == quaver_cycles_target            // -- All cycles complete?
                    begin                                                    // -- Yes
                        quaver_cycles_done  <= 0;                            // -- Restart cycles for the next duraiton
                        duration_done       <= 1;                            // -- Indicates duration has finished
                        // -- Change of state based on MSByte of rnd
                        if !duration_prob_trans_matrix_sel                                 // -- Matrix A is selected:higher slower notes probability
                        begin
                            if rnd[15:8] == duration_prob_trans_matrix[1][0][15:8]         // -- Transition to quaver.
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if rnd[15:8] == duration_prob_tran_matrix[1][1][15:8]     // -- Stays on crotchet.
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[1][2][15:8]    // -- Transition to minim. 
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[1][3][15:8]    // -- Transition to semibreve.
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                        else                                                               // -- Matrix B is selected:higher longer notes probability
                        begin
                            if rnd[15:8] == duration_prob_trans_matrix[1][0][7:0]          // -- Transition on quaver.
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if rnd[15:8] == duration_prob_tran_matrix[1][1][7:0]      // -- Stays on crotchet.
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[1][2][7:0]      // -- Transition to minim. 
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[1][3][7:0]      // -- Transition to semibreve.
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                    end
                    else  // No, cycles not completed
                    begin
                        quaver_cycles_done <= quaver_cycles_done+1;         // -- increment cycles done
                    end
                end

                MINIM: begin
                    if quaver_cycles_done == quaver_cycles_target            // -- All cycles complete?
                    begin                                                    // -- Yes
                        quaver_cycles_done  <= 0;                            // -- Restart cycles for the next duraiton
                        duration_done       <= 1;                            // -- Indicates duration has finished
                        // -- Change of state based on MSByte of rnd
                        if !duration_prob_trans_matrix_sel                                 // -- Matrix A is selected:higher slower notes probability
                        begin
                            if rnd[15:8] == duration_prob_trans_matrix[2][0][15:8]         // -- Transition to quaver.
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if rnd[15:8] == duration_prob_tran_matrix[2][1][15:8]     // -- Transition to crotchet.
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[2][2][15:8]    // -- Stays on minim. 
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[2][3][15:8]    // -- Transition to semibreve.
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                        else                                                               // -- Matrix B is selected:higher longer notes probability
                        begin
                            if rnd[15:8] == duration_prob_trans_matrix[2][0][7:0]          // -- Transition to quaver.
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if rnd[15:8] == duration_prob_tran_matrix[2][1][7:0]      // -- Transition to crotchet.
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[2][2][7:0]      // -- Stays on minim. 
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[2][3][7:0]      // -- Transition to semibreve.
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                    end
                    else  // No, cycles not completed
                    begin
                        quaver_cycles_done <= quaver_cycles_done+1;         // -- increment cycles done
                    end
                end

                SEMIBREVE: begin
                    if quaver_cycles_done == quaver_cycles_target            // -- All cycles complete?
                    begin                                                    // -- Yes
                        quaver_cycles_done  <= 0;                            // -- Restart cycles for the next duraiton
                        duration_done       <= 1;                            // -- Indicates duration has finished
                        // -- Change of state based on MSByte of rnd
                        if !duration_prob_trans_matrix_sel                                 // -- Matrix A is selected:higher slower notes probability
                        begin
                            if rnd[15:8] == duration_prob_trans_matrix[3][0][15:8]         // -- Transition to quaver.
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if rnd[15:8] == duration_prob_tran_matrix[3][1][15:8]     // -- Transition to crotchet.
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[3][2][15:8]    // -- Transition to minim. 
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[3][3][15:8]    // -- Stays on semibreve.
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                        else                                                               // -- Matrix B is selected:higher longer notes probability
                        begin
                            if rnd[15:8] == duration_prob_trans_matrix[3][0][7:0]          // -- Transition to quaver.
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if rnd[15:8] == duration_prob_tran_matrix[3][1][7:0]      // -- Transition to crotchet.
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[3][2][7:0]      // -- Transition to minim. 
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else if rnd[15:8] == duration_prob_trans_matrix[3][3][7:0]      // -- Stays on semibreve.
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                    end
                    else  // No, cycles not completed
                    begin
                        quaver_cycles_done <= quaver_cycles_done+1;         // -- increment cycles done
                    end
                end
            endcase
        end
    end

    // FSM Notes
    always @(posedge clk)
    begin
        if !reset_n
        begin
            note_FSM_state  <=  DO;
        end
        else
        begin
            case(note_FSM_state)
                MUTE: begin
                    // -- Output
                    

                end

                DO: begin
                end

                RE: begin
                end

                MI: begin
                end

                SOL: begin
                end

                LA: begin
                end
            endcase
        end
    end
endmodule
