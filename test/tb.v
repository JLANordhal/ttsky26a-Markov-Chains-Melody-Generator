`default_nettype none
`timescale 1ns / 1ps

/* Este testbench instancia el módulo principal y crea los cables 
   que cocotb controlará desde el archivo test.py.
*/
module tb ();

  // Generación de archivo de ondas para GTKWave
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

  // Señales para conectar con el módulo
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

`ifdef GL_TEST
  // Señales de alimentación para pruebas de nivel de compuertas (Gate Level)
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // --- Instancia del DUT (Tu Proyecto) ---
  tt_um_Melody_Generator_JLANordhal user_project (
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif
      .ui_in  (ui_in),    // Entradas dedicadas
      .uo_out (uo_out),   // Salidas dedicadas
      .uio_in (uio_in),   // IOs bidireccionales: Entrada
      .uio_out(uio_out),  // IOs bidireccionales: Salida
      .uio_oe (uio_oe),   // IOs bidireccionales: Habilitación
      .ena    (ena),      // Habilitado por el sistema
      .clk    (clk),      // Reloj principal
      .rst_n  (rst_n)     // Reset (activo bajo)
  );

endmodule
