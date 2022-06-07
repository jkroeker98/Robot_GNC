----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/03/2022 04:27:06 AM
-- Design Name: 
-- Module Name: GPS_Parser - Behavioral
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

entity GPS_Parser is
    Port (
        i_Clk       : in STD_LOGIC;     -- Input clock signal
        i_DV        : in STD_LOGIC;      -- Input flag, high if a new byte is available
        i_Byte      : in STD_LOGIC_VECTOR(7 downto 0);   -- Input Byte
        o_Msg_Type  : out STD_LOGIC_VECTOR(32 downto 0); -- Msg Type
        o_Full_Msg  : out STD_LOGIC_VECTOR(0 to 100 * 8 - 1) := (others => '0') -- Stores the full message
 );
end GPS_Parser;

architecture Behavioral of GPS_Parser is
    constant c_Max_Msg_Size : INTEGER := 100; -- VERIFY THIS Maximum size of a message
    
    type t_SM_Main is (s_Idle, s_Start_Byte, s_Header, s_GPGGA, s_GPGLL, s_GPGSA, s_GPGSV, s_GPRMC, s_GPVTG, S_Parse_Waiting, s_Checksum, s_EOM, s_Cleanup);
    type t_SM_GPGGA is (s_Time, s_Lat, s_N_S, s_Long, s_E_W, s_Pos_Fix, s_Sat_Count, s_HDOP, s_MSL_Alt, s_Alt_Units, s_Geoidal_Sep, s_Geo_Units, s_Age);
    type t_SM_GPGLL is (s_Lat, s_N_S, s_Long, s_E_W, s_Time, s_Status, s_Mode); 
    type t_SM_GPGSA is (s_Mode1, s_Mode2, s_SatUsed, s_PDOP, s_HDOP, s_VDOP);
    type t_SM_GPGSV is (s_Num_of_Msg, s_Msg_Num, s_Sat_View, s_Sat_ID, s_Elevation, s_Azimuth, s_SNR);
    type t_SM_GPRMC is (s_Time, s_Status, s_Lat, s_N_S, s_Long, s_E_W, s_Gnd_Speed, s_Gnd_Course, s_Date, s_Mag_Var, s_E_W_2, s_Mode);
    type t_SM_GPVTG is (s_Course, s_Ref_TF, s_Course2, s_Ref_Mag, s_Speed, s_Units_Spd, s_Speed2, s_Mode);
    
    signal r_SM_Main    : t_SM_Main := s_Idle;
    signal r_Header     : STD_LOGIC_VECTOR(0 to 39) := X"4E554C4C20"; -- Initialize to Null
    signal r_Checksum_Byte      : STD_LOGIC := '0'; -- Number of checksum byte that is being looked at (only 2 bytes)
    signal r_Checksum   : STD_LOGIC_VECTOR(0 to 15);              -- Checksum value read in
    signal r_Chars_Read : INTEGER range 0 to c_Max_Msg_Size := 0; -- Track the characters read for each message
    signal r_Full_Msg   : STD_LOGIC_VECTOR(0 to c_Max_Msg_Size * 8 - 1) := (others => '0'); -- Stores the full message
    signal r_DV         : STD_LOGIC; -- Input Flag for unique message parsers, high if new byte is available
    signal r_Byte       : STD_LOGIC_VECTOR(7 downto 0); -- Input Byte to unique message parsers
    signal r_Msg_Flag_GPGGA     : STD_LOGIC := '0'; -- Input to GPGGA_Parser to activate
    signal r_Msg_Flag_GPGLL     : STD_LOGIC := '0'; -- Input to GPGLL_Parser to activate
    signal r_Msg_Flag_GPGSA     : STD_LOGIC := '0'; -- Input to GPGSA_Parser to activate
    signal r_Msg_Flag_GPGSV     : STD_LOGIC := '0'; -- Input to GPGSV_Parser to activate
    signal r_Msg_Flag_GPRMC     : STD_LOGIC := '0'; -- Input to GPRMC_Parser to activate
    signal r_Msg_Flag_GPVTG     : STD_LOGIC := '0'; -- Input to GPVTG_Parser to activate
    signal r_Done_Flag          : STD_LOGIC := '0'; -- Output from unique message parsers when the fields are done parsing
    
    component GPGGA_Parser is
        port ( 
            i_Clk       : in STD_LOGIC;     -- Input clock signal
            i_DV        : in STD_LOGIC;     -- Input flag, hiogh if a new byte is available
            i_Byte      : in STD_LOGIC_VECTOR(7 downto 0);    -- Input byte
            i_Msg_Flag  : in STD_LOGIC;     -- Input flag, high if this the correct message
            io_Chars_Read : inout INTEGER range 0 to c_Max_Msg_Size := 0; -- Tack the current number of chars read
            io_Full_Msg : inout STD_LOGIC_VECTOR(0 to c_Max_Msg_Size * 8 - 1); -- Stores the full message
            o_Done_Flag : out STD_LOGIC     -- Output flag showing that the message unique data is done being parsed
            );
    end component GPGGA_Parser;
    
    component GPGLL_Parser is
        port ( 
            i_Clk       : in STD_LOGIC;     -- Input clock signal
            i_DV        : in STD_LOGIC;     -- Input flag, high if a new byte is available
            i_Byte      : in STD_LOGIC_VECTOR(7 downto 0);    -- Input byte
            i_Msg_Flag  : in STD_LOGIC;     -- Input flag, high if this the correct message
            io_Chars_Read : inout INTEGER range 0 to c_Max_Msg_Size := 0; -- Tack the current number of chars read
            io_Full_Msg : inout STD_LOGIC_VECTOR(0 to c_Max_Msg_Size * 8 - 1); -- Stores the full message
            o_Done_Flag : out STD_LOGIC     -- Output flag showing that the message unique data is done being parsed
           );
    end component GPGLL_Parser;
    
    component GPGSA_Parser is
        port ( 
            i_Clk       : in STD_LOGIC;     -- Input clock signal
            i_DV        : in STD_LOGIC;     -- Input flag, hiogh if a new byte is available
            i_Byte      : in STD_LOGIC_VECTOR(7 downto 0);    -- Input byte
            i_Msg_Flag  : in STD_LOGIC;     -- Input flag, high if this the correct message
            io_Chars_Read : inout INTEGER range 0 to c_Max_Msg_Size := 0; -- Tack the current number of chars read
            io_Full_Msg : inout STD_LOGIC_VECTOR(0 to c_Max_Msg_Size * 8 - 1); -- Stores the full message
            o_Done_Flag : out STD_LOGIC     -- Output flag showing that the message unique data is done being parsed
            );
    end component GPGSA_Parser;
    
    component GPGSV_Parser is
        port ( 
            i_Clk       : in STD_LOGIC;     -- Input clock signal
            i_DV        : in STD_LOGIC;     -- Input flag, hiogh if a new byte is available
            i_Byte      : in STD_LOGIC_VECTOR(7 downto 0);    -- Input byte
            i_Msg_Flag  : in STD_LOGIC;     -- Input flag, high if this the correct message
            io_Chars_Read : inout INTEGER range 0 to c_Max_Msg_Size := 0; -- Tack the current number of chars read
            io_Full_Msg : inout STD_LOGIC_VECTOR(0 to c_Max_Msg_Size * 8 - 1); -- Stores the full message
            o_Done_Flag : out STD_LOGIC     -- Output flag showing that the message unique data is done being parsed
            );
    end component GPGSV_Parser;
    
    component GPRMC_Parser is
        port ( 
            i_Clk       : in STD_LOGIC;     -- Input clock signal
            i_DV        : in STD_LOGIC;     -- Input flag, hiogh if a new byte is available
            i_Byte      : in STD_LOGIC_VECTOR(7 downto 0);    -- Input byte
            i_Msg_Flag  : in STD_LOGIC;     -- Input flag, high if this the correct message
            io_Chars_Read : inout INTEGER range 0 to c_Max_Msg_Size := 0; -- Tack the current number of chars read
            io_Full_Msg : inout STD_LOGIC_VECTOR(0 to c_Max_Msg_Size * 8 - 1); -- Stores the full message
            o_Done_Flag : out STD_LOGIC     -- Output flag showing that the message unique data is done being parsed
            );
    end component GPRMC_Parser;
    
    component GPVTG_Parser is
        port ( 
            i_Clk       : in STD_LOGIC;     -- Input clock signal
            i_DV        : in STD_LOGIC;     -- Input flag, hiogh if a new byte is available
            i_Byte      : in STD_LOGIC_VECTOR(7 downto 0);    -- Input byte
            i_Msg_Flag  : in STD_LOGIC;     -- Input flag, high if this the correct message
            io_Chars_Read : inout INTEGER range 0 to c_Max_Msg_Size := 0; -- Tack the current number of chars read
            io_Full_Msg : inout STD_LOGIC_VECTOR(0 to c_Max_Msg_Size * 8 - 1); -- Stores the full message
            o_Done_Flag : out STD_LOGIC     -- Output flag showing that the message unique data is done being parsed
            );
    end component GPVTG_Parser;
    
