----------------------------------------------------------------------------------
-- Company:  Home
-- Engineer: Joseph Kroeker
-- 
-- Create Date: 10/16/2020 10:29:50 AM
-- Design Name: UART 
-- Target Devices: Arty S7-50
-- Tool Versions: 
-- Description: Create UART controller between computer and 
--  
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART is
    --Generic( 
    --    ClkFreq    : UNSIGNED(27 downto 0) := to_unsigned(100_000_000, 28); -- Clk freq default to 100 MHz
    --    BaudRate   : UNSIGNED(18 downto 0) := to_unsigned(9_600, 19);       -- Baud Rate (bits/sec) Default to 9600;
    --   OSRate     : UNSIGNED(4 downto 0)  := to_unsigned(16, 5);           -- Oversampling rate (samples/baud) Default to 16
    --    Width      : UNSIGNED(3 downto 0)  := to_unsigned(8, 4);            -- Data transmission width
    --    Parity     : STD_LOGIC := '0';  -- Parity {0 = none | 1 = parity}
    --    ParType    : STD_LOGIC := '0'); -- Parity type {0 = even | 1 = odd}
    Port (   
        uart_rxd_in  : in STD_LOGIC;     -- Received data from UART
        CLK100MHZ    : in STD_LOGIC;     -- 100 MHz Clock signal
        led          : out STD_LOGIC_VECTOR(3 downto 0); -- LED Outputs
        --rst        : in STD_LOGIC;      -- Master reset
        --data       : inout STD_LOGIC_VECTOR(7 downto 0);                    -- Data Queue
        --rx_rdy     : out STD_LOGIC;     -- New data has been received and is ready to read 
        --tx_rdy     : out STD_LOGIC;     -- New data has is being transmitted
        uart_txd_out : out STD_LOGIC    -- Transmit data pin
        );
end UART;

architecture Behavioral of UART is

    component UART_RX_NandLand
        generic (
            g_CLKS_PER_BIT : integer := 10417     -- Needs to be set correctly
        );
        port (
            i_Clk       : in  std_logic;
            i_RX_Serial : in  std_logic;
            o_RX_DV     : out std_logic;
            o_RX_Byte   : out std_logic_vector(7 downto 0)
        );
     end component UART_RX_NandLand;
    
    component UART_RX is
        generic (
            g_BAUD_RATE : INTEGER := 9600;      -- Bits per second (default to 9600 Baud)
            g_PARITY    : STD_LOGIC_VECTOR(1 downto 0) := "00"; -- Parity of the message being received. ("00" for none (Default), "01" for odd, "10" for even)
            g_DATA_BITS : INTEGER := 8;     -- Number of bits per message
            g_CLK_FREQ  : INTEGER := 100000000 -- Clock frequency (default to 100 MHz)
        );
        port ( 
            i_Clk       : in STD_LOGIC;     -- Input clock signal
            i_RX_Serial : in STD_LOGIC;     -- Input data from pin
            o_RX_DV     : out STD_LOGIC;    -- Output high if done receiving                 
            o_RX_Byte   : out STD_LOGIC_VECTOR(g_DATA_BITS-1 downto 0) -- The byte of data that was received
        );
    end component UART_RX;
    
    component UART_TX is
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
    end component UART_TX;

    constant zero    : UNSIGNED(7 downto 0) := "00110000"; --ascii value for 0
    
    signal r_DV   : STD_LOGIC;
    signal r_Byte : STD_LOGIC_VECTOR(7 downto 0);
    signal r_TX_Active : STD_LOGIC := '0';
    signal r_TX_Done : STD_LOGIC := '0';
    signal temp_LED  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
begin
    --UART_RX_Comp : UART_RX_NandLand
    --    port map( i_Clk => CLK100MHZ, i_RX_Serial => uart_rxd_in , o_RX_DV => r_DV, o_RX_Byte => r_Byte);
    
    UART_RX_Comp : UART_RX
        port map ( i_Clk => CLK100MHZ, i_RX_Serial => uart_rxd_in, o_RX_DV => r_DV, o_RX_Byte => r_Byte);

   UART_TX_Comp : UART_TX
       port map ( i_Clk => CLK100MHZ, i_TX_DV => r_DV, i_TX_Byte => r_Byte , o_TX_Active => r_TX_Active, o_TX_Serial => uart_txd_out, o_TX_Done => r_TX_Done); 
        
    calcLED : process (r_DV) is 
        begin
        
        -- Toggle LED 0 whenever done recieving a message
        if rising_edge(r_DV) then
            temp_LED <= not temp_LED;
            led <= temp_LED; 
        end if;
       -- Toggle LED 1 whenever done trasnmitting a message
       if rising_edge(r_TX_Done) then
           temp_LED(1) <= not temp_LED(1);
           led(1) <= temp_LED(1); 
       end if;
        
    end process calcLED;
    
end Behavioral;
