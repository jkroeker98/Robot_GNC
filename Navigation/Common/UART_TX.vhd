----------------------------------------------------------------------------------
-- Engineer: Joseph Kroeker
-- 
-- Create Date: 01/04/2021 06:44:49 PM
-- Module Name: UART_TX 
-- Description: UART Transmitting Module based on Nandlands tutorial and code
-- 
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity UART_TX is
    generic (
        g_BAUD_RATE : INTEGER := 9600;      -- Bits per second (default to 9600 Baud)
        g_PARITY    : STD_LOGIC_VECTOR(1 downto 0) := "00"; -- Parity of the message being received. ("00" for none (Default), "01" for odd, "10" for even)
        g_DATA_BITS : INTEGER := 8;     -- Number of bits per message
        g_CLK_FREQ  : INTEGER := 100000000  -- Clock frequency (default to 100 MHz)
    );
    port ( 
    i_Clk       : in STD_LOGIC;     -- Input clock signal
    i_TX_DV     : in STD_LOGIC;     -- Input flag, high if data is available to be trasmitted
    i_TX_Byte   : in STD_LOGIC_VECTOR(7 downto 0);     -- Input data to be transmitted
    o_TX_Active : out STD_LOGIC;    -- Output high if trasmitting           
    o_TX_Serial : out STD_LOGIC;    -- Output data being trasmitted by bit, default high
    o_TX_Done   : out STD_LOGIC     -- Output high when done trasnmitting
    );
end UART_TX;

architecture Behavioral of UART_TX is
    
    -- TODO Verify that this value is an acceptable value (At least ~16)
    constant r_Clks_Per_Bit : integer := g_CLK_FREQ/g_BAUD_RATE;    -- Clock cycles per bit (Oversampling frequency) 
    
    type t_SM_Main is (s_Idle, s_TX_Start_Bit, s_TX_Data_Bits,
                       s_TX_Stop_Bit, s_Cleanup); -- State machine for UART
    signal r_SM_Main : t_SM_Main := s_Idle; -- Initialize state machine to idle
    
    --signal r_TX_Data_R  : STD_LOGIC := '0';  -- Raw receive data
    signal r_TX_Data    : STD_LOGIC_VECTOR(7 downto 0);     -- Receive data after debouncing through ff
    
    signal r_Clk_Count  : INTEGER range 0 to r_Clks_Per_Bit-1 := 0; -- Sample take in current bit
    signal r_Bit_Index  : INTEGER range 0 to g_DATA_BITS-1 := 0;    -- Index of current bit in message
    signal r_TX_Done      : STD_LOGIC := '0';    -- High if done sending signal
    
begin
    
    -- Purpose: Double ff the incoming data bit. (Sample every clock cycle and does not move to output data)
    --p_SAMPLE : process (i_Clk)
    --begin
    --    if rising_edge(i_Clk) then
    --        r_RX_Data_R <= i_RX_Serial;
    --        r_RX_Data <= r_RX_Data_R;
    --    end if ;
    --end process p_SAMPLE;

    p_UART_TX : process (i_Clk)
    begin
        if rising_edge(i_Clk) then
            case r_SM_Main is -- Check current state of SM
            
                -- Not currently receiving data
                when s_Idle =>
                    o_TX_Active <= '0';
                    o_TX_Serial <= '1';
                    r_TX_Done   <= '0';
                    r_Clk_Count <= 0;
                    r_Bit_Index <= 0;
                    
                    if i_TX_DV = '1' then 
                        r_TX_Data <= i_TX_Byte;
                        r_SM_Main <= s_TX_Start_Bit;
                    else 
                        r_SM_Main <= s_Idle;
                    end if;                  
                -- Trasmit start bit (0)
                when s_TX_Start_Bit =>
                    o_TX_Active <= '1';
                    o_TX_Serial <= '0';
                    
                    if r_Clk_Count = r_Clks_Per_Bit -1 then -- Trasmitted for full cycle
                        r_Clk_Count <= 0;
                        r_SM_Main <= s_TX_Data_Bits;
                    else -- Keep trasnmitting
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_TX_Start_Bit;
                    end if;
                    
                when s_TX_Data_Bits => 
                    o_TX_Serial <= r_TX_Data(r_Bit_Index);
                    if r_Clk_Count = r_Clks_Per_Bit-1 then -- Trasmitted for expected duration
                        r_Clk_Count <= 0;
                        r_Bit_Index <= r_Bit_Index + 1;
                        if r_Bit_Index < g_DATA_BITS-1 then
                            r_SM_Main <= s_TX_Data_Bits;
                        else
                            r_SM_Main <= s_TX_Stop_Bit;
                            r_Bit_Index <= 0;
                        end if;
                    else
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_TX_Data_Bits; 
                    end if;
                   
                -- Trasnmit the stop bit (1)
                when s_TX_Stop_Bit =>
                    o_TX_Serial <= '1';
                    if r_Clk_Count = r_Clks_Per_Bit-1 then -- Trasmitted for expected duration
                        r_TX_Done <= '1';
                        r_Clk_Count <= 0;
                        r_SM_Main <= s_Cleanup;
                    else
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_TX_Stop_Bit;
                    end if;
                    
                -- Wait one clock cycle
                when s_Cleanup =>
                    r_SM_Main <= s_Idle;
                    o_TX_Active <= '0';
                    r_TX_Done <= '1';
                    
                when others =>
                    r_SM_Main <= s_Idle;
            end case;
        end if;
    end process p_UART_TX;
  o_TX_Done <= r_TX_Done;
end Behavioral;
