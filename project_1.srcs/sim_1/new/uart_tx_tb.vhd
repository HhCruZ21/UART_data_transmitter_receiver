
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2025 12:18:47 PM
-- Design Name: 
-- Module Name: uart_tx_tb - Behavioral
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

entity uart_tx_tb is
--  Port ( );
end uart_tx_tb;

architecture Behavioral of uart_tx_tb is
constant clk_period : time := 20 ns;        -- 50 Mhz
constant baud_period : time := 104.16667 us;   -- 9600 baud

signal clk, reset, tx_start, baud_tick, tx_serial,tx_busy : std_logic;
signal tx_data : std_logic_vector(7 downto 0);

-- expected data tracking
signal expected_data : std_logic_vector (7 downto 0);
signal data_Received : std_logic_vector (7 downto 0);

component uart_tx is
    Port(
            clk : in std_logic;
            reset : in std_logic;
            tx_data : in std_logic_vector(7 downto 0);
            tx_start : in std_logic;
            baud_tick : in std_logic;
            tx_serial : out std_logic;
            tx_busy : out std_logic
    );
end component uart_tx;

begin
uut : uart_tx
Port map(
            clk => clk,
            reset => reset,
            tx_data => tx_data,
            tx_start => tx_start,
            baud_tick => baud_tick,
            tx_serial => tx_serial,
            tx_busy => tx_busy       
);

baud_gen_inst : entity work.baud_generator
        generic map(
            clk_freq  => 50_000_000,
            baud_rate => 9_600
        )
        port map(
            clk       => clk,
            reset     => reset,
            baud_tick => baud_tick
        );

clk_p : process
begin
    clk <= '0';
    wait for clk_period / 2;
    clk <= '1';
    wait for clk_period / 2;
end process clk_p;

serial_monitor : process
variable sampled_byte : std_logic_vector(7 downto 0);
begin
    wait until falling_edge(tx_serial); -- detect start bit
    
    -- wait for 1.5 baud periods with small delta for robustness
    wait for baud_period * 1.5;
    
    -- capture data bits
    for i in 0 to 7 loop
        sampled_byte(i) := tx_serial;
        wait for baud_period;
    end loop;
    
    data_received <= sampled_byte;
    -- verify stop bit
    wait for baud_period /2;
    assert tx_serial = '1'
        report "UART_TX_TB ERROR : Stop bit error - expected '1'"
        severity error;
        
end process serial_monitor;

stim_p : process
    procedure send_byte(data : std_logic_vector(7 downto 0)) is
    begin
        tx_data <= data;
        expected_data <= data;
        tx_start <= '1';
        wait for clk_period;
        tx_start <= '0';
        
        assert tx_busy = '1'
            report "UART_TX_TB ERROR : tx_busy not asserted after tx_start"
            severity error;
            
        wait until tx_busy = '0';
        wait for baud_period * 2;
    end procedure;
begin
    reset <= '1';
    tx_start <= '0';
    tx_data <= (others => '0');
    wait for 100 ns;
    
    reset <= '0';
    wait for clk_period * 10;
    
    -- test case 1 : Simple transmission
    send_byte("01010101");
    
    -- test case 2 : full byte (AAh)
    send_byte("10101010");
    
    -- test case 3 : edge cases
    send_byte("00000000");
    send_byte("11111111");
    send_byte("01011010");  -- alternating pattern
    
    -- test case 4 : back-to-back transmission
    send_byte("00110011");
    send_byte("11001100");
    
    -- test case 5 : Start during busy (violation of normal working)
    tx_data <= "11110000";
    tx_start <= '1';
    wait for clk_period;
    tx_start <= '0';
    wait for clk_period;
    
    tx_data <= "00001111";
    tx_start <= '1';
    wait for clk_period;
    assert tx_busy = '1'
        report "UART_TX_TB : WARNING : tx_tsart accepted while busy"
        severity warning;
    tx_start <= '0';
    
    wait until tx_busy = '0';
    wait for baud_period * 2;
    
    -- Final test
    send_byte("10011001");
    
    -- data verification
    wait for baud_period;
    assert data_received = expected_data
        report "UART_TX_TB : ERROR: Data mismatch : Expected 0x"
                & to_hstring(to_bitvector(expected_data)) 
                & " but received 0x" 
                & to_hstring(to_bitvector(data_received))
        severity error;
        
    report "UART_TX_TB : SUCCESS : Testbench completed successfully";
    wait;
end process stim_p;
end Behavioral;
