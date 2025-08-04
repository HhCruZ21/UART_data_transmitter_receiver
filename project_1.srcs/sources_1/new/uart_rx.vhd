----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07/29/2025 07:59:37 AM
-- Design Name: 
-- Module Name: uart_rx - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    Generic ( clk_freq : INTEGER := 50_000_000;
              baud_rate : INTEGER := 9_600);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           rx_serial : in STD_LOGIC;
           baud_tick : in STD_LOGIC;
           rx_data : out STD_LOGIC_VECTOR (7 downto 0);
           rx_valid : out STD_LOGIC;
           rx_error : out STD_LOGIC);
end uart_rx;

architecture Behavioral of uart_rx is

type rx_states is (IDLE, START, DATA, STOP);
signal current_state : rx_states := IDLE;
signal bit_count : integer range 0 to 7 := 0;
signal data_reg : std_logic_vector(7 downto 0) := (others => '0');

begin  
uart_rx_fsm : process(clk)
begin
    if rising_edge(clk) then
        if reset = '1' then
            current_state <= IDLE;
            data_reg <= (others => '0');
            bit_count <= 0;
            rx_valid <= '0';
            rx_error <= '0';
        else
            rx_valid <= '0';
            rx_error <= '0';
            
            case current_state is
                when IDLE =>
                    if rx_serial = '0' then
                        current_state <= START;
                        bit_count <= 0;
                    end if;
                when START =>
                    if baud_tick = '1' then
                        if rx_serial = '0' then
                            current_state <= DATA;
                        else
                            current_state <= IDLE;
                        end if;
                    end if;
                when DATA =>
                    if baud_tick = '1' then
                        data_reg(bit_count) <= rx_serial;
                        if bit_count = 7 then
                            current_state <= STOP;
                        else
                            bit_count <= bit_count + 1;
                        end if;
                    end if;
                when STOP =>
                    if baud_tick = '1' then
                        if rx_serial = '1' then
                            rx_valid <= '1';
                        else
                            rx_error <= '1';
                        end if;
                        data_reg <= (others => '0');
                        current_state <= IDLE;
                    end if;
            end case;
        end if;
    end if;
end process uart_rx_fsm;

rx_data <= data_reg;
end Behavioral;
