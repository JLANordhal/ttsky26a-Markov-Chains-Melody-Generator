# Makefile para Cocotb - Tiny Tapeout
SIM ?= icarus
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src

# Lista de todos tus archivos fuente .v en la carpeta /src
PROJECT_SOURCES = tt_um_Melody_Generator_JLANordhal.v lfsr.v markov_chain_fsm.v pwm_generator.v

ifneq ($(GATES),yes)

# Simulación RTL (Lógica)
SIM_BUILD = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Simulación Gate Level (Post-GDS)
SIM_BUILD = sim_build/gl
COMPILE_ARGS += -DGL_TEST
COMPILE_ARGS += -DFUNCTIONAL
COMPILE_ARGS += -DUSE_POWER_PINS
COMPILE_ARGS += -DSIM
COMPILE_ARGS += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# Este archivo se genera automáticamente durante el proceso de GDS
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Configuración del entorno de simulación
COMPILE_ARGS += -I$(SRC_DIR)
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# Definir el módulo de prueba de Python (test.py)
COCOTB_TEST_MODULES = test

include $(shell cocotb-config --makefiles)/Makefile.sim