begin

-- Initialize Components
 GPGGA_Parser_Comp : GPGGA_Parser
                        port map (i_Clk => i_Clk, i_DV => r_DV, i_Byte => r_Byte, i_Msg_Flag => r_Msg_Flag_GPGGA, io_Chars_Read => r_Chars_Read, 
                        io_Full_Msg => r_Full_Msg, o_Done_Flag => r_Done_Flag);
 GPGLL_Parser_Comp : GPGLL_Parser
                        port map (i_Clk => i_Clk, i_DV => r_DV, i_Byte => r_Byte, i_Msg_Flag => r_Msg_Flag_GPGGA, io_Chars_Read => r_Chars_Read, 
                        io_Full_Msg => r_Full_Msg, o_Done_Flag => r_Done_Flag);
 GPGSA_Parser_Comp : GPGSA_Parser
                        port map (i_Clk => i_Clk, i_DV => r_DV, i_Byte => r_Byte, i_Msg_Flag => r_Msg_Flag_GPGGA, io_Chars_Read => r_Chars_Read, 
                        io_Full_Msg => r_Full_Msg, o_Done_Flag => r_Done_Flag);                                              
 GPGSV_Parser_Comp : GPGSV_Parser
                        port map (i_Clk => i_Clk, i_DV => r_DV, i_Byte => r_Byte, i_Msg_Flag => r_Msg_Flag_GPGGA, io_Chars_Read => r_Chars_Read, 
                        io_Full_Msg => r_Full_Msg, o_Done_Flag => r_Done_Flag);
 GPRMC_Parser_Comp : GPRMC_Parser
                        port map (i_Clk => i_Clk, i_DV => r_DV, i_Byte => r_Byte, i_Msg_Flag => r_Msg_Flag_GPGGA, io_Chars_Read => r_Chars_Read, 
                        io_Full_Msg => r_Full_Msg, o_Done_Flag => r_Done_Flag);   
