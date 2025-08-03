
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2025 10:01:30 AM
-- Design Name: 
-- Module Name: baud_generator - Behavioral
-- Project Name: UART-Transmitter-Receiver
-- Target Devices: Zynq-7000
-- Tool Versions: 
-- Description: Generates a clock pulse baud_tick at the specified baud_rate
--              The pulse is one clock cycle wide and occurs every (clk_freq/baud_rate) cycles
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity baud_generator is
    Generic(
        clk_freq : integer := 50_000_000;   -- System clock frequency in Hz
        baud_rate : integer := 9_600        -- Desired baud rate
    );
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           baud_tick : out STD_LOGIC
           );
end baud_generator;

architecture Behavioral of baud_generator is

constant baud_div : integer := INTEGER(clk_freq/baud_rate);
signal baud_counter : integer range 0 to baud_div - 1 := 0;

begin
assert(clk_freq > 0 and baud_rate > 0)
    report "Clock frequency and baud rate must be positive"
    severity failure;
    
assert(clk_freq mod baud_rate = 0)
    report "Clock frequency must be evenly divisible by baud rate"
    severity warning;

baud_gen_p : process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            baud_counter <= 0;
            baud_tick <= '0';
        elsif baud_counter = baud_div - 1 then
            baud_counter <= 0;
            baud_tick <= '1';
        else
            baud_counter <= baud_counter + 1;
            baud_tick <= '0';
        end if; 
    end if;
end process baud_gen_p;

end Behavioral;
