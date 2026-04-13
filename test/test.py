import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_melody_generator(dut):
    """
    Testbench para el Generador de Melodías Estocásticas.
    Configurado para una simulación de larga duración (10 segundos).
    """
    
    dut._log.info("Iniciando simulación: Generador de Música (Arellano Nordahl)")

    # 1. Configuración del Reloj
    # 1 MHz = 1 microsegundo por ciclo.
    clock = Clock(dut.clk, 1, unit="us")
    cocotb.start_soon(clock.start())

    # 2. Inicialización y Reset
    dut._log.info("Aplicando Reset...")
    dut.ena.value = 1       # Activar el diseño
    dut.ui_in.value = 0     # Entradas iniciales
    dut.uio_in.value = 0    # Entradas bidireccionales
    dut.rst_n.value = 0     # Reset activo (bajo)
    
    # Esperamos 10 ciclos para estabilizar
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1     # Liberar el sistema
    dut._log.info("Sistema operando. Iniciando grabación de 10 segundos...")

    # 3. Configuración de parámetros mediante ui_in
    # ui_in[3:0] -> Semilla (Seed)
    # ui_in[4]   -> BPM_SEL (0: 120, 1: 60)
    # ui_in[5]   -> DUR_MATRIX_SEL (Cambio de estilo rítmico)
    seed = 0x7          # Semilla de ejemplo
    bpm = 1             # Selección de velocidad
    matrix = 0          # Matriz de probabilidad A
    
    input_val = (matrix << 5) | (bpm << 4) | (seed & 0xF)
    dut.ui_in.value = input_val

    # 4. DURACIÓN DE LA SIMULACIÓN
    # 10,000,000 ciclos / 1,000,000 Hz = 10 segundos.
    # NOTA: El archivo 'tb.fst' resultante será pesado (varios MB).
    # Asegúrate de tener espacio en disco en tu sistema Arch.
    await ClockCycles(dut.clk, 10000000)
    
    dut._log.info("Simulación terminada con éxito tras 10 segundos de audio simulado.")
