# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge

@cocotb.test()
async def test_melody_generator(dut):
    """Prueba del generador de melodías: Reset, configuración y detección de PWM"""
    
    dut._log.info("Iniciando simulación del Generador de Música de Arellano Nordahl")

    # Definimos el reloj a 1 MHz (1000ns de periodo) según tu info.yaml
    clock = Clock(dut.clk, 1, unit="us")
    cocotb.start_soon(clock.start())

    # --- Inicialización y Reset ---
    dut._log.info("Aplicando Reset...")
    dut.ena.value = 1
    dut.rst_n.value = 0
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    
    # Esperamos 10 ciclos de reloj para asegurar un reset limpio
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    dut._log.info("Sistema fuera de reset")

    # --- Configuración de Entradas (ui_in) ---
    # ui_in[3:0] = SEED (Semilla del LFSR, ej: 4'b1010 -> 10)
    # ui_in[4]   = BPM_SEL (0 -> 120 BPM, 1 -> 60 BPM)
    # ui_in[5]   = DUR_MATRIX_SEL (0 o 1)
    semilla = 10
    bpm_sel = 0
    matrix_sel = 0
    
    # Combinamos los bits para formar el byte de entrada ui_in
    val_entrada = (matrix_sel << 5) | (bpm_sel << 4) | semilla
    dut.ui_in.value = val_entrada
    
    dut._log.info(f"Configuración: Seed={semilla}, BPM_SEL={bpm_sel}, Matrix_SEL={matrix_sel}")

    # --- Verificación de Actividad PWM ---
    # Queremos confirmar que el pin uo_out[0] (PWM_SIG) cambia de estado
    actividad_detectada = False
    dut._log.info("Monitoreando uo_out[0] (PWM_SIG) en busca de señal de audio...")
    
    # Revisamos durante 2000 ciclos de reloj
    for _ in range(2000):
        await RisingEdge(dut.clk)
        if dut.uo_out[0].value == 1:
            actividad_detectada = True
            break
            
    # Si después de 2000 ciclos uo_out[0] nunca fue '1', el test falla
    assert actividad_detectada, "ERROR: No se detectó ninguna señal PWM en uo_out[0]. Revisa tu lógica de PWM."
    
    dut._log.info("¡TEST EXITOSO! Se detectó actividad de audio en la salida.")
