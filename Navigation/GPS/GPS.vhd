----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/02/2022 04:03:55 PM
-- Design Name: 
-- Module Name: GPS - Behavioral
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

entity GPS is
    --Generic( 
    --    ClkFreq    : UNSIGNED(27 downto 0) := to_unsigned(100_000_000, 28); -- Clk freq default to 100 MHz
    --    BaudRate   : UNSIGNED(18 downto 0) := to_unsigned(9_600, 19);       -- Baud Rate (bits/sec) Default to 9600;
    --   OSRate     : UNSIGNED(4 downto 0)  := to_unsigned(16, 5);           -- Oversampling rate (samples/baud) Default to 16
    --    Width      : UNSIGNED(3 downto 0)  := to_unsigned(8, 4);            -- Data transmission width
    --    Parity     : STD_LOGIC := '0';  -- Parity {0 = none | 1 = parity}
    --    ParType    : STD_LOGIC := '0'); -- Parity type {0 = even | 1 = odd}
    Port (   
        uart_rxd_comp  : in STD_LOGIC;    -- Received data from computer via UART
        uart_rxd_gps   : in STD_LOGIC;    -- Recieved data from GPS via UART
        uart_txd_comp  : out STD_LOGIC;   -- Transmited data to computer via UART
        uart_txd_gps   : in STD_LOGIC;   -- Trasmitted data to GPS via UART
        CLK100MHZ      : in STD_LOGIC;    -- 100 MHz Clock signal
        led            : out STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- LED Outputs
        GPS_3DF        : in STD_LOGIC;    -- GPS 3D Fix Indicator
        GPS_1PPS       : in STD_LOGIC    -- GPS 1 Pulse Per Second Signal
        --rst        : in STD_LOGIC;      -- Master reset
        --data       : inout STD_LOGIC_VECTOR(7 downto 0);                    -- Data Queue
        --rx_rdy     : out STD_LOGIC;     -- New data has been received and is ready to read 
        --tx_rdy     : out STD_LOGIC;     -- New data has is being transmitted

        );
end GPS;

architecture Behavioral of GPS is
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

    signal r_DV_RX_Comp   : STD_LOGIC;
    signal r_DV_TX_Comp   : STD_LOGIC;
    signal r_DV_RX_GPS    : STD_LOGIC;
    signal r_DV_TX_GPS    : STD_LOGIC;
    signal r_Byte_RX_Comp : STD_LOGIC_VECTOR(7 downto 0);
    signal r_Byte_TX_Comp : STD_LOGIC_VECTOR(7 downto 0);
    signal r_Byte_RX_Gps : STD_LOGIC_VECTOR(7 downto 0);
    signal r_Byte_TX_Gps : STD_LOGIC_VECTOR(7 downto 0);
    signal r_TX_Active_Comp : STD_LOGIC := '0';
    signal r_TX_Active_Gps : STD_LOGIC := '0';
    signal r_TX_Done_Comp : STD_LOGIC := '0';
    signal r_TX_Done_Gps : STD_LOGIC := '0';
    signal temp_LED  : STD_LOGIC_VECTOR(3 downto 0) := "0000";
begin

    -- Define UART Components
    UART_RX_Comp : UART_RX
        port map ( i_Clk => CLK100MHZ, i_RX_Serial => uart_rxd_comp, o_RX_DV => r_DV_RX_Comp, o_RX_Byte => r_Byte_RX_Comp);

   UART_TX_Comp : UART_TX
       port map ( i_Clk => CLK100MHZ, i_TX_DV => r_DV_TX_Comp, i_TX_Byte => r_Byte_TX_Comp , 
       o_TX_Active => r_TX_Active_Comp, o_TX_Serial => uart_txd_comp, o_TX_Done => r_TX_Done_Comp); 
      
    UART_RX_Gps : UART_RX
        port map ( i_Clk => CLK100MHZ, i_RX_Serial => uart_rxd_gps, o_RX_DV => r_DV_RX_Gps, o_RX_Byte => r_Byte_RX_Gps);
        
    --UART_TX_Gps : UART_RX
    --    port map ( i_Clk => CLK100MHZ, i_RX_Serial => uart_txd_gps, o_RX_DV => r_DV_RX_Gps, o_RX_Byte => r_Byte_RX_Gps);

    
    -- Send output GPS Data to Computer
    r_DV_TX_Comp <= r_DV_RX_Gps;
    r_Byte_TX_Comp <= r_Byte_RX_Gps;
    
    -- Echo computer data
    --r_DV_TX_Comp <= r_DV_RX_Comp;
    --r_Byte_TX_Comp <= r_Byte_RX_Gps
    
    calcLED : process (r_DV_RX_Comp, r_DV_RX_GPS, GPS_1PPS)
        begin
        
        -- Toggle LED 0 whenever done recieving a message
        if rising_edge(r_DV_RX_Comp) then
            temp_LED(0) <= not temp_LED(0);
            led(0) <= temp_LED(0); 
        end if;
       -- Toggle LED 1 whenever done trasnmitting a message
       if rising_edge(r_DV_RX_GPS) then
           temp_LED(1) <= not temp_LED(1);
           led(1) <= temp_LED(1); 
       end if;
       led(2) <= GPS_1PPS;
    end process calcLED;
end Behavioral;
