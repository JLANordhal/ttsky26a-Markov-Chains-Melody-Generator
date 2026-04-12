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
    output wire             enable_rnd,
    output wire[11:0]       ticks_target
);
    // ========== Local Parameters ==========
    // -- Notes FSM states
    localparam MUTE  =   3'b000;
    localparam DO    =   3'b001; 
    localparam RE    =   3'b010; 
    localparam MI    =   3'b011;
    localparam SOL   =   3'b100;
    localparam LA    =   3'b101;

    // -- Durations FSM states
    localparam  QUAVER       =   2'b00;  // 1 quaver 
    localparam  CROTCHET     =   2'b01;  // 2 quaver
    localparam  MINIM        =   2'b10;  // 4 quaevr
    localparam  SEMIBREVE    =   2'b11;  // 8 quaver
    // ========== Wires ==========
    wire duration_done_rise; 
    // ========== Registers =========
    reg[20:0] BPM_counter;
    reg[3:0]  quaver_cycles_target;
    reg[3:0]  quaver_cycles_done;
    reg[1:0]  duration_FSM_state;
    reg[15:0] duration_prob_trans_matrix[0:3][0:3];  // -- 4x4 matrix of 16 bits arrays.
    reg       duration_done;
    reg[2:0]  note_FSM_state;
    reg[7:0]  note_prob_trans_matrix[0:5][0:5];      // -- 6x6 matrix of 8 bits arrays.
    reg       enable;
    reg[11:0] ticks_target_reg;
    reg       duration_done_last;
    
    // ========== Matrix initialization ==========
    // -- Probability transition matrix for the duration Markov chain
    initial
    begin
        // -- QUAVER ROW
        duration_prob_trans_matrix[0][0]    =   16'h8C19;   // -- From quaver to quaver. A1: 55%, A2: 10%
        duration_prob_trans_matrix[0][1]    =   16'h4D26;   // -- From quaver to crotchet. A1: 30%, A2: 15%
        duration_prob_trans_matrix[0][2]    =   16'h1A73;   // -- From quaver to minim. A1: 10%, A2: 45%
        duration_prob_trans_matrix[0][3]    =   16'h0D4D;   // -- From quaver to semibreve. A1: 5%, A2: 30%
        // -- CROTCHET ROW
        duration_prob_trans_matrix[1][0]    =   16'h8019;   // -- From crotchet to quaver. A1: 50%, A2: 10%
        duration_prob_trans_matrix[1][1]    =   16'h5926;   // -- From crotchet to crotchet. A1: 35%, A2: 15%
        duration_prob_trans_matrix[1][2]    =   16'h1A73;   // -- From crotchet to minim. A1: 10%, A2: 45%
        duration_prob_trans_matrix[1][3]    =   16'h0D4D;   // -- From crotchet to semibreve. A1: 5%, A2: 30%
        // -- MIMINM ROW
        duration_prob_trans_matrix[2][0]    =   16'h4D19;   // -- From minim to quaver. A1: 30%, A2: 10%
        duration_prob_trans_matrix[2][1]    =   16'h6626;   // -- From minim to crotchet. A1: 40%, A2: 15%
        duration_prob_trans_matrix[2][2]    =   16'h3373;   // -- From minim to minim. A1: 20%, A2: 45%
        duration_prob_trans_matrix[2][3]    =   16'h1A4D;   // -- From minim to semibreve. A1: 10%, A2: 30%
        // -- SEMIBREVE ROW
        duration_prob_trans_matrix[3][0]    =   16'h3319;   // -- From semibreve to quaver. A1: 20%, A2: 10%
        duration_prob_trans_matrix[3][1]    =   16'h4D26;   // -- From semibreve to crotchet. A1: 30%, A2: 15%
        duration_prob_trans_matrix[3][2]    =   16'h6673;   // -- From semibreve to minim. A1: 40%, A2: 45%
        duration_prob_trans_matrix[3][3]    =   16'h1A4D;   // -- From semibreve to semibreve. A1: 10%, A2: 30%
    end
    
    // -- Probability transition matrix for the note Markov chain
    initial begin
        // -- MUTE ROW  
        note_prob_trans_matrix[0][0]    =   8'h19;   // -- From mute to mute. 10%
        note_prob_trans_matrix[0][1]    =   8'h73;   // -- From mute to Do. 45%
        note_prob_trans_matrix[0][2]    =   8'h0D;   // -- From mute to Re. 5%
        note_prob_trans_matrix[0][3]    =   8'h0D;   // -- From mute to Mi. 5%
        note_prob_trans_matrix[0][4]    =   8'h4D;   // -- From mute to Sol. 30%
        note_prob_trans_matrix[0][5]    =   8'h0A;   // -- From mute to La. 5%
        // -- DO ROW
        note_prob_trans_matrix[1][0]    =   8'h0D;   // -- From Do to mute. 5%
        note_prob_trans_matrix[1][1]    =   8'h33;   // -- From Do to Do. 20%
        note_prob_trans_matrix[1][2]    =   8'h59;   // -- From Do to Re. 35%
        note_prob_trans_matrix[1][3]    =   8'h19;   // -- From Do to Mi. 10%
        note_prob_trans_matrix[1][4]    =   8'h33;   // -- From Do to Sol. 20%
        note_prob_trans_matrix[1][5]    =   8'h1A;   // -- From Do to La. 10%
        // -- RE ROW
        note_prob_trans_matrix[2][0]    =   8'h0D;   // -- From Re to mute. 5%
        note_prob_trans_matrix[2][1]    =   8'h66;   // -- From Re to Do. 40%
        note_prob_trans_matrix[2][2]    =   8'h26;   // -- From Re to Re. 15%
        note_prob_trans_matrix[2][3]    =   8'h4D;   // -- From Re to Mi. 30%
        note_prob_trans_matrix[2][4]    =   8'h0D;   // -- From Re to Sol. 5%
        note_prob_trans_matrix[2][5]    =   8'h10;   // -- From Re to La. 5%
        // -- MI ROW
        note_prob_trans_matrix[3][0]    =   8'h0D;   // -- From Mi to mute. 5%
        note_prob_trans_matrix[3][1]    =   8'h19;   // -- From Mi to Do. 10%
        note_prob_trans_matrix[3][2]    =   8'h59;   // -- From Mi to Re. 35%
        note_prob_trans_matrix[3][3]    =   8'h26;   // -- From Mi to Mi. 15%
        note_prob_trans_matrix[3][4]    =   8'h4D;   // -- From Mi to Sol. 30%
        note_prob_trans_matrix[3][5]    =   8'h0D;   // -- From Mi to La. 5%
        // -- SOL ROW
        note_prob_trans_matrix[4][0]    =   8'h0D;   // -- From Sol to mute. 5%
        note_prob_trans_matrix[4][1]    =   8'h4D;   // -- From Sol to Do. 30%
        note_prob_trans_matrix[4][2]    =   8'h0D;   // -- From Sol to Re. 5%
        note_prob_trans_matrix[4][3]    =   8'h40;   // -- From Sol to Mi. 25%
        note_prob_trans_matrix[4][4]    =   8'h26;   // -- From Sol to Sol. 15%
        note_prob_trans_matrix[4][5]    =   8'h33;   // -- From Sol to La. 20%
        // -- LA row
        note_prob_trans_matrix[5][0]    =   8'h19;   // -- From La to mute. 10%
        note_prob_trans_matrix[5][1]    =   8'h26;   // -- From La to Do. 15%
        note_prob_trans_matrix[5][2]    =   8'h0D;   // -- From La to Re. 5%
        note_prob_trans_matrix[5][3]    =   8'h19;   // -- From La to Mi. 10%
        note_prob_trans_matrix[5][4]    =   8'h66;   // -- From La to Sol. 40%
        note_prob_trans_matrix[5][5]    =   8'h34;   // -- From La to La. 20%
    end

    // ========== Concurrent Assigments ==========
    assign ticks_target = ticks_target_reg;
    assign enable_rnd = duration_done_rise;
    assign duration_done_rise = duration_done & ~duration_done_last;
    
    // -- Frequncy divider duration of a quaver.
    always @(posedge clk)
    begin
        if (!reset_n)
        begin
            BPM_counter <= 0;
            enable <= 0;
        end
        else if (!BPM_sel) 
        begin
            if (BPM_counter[19])                        // -- 120 BPM
            begin
                enable <= 1;
                BPM_counter <= 0;
            end 
            else
            begin
                enable  <= 0;
                BPM_counter <= BPM_counter+1;
            end  
        end
        else
        begin
            if (BPM_counter[20])                        // -- 60 BPM               
            begin
                enable <= 1;
                BPM_counter <= 0;
            end 
            else
            begin
                BPM_counter <= BPM_counter+1;
                enable <= 0;
            end
        end  
    end
    
    // duration_done rising edge detection 
    always @(posedge clk)
    begin
        if (!reset_n)
        begin
            duration_done_last <= 0;
        end
        else
        begin
            duration_done_last <= duration_done;
        end
    end
    
    // FSM Duration
    always @(posedge clk)
    begin
        if (!reset_n)                                   // -- Synchronous reset.
        begin
            // -- initialize to crotchet state
            quaver_cycles_target    <=  2;              
            duration_FSM_state      <=  CROTCHET;        
            quaver_cycles_done      <=  0;            
            duration_done           <=  0;
        end
        else   
        begin                           
        if (enable)                             // -- Quaver cycle starts.
        begin
            // -- FSM output & transition logic
            case(duration_FSM_state)
                QUAVER: begin
                    if (quaver_cycles_done == quaver_cycles_target)            // -- All cycles complete?
                    begin                                                    // -- Yes
                        quaver_cycles_done  <= 0;                            // -- Restart cycles for the next duration
                        duration_done       <= 1;                            // -- Indicates duration has finished
                        
                        if (!duration_prob_trans_matrix_sel)                 // -- Matrix A1 (Short notes)
                        begin
                            if (rnd[15:8] < duration_prob_trans_matrix[0][0][15:8])
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[0][0][15:8] + duration_prob_trans_matrix[0][1][15:8]))
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[0][0][15:8] + duration_prob_trans_matrix[0][1][15:8] + duration_prob_trans_matrix[0][2][15:8]))
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else 
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                        else                                                 // -- Matrix A2 (Long notes)
                        begin
                            if (rnd[15:8] < duration_prob_trans_matrix[0][0][7:0])
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[0][0][7:0] + duration_prob_trans_matrix[0][1][7:0]))
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[0][0][7:0] + duration_prob_trans_matrix[0][1][7:0] + duration_prob_trans_matrix[0][2][7:0]))
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else 
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                    end
                    else  // No, cycles not completed
                    begin
                        duration_done   <=  0;
                        quaver_cycles_done <= quaver_cycles_done + 1;         // -- increment cycles done
                    end
                end

                CROTCHET: begin
                    if (quaver_cycles_done == quaver_cycles_target)            // -- All cycles complete?
                    begin                                                    // -- Yes
                        quaver_cycles_done  <= 0;                            // -- Restart
                        duration_done       <= 1;
                        
                        if (!duration_prob_trans_matrix_sel)                 // -- Matrix A1
                        begin
                            if (rnd[15:8] < duration_prob_trans_matrix[1][0][15:8])
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[1][0][15:8] + duration_prob_trans_matrix[1][1][15:8]))
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[1][0][15:8] + duration_prob_trans_matrix[1][1][15:8] + duration_prob_trans_matrix[1][2][15:8]))
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else 
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                        else                                                 // -- Matrix A2
                        begin
                            if (rnd[15:8] < duration_prob_trans_matrix[1][0][7:0])
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[1][0][7:0] + duration_prob_trans_matrix[1][1][7:0]))
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[1][0][7:0] + duration_prob_trans_matrix[1][1][7:0] + duration_prob_trans_matrix[1][2][7:0]))
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else 
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                    end
                    else 
                    begin
                        duration_done   <=  0;
                        quaver_cycles_done <= quaver_cycles_done + 1;
                    end
                end

                MINIM: begin
                    if (quaver_cycles_done == quaver_cycles_target)
                    begin
                        quaver_cycles_done  <= 0;
                        duration_done       <= 1;
                        
                        if (!duration_prob_trans_matrix_sel)                 // -- Matrix A1
                        begin
                            if (rnd[15:8] < duration_prob_trans_matrix[2][0][15:8])
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[2][0][15:8] + duration_prob_trans_matrix[2][1][15:8]))
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[2][0][15:8] + duration_prob_trans_matrix[2][1][15:8] + duration_prob_trans_matrix[2][2][15:8]))
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else 
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                        else                                                 // -- Matrix A2
                        begin
                            if (rnd[15:8] < duration_prob_trans_matrix[2][0][7:0])
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[2][0][7:0] + duration_prob_trans_matrix[2][1][7:0]))
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[2][0][7:0] + duration_prob_trans_matrix[2][1][7:0] + duration_prob_trans_matrix[2][2][7:0]))
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else 
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                    end
                    else 
                    begin
                        duration_done   <=  0;
                        quaver_cycles_done <= quaver_cycles_done + 1;
                    end
                end

                SEMIBREVE: begin
                    if (quaver_cycles_done == quaver_cycles_target)
                    begin
                        quaver_cycles_done  <= 0;
                        duration_done       <= 1;
                        
                        if (!duration_prob_trans_matrix_sel)                 // -- Matrix A1
                        begin
                            if (rnd[15:8] < duration_prob_trans_matrix[3][0][15:8])
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[3][0][15:8] + duration_prob_trans_matrix[3][1][15:8]))
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[3][0][15:8] + duration_prob_trans_matrix[3][1][15:8] + duration_prob_trans_matrix[3][2][15:8]))
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else 
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                        else                                                 // -- Matrix A2
                        begin
                            if (rnd[15:8] < duration_prob_trans_matrix[3][0][7:0])
                            begin
                                duration_FSM_state      <=  QUAVER;
                                quaver_cycles_target    <=  1;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[3][0][7:0] + duration_prob_trans_matrix[3][1][7:0]))
                            begin
                                duration_FSM_state      <=  CROTCHET;
                                quaver_cycles_target    <=  2;
                            end
                            else if (rnd[15:8] < (duration_prob_trans_matrix[3][0][7:0] + duration_prob_trans_matrix[3][1][7:0] + duration_prob_trans_matrix[3][2][7:0]))
                            begin
                                duration_FSM_state      <=  MINIM;
                                quaver_cycles_target    <=  4;
                            end
                            else 
                            begin
                                duration_FSM_state      <=  SEMIBREVE;
                                quaver_cycles_target    <=  8;
                            end
                        end
                    end
                    else 
                    begin
                        duration_done   <=  0;
                        quaver_cycles_done <= quaver_cycles_done + 1;
                    end
                end
            endcase
        end
        end
    end    

    // FSM Notes
    always @(posedge clk)
    begin
        if (!reset_n)
        begin
            note_FSM_state  <=  DO;
            ticks_target_reg <= 1908;
        end
        else
        begin
            case(note_FSM_state)
                MUTE: begin
                    // -- Output
                    ticks_target_reg    <=  0;   // -- Mute Freq: 0 Hz -> Output set to zero.
                    // Transition
                    if (duration_done_rise)
                    begin
                        if (rnd[7:0] < note_prob_trans_matrix[0][0])         // -- Stays on mute 
                        begin
                            note_FSM_state  <=  MUTE;
                        end
                        else if (note_prob_trans_matrix[0][0] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[0][1])  // -- Transition to Do
                        begin
                            note_FSM_state  <=  DO;
                        end
                        else if (note_prob_trans_matrix[0][1]< rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[0][2])    // -- transition to Re
                        begin
                            note_FSM_state  <=  RE;
                        end
                        else if (note_prob_trans_matrix[0][2] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[0][3])    // -- Transition to Mi
                        begin
                            note_FSM_state  <=  MI;
                        end
                        else if (note_prob_trans_matrix[0][3] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[0][4])    // -- Transition to Sol
                        begin
                            note_FSM_state  <=  SOL;
                        end
                        else if (note_prob_trans_matrix[0][4] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[0][5])    // -- Transition to La
                        begin
                            note_FSM_state  <=  LA;
                        end
                    end
                end

                DO: begin
                    ticks_target_reg    <=  1908;   // -- Do freq: 262 Hz -> 1908 ticks for a 50% Dutty Cycle.
                    // Transition
                     if (duration_done_rise)
                    begin
                        if (rnd[7:0] < note_prob_trans_matrix[1][0])         // -- Transition to mute 
                        begin
                            note_FSM_state  <=  MUTE;
                        end
                        else if (note_prob_trans_matrix[1][0] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[1][1])    // -- Stays on Do
                        begin
                            note_FSM_state  <=  DO;
                        end
                        else if (note_prob_trans_matrix[1][1] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[1][2])    // -- transition to Re
                        begin
                            note_FSM_state  <=  RE;
                        end
                        else if (note_prob_trans_matrix[1][2] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[1][3])    // -- Transition to Mi
                        begin
                            note_FSM_state  <=  MI;
                        end
                        else if (note_prob_trans_matrix[1][3] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[1][4])    // -- Transition to Sol
                        begin
                            note_FSM_state  <=  SOL;
                        end
                        else if (note_prob_trans_matrix[1][4] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[1][5])    // -- Transition to La
                        begin
                            note_FSM_state  <=  LA;
                        end
                    end
                end

                RE: begin
                    ticks_target_reg   <=  1701;   // -- Re freq: 294 Hz -> 1701 ticks for a 50% Dutty Cycle.
                    // Transition
                     if (duration_done_rise)
                    begin
                        if (rnd[7:0] < note_prob_trans_matrix[2][0])         // -- Transition to mute 
                        begin
                            note_FSM_state  <=  MUTE;
                        end
                        else if (note_prob_trans_matrix[2][0] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[2][1])    // -- Transition to Do
                        begin
                            note_FSM_state  <=  DO;
                        end
                        else if (note_prob_trans_matrix[2][1] <rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[2][2])    // -- Stays on Re
                        begin
                            note_FSM_state  <=  RE;
                        end
                        else if (note_prob_trans_matrix[2][2]< rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[2][3])    // -- Transition to Mi
                        begin
                            note_FSM_state  <=  MI;
                        end
                        else if (note_prob_trans_matrix[2][3] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[2][4])    // -- Transition to Sol
                        begin
                            note_FSM_state  <=  SOL;
                        end
                        else if (note_prob_trans_matrix[2][4] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[2][5])    // -- Transition to La
                        begin
                            note_FSM_state  <=  LA;
                        end
                    end
                end

                MI: begin
                    ticks_target_reg    <=  1515;   // -- Mi freq: 330 Hz -> 1515 ticks for a 50% Dutty Cycle. 
                    // Transition
                    if (duration_done_rise)
                    begin
                        if (rnd[7:0] < note_prob_trans_matrix[3][0])        // -- Transition to mute 
                        begin
                            note_FSM_state  <=  MUTE;
                        end
                        else if(note_prob_trans_matrix[3][0] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[3][1])    // -- Transition to Do
                        begin
                            note_FSM_state  <=  DO;
                        end
                        else if (note_prob_trans_matrix[3][1] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[3][2])    // -- transition to Re
                        begin
                            note_FSM_state  <=  RE;
                        end
                        else if (note_prob_trans_matrix[3][2] <rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[3][3])    // -- Stays on Mi
                        begin
                            note_FSM_state  <=  MI;
                        end
                        else if (note_prob_trans_matrix[3][3] <rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[3][4])    // -- Transition to Sol
                        begin
                            note_FSM_state  <=  SOL;
                        end
                        else if (note_prob_trans_matrix[3][4]< rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[3][5])    // -- Transition to La
                        begin
                            note_FSM_state  <=  LA;
                        end
                    end
                end

                SOL: begin
                    ticks_target_reg    <=  1275;   // -- Sol freq: 392 Hz -> 1275 ticks for a 50% Dutty Cyle.
                    // Transition
                    if (duration_done_rise)
                    begin
                        if (rnd[7:0] < note_prob_trans_matrix[4][0])         // -- Transition to mute 
                        begin
                            note_FSM_state  <=  MUTE;
                        end
                        else if (note_prob_trans_matrix[4][0] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[4][1])    // -- Transition to Do
                        begin
                            note_FSM_state  <=  DO;
                        end
                        else if (note_prob_trans_matrix[4][1] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[4][2])    // -- transition to Re
                        begin
                            note_FSM_state  <=  RE;
                        end
                        else if (note_prob_trans_matrix[4][2] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[4][3])    // -- Transition to Mi
                        begin
                            note_FSM_state  <=  MI;
                        end
                        else if (note_prob_trans_matrix[4][3]< rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[4][4])    // -- Stays on Sol
                        begin
                            note_FSM_state  <=  SOL;
                        end
                        else if (note_prob_trans_matrix[4][4]< rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[4][5])    // -- Transition to La
                        begin
                            note_FSM_state  <=  LA;
                        end
                    end
                end

                LA: begin
                    ticks_target_reg    <=  1136;   // -- La freq: 440 Hz -> 1136 ticks for a 50% Dutty Cycle.
                    // Transition
                    if (duration_done_rise)
                    begin
                        if (rnd[7:0] < note_prob_trans_matrix[5][0])         // -- Transition to mute 
                        begin
                            note_FSM_state  <=  MUTE;
                        end
                        else if (note_prob_trans_matrix[5][0] < rnd[7:0] & rnd[7:0] < note_prob_trans_matrix[5][1])    // -- Transition to Do
                        begin
                            note_FSM_state  <=  DO;
                        end
                        else if (note_prob_trans_matrix[5][1] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[5][2])    // -- transition to Re
                        begin
                            note_FSM_state  <=  RE;
                        end
                        else if (note_prob_trans_matrix[5][2] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[5][3])    // -- Transition to Mi
                        begin
                            note_FSM_state  <=  MI;
                        end
                        else if (note_prob_trans_matrix[5][3] < rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[5][4])    // -- Transition to Sol
                        begin
                            note_FSM_state  <=  SOL;
                        end
                        else if (note_prob_trans_matrix[5][4]< rnd[7:0] && rnd[7:0] < note_prob_trans_matrix[5][5])    // -- Stays on La
                        begin
                            note_FSM_state  <=  LA;
                        end
                    end 
                end
            endcase
        end
    end
endmodule
