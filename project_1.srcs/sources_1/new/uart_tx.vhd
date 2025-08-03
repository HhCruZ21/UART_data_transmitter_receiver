
----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/28/2025 10:43:42 AM
-- Design Name: 
-- Module Name: uart_tx - Behavioral
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

entity uart_tx is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           tx_data : in STD_LOGIC_VECTOR (7 downto 0);
           tx_start : in STD_LOGIC;
           baud_tick : in STD_LOGIC;
           tx_serial : out STD_LOGIC;
           tx_busy : out STD_LOGIC);
end uart_tx;

architecture Behavioral of uart_tx is

type tx_states is (IDLE, START, DATA, STOP);
signal current_state : tx_states := IDLE;
signal tx_data_in : std_logic_vector(7 downto 0);
signal bit_counter : integer range 0 to 7 := 0;
signal tx_start_flag : std_logic := '0';
signal busy_flag : std_logic := '0';

-- FSM encoding attribute for reliable synthesis
    --attribute fsm_encoding : string;
    --attribute fsm_encoding of current_state : signal is "sequential";

begin

-- Check if new transmission is attempted while busy
assert not (rising_edge(clk) and tx_start = '1' and busy_flag = '1')
    report "UART_TX ERROR : tx_start asserted while transmitter is busy"
    severity warning;
    
-- Check if baud_tick is glitching
assert not (baud_tick'event and baud_tick = '1' and current_state /= IDLE and baud_tick'last_active > 1 ns)
    report "UART_TX WARNING : baud_tick glitch detected uding transmission"
    severity warning;
    
uart_tx_fsm : process(clk, reset)
begin 
    if rising_edge(clk) then
        if reset = '1' then
            current_state <= IDLE;
            tx_serial <= '1';
            tx_data_in <= (others => '0');
            bit_counter <= 0;
            busy_flag <= '0';
         else  
            if tx_start = '1' then
                tx_start_flag <= '1';
            end if;
            if baud_tick = '1' then
                case current_state is
                when IDLE =>  
                    tx_serial <= '1';
                    busy_flag <= '0';
                    if tx_start_flag = '1' then
                        tx_data_in <= tx_data;
                        bit_counter <= 0;
                        current_state <= START;
                    end if;
                when START =>
                    if baud_tick = '1' then
                        tx_serial <= '0';
                        busy_flag <= '1';
                        current_state <= DATA;
                    end if;
                when DATA => 
                    if baud_tick = '1' then
                        tx_serial <= tx_data_in(0);
                        tx_data_in <= '0' & tx_data_in(7 downto 1);
                        if bit_counter = 7 then  
                            current_state <= STOP;
                            bit_counter <= 0;
                        else
                            bit_counter <= bit_counter + 1;
                        end if;
                    end if;
                when STOP =>
                    if baud_tick = '1' then
                        tx_serial <= '1';
                        tx_start_flag <= '0';
                        current_state <= IDLE;
                    end if;
                end case;
            end if;
        end if;   
    end if;
end process uart_tx_fsm;

tx_busy <= busy_flag;
end Behavioral;
