----------------------------------------------------------------------------------
-- Engineer: Joseph Kroeker
-- 
-- Create Date: 01/04/2021 06:44:49 PM
-- Module Name: UART_RX 
-- Description: UART Recieving Module based on Nandlands tutorial and code
-- 
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity UART_RX is
    generic (
        g_BAUD_RATE : INTEGER := 9600;      -- Bits per second (default to 9600 Baud)
        g_PARITY    : STD_LOGIC_VECTOR(1 downto 0) := "00"; -- Parity of the message being received. ("00" for none (Default), "01" for odd, "10" for even)
        g_DATA_BITS : INTEGER := 8;     -- Number of bits per message
        g_CLK_FREQ  : INTEGER := 100000000  -- Clock frequency (default to 100 MHz)
    );
    port ( 
    i_Clk       : in STD_LOGIC;     -- Input clock signal
    i_RX_Serial : in STD_LOGIC;     -- Input data from pin
    o_RX_DV     : out STD_LOGIC;    -- Output high if done receiving                 
    o_RX_Byte   : out STD_LOGIC_VECTOR(g_DATA_BITS-1 downto 0) -- The byte of data that was received
    );
end UART_RX;

architecture Behavioral of UART_RX is
    
    -- TODO Verify that this value is an acceptable value (At least ~16)
    constant r_Clks_Per_Bit : integer := g_CLK_FREQ/g_BAUD_RATE;    -- Clock cycles per bit (Oversampling frequency) 
    
    type t_SM_Main is (s_Idle, s_RX_Start_Bit, s_RX_Data_Bits,
                       s_RX_Stop_Bit, s_Cleanup); -- State machine for UART
    signal r_SM_Main : t_SM_Main := s_Idle; -- Initialize state machine to idle
    
    signal r_RX_Data_R  : STD_LOGIC := '0';  -- Raw receive data
    signal r_RX_Data    : STD_LOGIC := '0';  -- Receive data after debouncing through ff
    
    signal r_Clk_Count  : INTEGER range 0 to r_Clks_Per_Bit-1 := 0; -- Sample take in current bit
    signal r_Bit_Index  : INTEGER range 0 to g_DATA_BITS-1 := 0;    -- Index of current bit in message
    signal r_RX_Byte    : STD_LOGIC_VECTOR(g_DATA_BITS-1 downto 0) := (others => '0'); -- Overall current message
    signal r_RX_DV      : STD_LOGIC := '0';    -- Current status of message (high if done receiving)
    
begin
    
    -- Purpose: Double ff the incoming data bit. (Sample every clock cycle and does not move to output data)
    p_SAMPLE : process (i_Clk)
    begin
        if rising_edge(i_Clk) then
            r_RX_Data_R <= i_RX_Serial;
            r_RX_Data <= r_RX_Data_R;
        end if ;
    end process p_SAMPLE;

    p_UART_RX : process (i_Clk)
    begin
        if rising_edge(i_Clk) then
            case r_SM_Main is -- Check current state of SM
            
                -- Not currently receiving data
                when s_Idle =>
                    r_RX_DV <= '0';
                    r_Clk_Count <= 0;
                    r_Bit_Index <= 0;
                    if r_RX_Data = '0' then  -- Start bit detected, next state
                        r_SM_Main <= s_RX_Start_Bit;
                    else -- No start bit, stay here
                        r_SM_Main <= s_Idle;
                    end if;
                    
                -- Received start bit    
                when s_RX_Start_Bit =>
                    r_RX_DV <= '1';
                    if r_Clk_Count = (r_Clks_Per_Bit-1)/2 then -- In middle, continue to next state
                        if r_RX_Data = '0' then
                            r_Clk_Count <= 0;
                            r_SM_Main <= s_RX_Data_Bits;
                        else
                            r_SM_Main <= s_Idle;
                        end if;
                    else -- Not in middle yet, keep iterating and stay here
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_RX_Start_Bit;
                    end if;
                    
                when s_RX_Data_Bits => 
                    if r_Clk_Count < r_Clks_Per_Bit-1 then -- Not in middle yet, iterate and stay here
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_RX_Data_Bits;
                    else -- In middle of bit, sample
                        r_RX_Byte(r_Bit_Index) <= r_RX_Data;
                        r_Clk_Count <= 0;
                        
                        if r_Bit_Index = g_DATA_BITS-1 then -- All bits accounted for
                            r_Bit_Index <= 0;
                            r_SM_Main <= s_RX_Stop_Bit;

                        else
                            r_Bit_Index <= r_Bit_Index + 1;
                            r_SM_Main <= s_RX_Data_Bits;
                        end if;
                    end if;
                    
                -- Receive stop bit
                when s_RX_Stop_Bit =>
                    if r_Clk_Count < r_Clks_Per_Bit-1 then -- Not in middle yet
                        r_Clk_Count <= r_Clk_Count + 1;
                        r_SM_Main <= s_RX_Stop_Bit;
                    else -- At end of message, flash high value
                        r_RX_DV <= '1';
                        r_Clk_Count <= 0;
                        r_SM_Main <= s_Cleanup;
                    end if;
                    
                -- Wait one clock cycle
                when s_Cleanup =>
                    r_SM_Main <= s_Idle;
                    r_RX_DV <= '0';
                    
                when others =>
                    r_SM_Main <= s_Idle;
                    r_RX_DV <= '0';
            end case;
        end if;
    end process p_UART_RX;
    
  o_RX_DV   <= r_RX_DV;
  o_RX_Byte <= r_RX_Byte;
end Behavioral;
