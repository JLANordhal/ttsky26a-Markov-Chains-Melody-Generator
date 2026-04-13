----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.04.2026 11:27:44
-- Design Name: 
-- Module Name: tt_um_Melody_Generator_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tt_um_Melody_Generator_tb is
--  Port ( );
end tt_um_Melody_Generator_tb;

architecture Behavioral of tt_um_Melody_Generator_tb is
    -- Signals
    signal ui_in:   std_logic_vector(7 downto 0) := (others => '0');
    signal uio_in:  std_logic_vector(7 downto 0) := (others => '0');
    signal ena:     std_logic   :=  '1';
    signal clk:     std_logic   :=  '0';
    signal rst_n:   std_logic   :=  '1';
    
    signal uo_out:  std_logic_vector(7 downto 0);
    signal uio_out: std_logic_vector(7 downto 0);
    signal uio_oe:  std_logic_vector(7 downto 0);
begin

    -- Unit Under Test
    UUT: entity work.tt_um_Melody_Generator_JLANordhal
    port map
    (
        ui_in   =>  ui_in,
        uo_out  =>  uo_out, 
        uio_in  =>  uio_in,
        uio_out =>  uio_out,
        uio_oe  =>  uio_oe,
        ena     =>  ena,
        clk     =>  clk,
        rst_n   =>  rst_n
    );

    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for 0.5us;
        clk <= '1';
        wait for 0.5us;
    end process;
    
    -- Stimulus process
    stim_proces: process
    begin
        -- Initial reset
        rst_n <= '0';
        wait for 1 ms;
        rst_n <= '1';
        
        -- SEED: hA, BPM: 120, Matrix: A1
        ui_in(0) <=  '0'; 
        ui_in(1) <=  '1';
        ui_in(2) <=  '0';
        ui_in(3) <=  '1';
        
        ui_in(4) <=  '0';
        
        ui_in(5) <=  '0';
        wait for 100 sec;
        
        ui_in(0) <=  '1'; 
        ui_in(1) <=  '1';
        ui_in(2) <=  '1';
        ui_in(3) <=  '1';
        ui_in(4) <=  '1';
        ui_in(5) <=  '1';
        wait for 30 sec;
        wait;
    end process;
end Behavioral;
