import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

@cocotb.test()
async def test_melody_generator(dut):
    """Prueba funcional del generador de melodías estocásticas"""
    
    dut._log.info("Iniciando simulación: Generador de Música (Arellano Nordahl)")

    # 1. Configuración del Reloj (1 MHz = 1us de periodo)
    # Esto genera la señal que entra al pin 'clk' definido en el Canvas
    clock = Clock(dut.clk, 1, unit="us")
    cocotb.start_soon(clock.start())

    # 2. Inicialización de señales y Reset
    dut._log.info("Aplicando Reset al sistema...")
    dut.ena.value = 1       # Activamos el diseño (Enable)
    dut.ui_in.value = 0     # Entradas a cero
    dut.uio_in.value = 0    # Bidireccionales a cero
    dut.rst_n.value = 0     # Reset activo (bajo)
    
    # Esperamos 10 ciclos para que el reset se propague
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1     # Liberamos el reset
    dut._log.info("Sistema fuera de reset y operando")

    # 3. Configuración de parámetros de usuario (ui_in)
    # Basado en tu info.yaml:
    # ui_in[3:0] -> Seed (Semilla)
    # ui_in[4]   -> BPM_SEL (0: 120, 1: 60)
    # ui_in[5]   -> DUR_MATRIX_SEL
    seed = 0xA          # Ejemplo: semilla 1010
    bpm = 0             # 120 BPM
    matrix = 0          # Matriz A
    
    input_val = (matrix << 5) | (bpm << 4) | (seed & 0xF)
    dut.ui_in.value = input_val
    dut._log.info(f"Configuración aplicada: Seed={seed}, BPM={bpm}, Matrix={matrix}")

    # 4. Monitoreo de la salida PWM (uo_out[0])
    # Como el diseño es aleatorio, verificamos que 'haya vida' (actividad en el pin)
    actividad_detectada = False
    dut._log.info("Buscando pulsos PWM en uo_out[0]...")
    
    # Revisamos los próximos 5000 ciclos de reloj
    for _ in range(5000):
        await RisingEdge(dut.clk)
        
        # Leemos el bus uo_out completo y extraemos el bit 0 (PWM_SIG)
        # Esto evita el error de 'Packed objects cannot be indexed'
        bus_salida = int(dut.uo_out.value)
        pwm_sig = bus_salida & 0x01
        
        if pwm_sig == 1:
            actividad_detectada = True
            break
            
    # Si después de 5000 ciclos no hubo ni un solo '1', algo va mal
    assert actividad_detectada, "ERROR: No se detectó señal PWM en uo_out[0]. Revisa la lógica del PWM o del FSM."
    
    dut._log.info("¡Prueba superada! Se detectó actividad de audio en la salida.")