GPVTG_Parser_Comp : GPVTG_Parser
                        port map (i_Clk => i_Clk, i_DV => r_DV, i_Byte => r_Byte, i_Msg_Flag => r_Msg_Flag_GPGGA, io_Chars_Read => r_Chars_Read, 
                        io_Full_Msg => r_Full_Msg, o_Done_Flag => r_Done_Flag);
                                            
-- Split into individual messages ($/0x25 start, <CR><LF>/0x0D 0A end)
parseMessage : process(i_DV)
    begin
        if i_Byte = X"2C" and rising_edge(i_DV) then -- Skip over , delimiters regardless of state, ensure i_DV for new data
            r_Full_Msg(r_Chars_Read * 8 to (r_Chars_Read + 1) * 8 - 1) <= i_Byte; 
            r_Chars_Read <= r_Chars_Read + 1;
        elsif rising_edge(i_DV) then -- Ensure i_DV is high for new data
            case r_SM_Main is
                when s_Idle =>
                    -- Wait until the beginning of a message (Will lose data if started parsing in middle of message)
                    if i_Byte = X"24" then -- Beginning of a message
                        r_Header(r_Chars_Read * 8 to (r_Chars_Read + 1) * 8 - 1) <= i_Byte;
                        r_Full_Msg(r_Chars_Read * 8 to (r_Chars_Read + 1) * 8 - 1) <= i_Byte; 
                        r_Chars_Read <= r_Chars_Read + 1;    
                        r_SM_Main <= s_Header; 
                    else
                        r_SM_Main <= s_Idle;
                    end if;
                when s_Header =>
                    r_Header(r_Chars_Read * 8 to (r_Chars_Read + 1) * 8 - 1) <= i_Byte;
                    r_Full_Msg(r_Chars_Read * 8 to (r_Chars_Read + 1) * 8 - 1) <= i_Byte;
                    r_Chars_Read <= r_Chars_Read +1;
                    if r_Chars_Read < 5 then -- Header should be 5 bytes
                        r_SM_Main <= s_Header;
                    else
                        case r_Header is 
                        -- Determine Message type
                        -- $GPGGA - Global positioning system fixed data - 0x24 47 50 47 47 41
                            when X"244750474741" =>
                                r_SM_Main <= s_GPGGA;
                        -- $GPGLL - Geographic position - latitude/longitude - 0x24 47 50 47 4C 4C
                            when X"244750474C4C" =>
                                r_SM_Main <= s_GPGLL;
                        -- $GPGSA - GNSS DOP and active satellites - 0x24 47 50 47 53 41
                            when X"244750475341" =>
                                r_SM_Main <= s_GPGSA;
                        -- $GPGSV - GNSS satellites in view -  0x24 47 50 47 53 56
                            when X"244750475356" =>
                                r_SM_Main <= s_GPGSV;
                        -- $GPRMC - Recommened minimum specific GNSS data - 0x24 47 50 52 4D 43
                            when X"244750524D43" =>
                                r_SM_Main <= s_GPRMC;
                        -- $GPVTG - Course over ground and ground speed - 0x24 47 50 56 54 47
                            when X"244750565447" =>
                                r_SM_Main <= s_GPVTG;
                        -- Unknown message format, move back to idle and wait for the next one        
                            when others =>
                                r_SM_Main <= s_Cleanup;
                        end case;
                    end if;
                -- Assign the correct message flag for the message hi
                when s_GPGGA =>
                    r_MSG_Flag_GPGGA <= '1';
                    r_SM_Main <= s_Parse_Waiting;
                when s_GPGLL =>
                    r_Msg_Flag_GPGLL <= '1';
                    r_SM_Main <= s_Parse_Waiting;
                when s_GPGSA =>
                    r_Msg_Flag_GPGSA <= '1';
                    r_SM_Main <= s_Parse_Waiting;
                when s_GPGSV =>
                    r_Msg_Flag_GPGSV <= '1';
                    r_SM_Main <= s_Parse_Waiting;
                when s_GPRMC =>
                    r_Msg_Flag_GPRMC <= '1';
                    r_SM_Main <= s_Parse_Waiting;
                when s_GPVTG =>
                    r_Msg_Flag_GPVTG <= '1';
                    r_SM_Main <= s_Parse_Waiting;
                when s_Parse_Waiting =>  -- Waiting to parse the unique message data fields
                    if r_Done_Flag = '1' then
                        r_SM_Main <= s_Checksum;
                    end if;
                when s_Checksum =>  -- Parse the checksum for the message and verify
                    -- Read in Data
                    r_Full_Msg(r_Chars_Read * 8 to (r_Chars_Read + 1) * 8 - 1) <= i_Byte;
                    r_Chars_Read <= r_Chars_Read +1;
                    if r_Checksum_Byte = '0' then
                        r_Checksum(0 to 7) <= i_Byte;
                        r_Checksum_Byte <= '1';
                    else
                        r_Checksum(8 to 15) <= i_Byte;
                        r_SM_Main <= s_EOM;  -- TODO Actually check the checksum instead of jumping to EOM
                        r_Checksum_Byte <= '0';
                    end if;   
                when s_EOM => -- Receive End of Message Characters 
                -- TODO Actually check that these are correct
                    r_Full_Msg(r_Chars_Read * 8 to (r_Chars_Read + 1) * 8 - 1) <= i_Byte;
                    r_Chars_Read <= r_Chars_Read +1;
                    if i_Byte = X"0A" then -- Check for the last byte
                        r_SM_Main <= s_Cleanup;
                    end if;
                when s_Cleanup => -- Reset all variables for the next message
                    -- Clear out message flags
                    r_MSG_Flag_GPGGA <= '0';
                    r_Msg_Flag_GPGLL <= '0';
                    r_Msg_Flag_GPGSA <= '0';
                    r_Msg_Flag_GPGSV <= '0';
                    r_Msg_Flag_GPRMC <= '0';
                    r_Msg_Flag_GPVTG <= '0';
                    r_Done_Flag <= '1';
                    
                    -- Revert chars read
                    r_Chars_Read <= 0;
                    r_Checksum_Byte <= '0';
                    
                    -- Move back to idle
                    r_SM_Main <= s_Idle;
                    
                    -- Move Message to output and empty it 
                    o_Full_Msg <= r_Full_Msg; 
                    r_Full_Msg <= (others => '0');
                when others => 
                    r_SM_Main <= s_Cleanup;
                end case;
        end if;
end process parseMessage;

o_Msg_Type <= r_Header(0 to 32);

end Behavioral;
