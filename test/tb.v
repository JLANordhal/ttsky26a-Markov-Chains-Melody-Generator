`default_nettype none
`timescale 1ns / 1ps

/* Este es el "cascarón" (Harness) del test. 
   Su única función es conectar tu módulo con el simulador.
*/
module tb ();

  // Configuración para grabar las señales y verlas en GTKWave
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Definición de las señales (cables)
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

`ifdef GL_TEST
  // Pines de alimentación necesarios para el test del GDS final
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // --- CONEXIÓN DE TU PROYECTO ---
  tt_um_Melody_Generator_JLANordhal user_project (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),    // Entradas: Semilla, BPM, Matriz
      .uo_out (uo_out),   // Salidas: PWM Audio
      .uio_in (uio_in),   // Bidireccionales (no usados)
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),      // Activación del chip
      .clk    (clk),      // Reloj de 1MHz
      .rst_n  (rst_n)     // Reset (activo en bajo)
  );

endmodule
