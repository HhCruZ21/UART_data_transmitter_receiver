----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/04/2025 06:19:54 PM
-- Design Name: 
-- Module Name: uart_tx_rx_tb - Behavioral
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
library xil_defaultlib;
library work;

entity uart_tx_rx_tb is
--  Port ( );
end uart_tx_rx_tb;

architecture Behavioral of uart_tx_rx_tb is

-- components
component uart_tx is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           tx_data : in STD_LOGIC_VECTOR (7 downto 0);
           tx_start : in STD_LOGIC;
           baud_tick : in STD_LOGIC;
           tx_serial : out STD_LOGIC;
           tx_busy : out STD_LOGIC);
end component uart_tx;

component uart_rx is
    Generic ( clk_freq : INTEGER := 50_000_000;
              baud_rate : INTEGER := 9_600);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           rx_serial : in STD_LOGIC;
           baud_tick : in STD_LOGIC;
           rx_data : out STD_LOGIC_VECTOR (7 downto 0);
           rx_valid : out STD_LOGIC;
           rx_error : out STD_LOGIC);
end component uart_rx;

component baud_generator is
    Generic(
        clk_freq : integer := 50_000_000;   -- System clock frequency in Hz
        baud_rate : integer := 9_600        -- Desired baud rate
    );
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           baud_tick : out STD_LOGIC
           );
end component baud_generator;

constant clk_period : time := 20 ns;            -- 50 MHz clock
constant baud_period : time := 104.16667 us;    --9600 baud rate

signal clk : std_logic := '0';
signal reset : std_logic := '1';

-- tx signals
signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
signal tx_start : std_logic := '0';
signal tx_serial : std_logic;
signal tx_busy : std_logic;

-- rx signals
signal rx_Serial : std_logic;
signal rx_data : std_logic_vector(7 downto 0);
signal rx_valid : std_logic;
signal rx_error : std_logic;

-- shared baud tick
signal baud_tick : std_logic;

-- expected and received data tracking
signal expected_data : std_logic_vector(7 downto 0);
signal test_done : std_logic := '0';

begin

-- DUT instances
tx_inst : uart_tx
    port map (
        clk => clk,
        reset => reset,
        tx_data => tx_data,
        tx_start => tx_start,
        baud_tick => baud_tick,
        tx_serial => tx_serial,
        tx_busy => tx_busy
    );
    
rx_inst : uart_rx
    generic map(
        clk_freq => 50_000_000,
        baud_rate => 9_600
        )
    port map(
        clk => clk,
        reset => reset,
        rx_Serial => rx_serial,
        baud_tick => baud_tick,
        rx_data => rx_Data,
        rx_valid => rx_valid,
        rx_error => rx_error
        );
        
baud_gen_inst : baud_generator
    generic map(
        clk_freq => 50_000_000,
        baud_rate => 9_600
        )
    port map(
        clk => clk,
        reset => reset,
        baud_tick => baud_tick
        );
        
-- Tx -> Rx connection
rx_serial <= tx_serial;

--clock generation
clk_p : process
begin
    while test_done = '0' loop
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end loop;
    wait;
end process clk_p;

stim_p : process
procedure send_and_check(data : std_logic_vector(7 downto 0)) is
begin
    tx_data <= data;
    expected_data <= data;
    tx_start <= '1';
    wait for clk_period;
    tx_start <= '0';
    
    wait until tx_busy = '0';
    wait until rx_valid = '1' for baud_period * 20;
    
    assert rx_error = '0'
        report "UART_TX_RX_TB ERROR : Rx framing error"
        severity error;
        
    assert rx_data = expected_data
        report "UART_TX_RX ERROR : Rx data mismatch. Expected: 0x" &
                to_hstring(to_bitvector(expected_data)) &
                ", Got: 0x" & to_hstring(to_bitvector(rx_data))
        severity error;
end procedure;
begin
    wait for 100 ns;
    reset <= '0';
    wait for clk_period * 10;
    
    -- Test various patterns
    send_and_check("01010101"); --0x55
    send_and_check("10101010"); --0xAA  
    send_and_check("11111111"); --0xFF
    send_and_check("00000000"); --0x00
    send_and_check("11001100"); --0xCC
    send_and_check("00110011"); --0x33
    
    report "UART_TX_RX_TB SUCCESS : All test cases passed";
    test_done <= '1';
    wait;
end process stim_p;
end Behavioral;
