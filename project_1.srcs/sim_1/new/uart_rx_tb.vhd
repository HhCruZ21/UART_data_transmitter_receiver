----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/29/2025 08:37:41 AM
-- Design Name: 
-- Module Name: uart_rx_tb - Behavioral
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
library xil_defaultlib;
library work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx_tb is
--  Port ( );
end uart_rx_tb;

architecture Behavioral of uart_rx_tb is
component uart_rx is
    Generic(
           clk_freq : integer := 50_000_000;
           baud_rate : integer := 9600);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           rx_serial : in STD_LOGIC;
           baud_tick : in STD_LOGIC;
           rx_data : out STD_LOGIC_VECTOR (7 downto 0);
           rx_valid : out STD_LOGIC;
           rx_error : out STD_LOGIC);
end component uart_rx;

--component baud_generator is
--    Generic(
--        clk_freq : integer := 50_000_000;   -- System clock frequency in Hz
--        baud_rate : integer := 9_600        -- Desired baud rate
--    );
--    Port ( clk : in STD_LOGIC;
--           reset : in STD_LOGIC;
--           baud_tick : out STD_LOGIC
--           );
--end component baud_generator;

constant clk_period : time := 20 ns;
constant baud_period : time := 104.16667 us;
constant reset_time : time := 100 ns;

signal clk : std_logic := '0';
signal reset : std_logic := '1';
signal rx_serial : std_logic := '1';
signal rx_data : std_logic_vector(7 downto 0);
signal rx_valid : std_logic;
signal rx_error : std_logic;

signal baud_tick : std_logic;
signal test_data : std_logic_vector(7 downto 0) := "01010101";

begin
uut : uart_rx
    Generic map(
            clk_freq => 50_000_000,
            baud_rate => 9_600
            )
    Port map(
            clk => clk,
            reset => reset,
            rx_serial => rx_serial,
            baud_tick => baud_tick,
            rx_data => rx_data,
            rx_valid => rx_valid,
            rx_error => rx_error
            );
            
baud_gen_inst : entity work.baud_generator
    Generic map(
            clk_freq => 50_000_000,
            baud_rate => 9_600
            )
    Port map(
            clk => clk,
            reset => reset,
            baud_tick => baud_tick
            );
            
clk_p : process
begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
end process clk_p;

stim_p : process
procedure send_byte(
        constant data : in std_logic_vector(7 downto 0))
        is
        begin
            rx_serial <= '0';
            wait for baud_period;
            
            for i in 0 to 7 loop
                rx_serial <= data(i);
                wait for baud_period;
            end loop;
            
            rx_serial <= '1';
            wait for baud_period;
            
            wait for baud_period;
            end procedure;
begin
reset <= '1';
wait for reset_time;
reset <= '0';
wait for clk_period * 10;

-- Test case 1 : Normal transmission
report "Starting test case 1 : Normal transmission (0x55)";
test_data <= "01010101";    -- 0x55
send_byte(test_data);
wait until rx_valid = '1' for baud_period * 20;
assert rx_data = test_data
    report "RX data mismatch in test case 1" severity error;
assert rx_error = '0'
    report "Unexpected error in test case 1" severity error;

-- Test case 2 : Complementary pattern
report "Starting test case 2 : Complementary pattern (0xAA)";
test_data <= "10101010";    -- 0xAA
send_byte(test_data);
wait until rx_valid = '1' for baud_period * 20;
assert rx_data = test_data
    report "RX data mismatch in test case 2" severity error;
    
-- Test case 3 : Framing error test
report "Starting test case 3 : Framing error test";
test_data <= "00001111";    -- 0x0F
rx_serial <= '0';   -- Start bit
wait for baud_period;
for i in 0 to 6 loop
    rx_serial <= test_data(i);
    wait for baud_period;
end loop;           

rx_serial <= '0';
wait for baud_period;
wait for baud_period;
assert rx_error = '1'
    report "Framing error not detected in test case 3" severity error;

-- Test case 4 : Continous transmission
report "Starting test case 4 : Coninous transmission";
for i in 0 to 15 loop
    test_data <= std_logic_vector(to_unsigned(i,8));
    send_byte(test_data);
    wait until rx_valid = '1' for baud_period * 20;
    assert rx_data = test_data
        report "RX data mismatch in test case 4, byte " & integer'image(i)
        severity error;
end loop;

report "All test case completed successfully";
wait;
end process stim_p;

baud_monitor : process
variable last_tick : time := 0 ns;
variable period : time;
begin
    wait until rising_edge(baud_tick);
    period := now - last_tick;
    last_tick := now;
    
    assert abs(period - baud_period) < clk_period
        report "Baud period deviation detected: " & time'image(period)
        severity warning;
end process baud_monitor;
end Behavioral;
