--------------------------------------------------
-- Seven Segment Decoder 32 bit
--
-- Input: 32 bit signal
-- Output: 32 bit signal displayed on HEX7 to HEX1
--------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY ssd_32bit IS
  PORT(ssd_in_32bit   : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
       ssd0, ssd1, ssd2, ssd3, ssd4, ssd5, ssd6, ssd7  : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)); 
END ssd_32bit;

ARCHITECTURE ssd_32bit_beh OF ssd_32bit IS
    
  component ssd IS
    port(SSD_IN   : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
         SSD_OUT  : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)); 
  end component;

BEGIN              
  ssd0disp : ssd PORT MAP( ssd_in_32bit(3 downto 0), ssd0);
  ssd1disp : ssd PORT MAP( ssd_in_32bit(7 downto 4), ssd1);
  ssd2disp : ssd PORT MAP( ssd_in_32bit(11 downto 8), ssd2);
  ssd3disp : ssd PORT MAP( ssd_in_32bit(15 downto 12), ssd3);
  ssd4disp : ssd PORT MAP( ssd_in_32bit(19 downto 16), ssd4);
  ssd5disp : ssd PORT MAP( ssd_in_32bit(23 downto 20), ssd5);
  ssd6disp : ssd PORT MAP( ssd_in_32bit(27 downto 24), ssd6);
  ssd7disp : ssd PORT MAP( ssd_in_32bit(31 downto 28), ssd7);

END ssd_32bit_beh;



--------------------------------------------------
-- Seven Segment Decoder
--
-- Input: 4 bit signal
-- Output 7 bit signal
--------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY ssd IS
  PORT(SSD_IN   : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
       SSD_OUT  : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)); 
END ssd;

ARCHITECTURE ssd_beh OF ssd IS
BEGIN
  PROCESS (SSD_in)
    BEGIN
      CASE SSD_in IS
        WHEN "0000" => SSD_out <= NOT "0111111"; -- 0
        WHEN "0001" => SSD_out <= NOT "0000110"; -- 1
        WHEN "0010" => SSD_out <= NOT "1011011"; -- 2
        WHEN "0011" => SSD_out <= NOT "1001111"; -- 3
        WHEN "0100" => SSD_out <= NOT "1100110"; -- 4
        WHEN "0101" => SSD_out <= NOT "1101101"; -- 5
        WHEN "0110" => SSD_out <= NOT "1111101"; -- 6
        WHEN "0111" => SSD_out <= NOT "0000111"; -- 7
        WHEN "1000" => SSD_out <= NOT "1111111"; -- 8
        WHEN "1001" => SSD_out <= NOT "1101111"; -- 9
        WHEN "1010" => SSD_out <= NOT "1110111"; -- A
        WHEN "1011" => SSD_out <= NOT "1111100"; -- B
        WHEN "1100" => SSD_out <= NOT "0111001"; -- C
        WHEN "1101" => SSD_out <= NOT "1011110"; -- D
        WHEN "1110" => SSD_out <= NOT "1111001"; -- E
        WHEN "1111" => SSD_out <= NOT "1110001"; -- F
        WHEN OTHERS => SSD_out <= NOT "1000000"; -- -              
      END CASE;
  END PROCESS;
END ssd_beh;


--------------------------------------------------
-- LCD Char Converter
--
-- Input: 4 bit signal
-- Output 8 bit signal
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LCDCharConverter is
  port( char    : in std_logic_vector(3 downto 0);
        charLCD : out std_logic_vector(7 downto 0));
end LCDCharConverter;

architecture LCDCharConverter_beh of LCDCharConverter is
begin
  process (char)
    begin
      case char is
        WHEN "0000" => charLCD <= X"30"; -- 0
        WHEN "0001" => charLCD <= X"31"; -- 1
        WHEN "0010" => charLCD <= X"32"; -- 2
        WHEN "0011" => charLCD <= X"33"; -- 3
        WHEN "0100" => charLCD <= X"34"; -- 4
        WHEN "0101" => charLCD <= X"35"; -- 5
        WHEN "0110" => charLCD <= X"36"; -- 6
        WHEN "0111" => charLCD <= X"37"; -- 7
        WHEN "1000" => charLCD <= X"38"; -- 8
        WHEN "1001" => charLCD <= X"39"; -- 9
        WHEN "1010" => charLCD <= X"41"; -- A
        WHEN "1011" => charLCD <= X"42"; -- B
        WHEN "1100" => charLCD <= X"43"; -- C
        WHEN "1101" => charLCD <= X"44"; -- D
        WHEN "1110" => charLCD <= X"45"; -- E
        WHEN "1111" => charLCD <= X"46"; -- F
        WHEN OTHERS => charLCD <= X"A0"; -- -
      end case;
  end process;
end LCDCharConverter_beh;





---------------------------------------------------
-- LCD Driver Module for driving HD44780 Controller
-- A. Greensted, June 2007
--
-- Modified by Jorgen K Dohlie, January 2010
--

-- Generic tickNum must be set such that:
-- tickNum = 10us / Period clk
-- This provides an internal tick every 10us
-- Clk: 100 MHz, tickNum: 1000
-- Clk: 32 MHz, tickNum: 320
-- Clk: 10 MHz, tickNum: 100
-- Clk: 50 MHZ, ticknum 500
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity LCDDriver is
   generic ( tickNum    : positive := 500);
   port    ( clk        : in    std_logic; 			-- DE2: CLOCK_50
            reset       : in    std_logic;			-- DE2: Optional. Can use KEY0 (remember NOT)

            dIn32bit    : in    std_logic_vector(31 downto 0);	-- Dataadr
            dIn32bit2   : in    std_logic_vector(31 downto 0);	-- Writedata
            wEn         : in    std_logic;			-- Always '1'

            -- LCD Interface
            lcdData     : out   std_logic_vector(7 downto 0);	-- DE2: LCD_DATA		
            lcdRS       : out   std_logic;			-- DE2: LCD_RS
            lcdRW       : out   std_logic;			-- DE2: LCD_RW
            lcdE        : out   std_logic);			-- DE2: LCD_EN

end LCDDriver;

architecture Structural of LCDDriver is

   component LCDCharConverter is
     port(char    : in std_logic_vector(3 downto 0);
          charLCD : out std_logic_vector(7 downto 0));
   end component;  
   
   
   -- LCD interface constants
   constant LCD_READ      : std_logic := '1';
   constant LCD_WRITE     : std_logic := '0';
   constant DATA_CODE     : std_logic := '1';
   constant INSN_CODE     : std_logic := '0';

   -- Tick Generation
   subtype TICK_COUNTER_TYPE is integer range 0 to tickNum;
   signal tick            : std_logic;

   constant WARMUP_DELAY  : integer := 2000;  -- 2000: 20ms
   constant INIT_DELAY    : integer := 500;   -- 500:  5ms
   constant CHAR_DELAY    : integer := 10;    -- 10:   100us

   subtype DELAY_TYPE is integer range 0 to WARMUP_DELAY;
   signal timer           : DELAY_TYPE;

   type INIT_ROM_TYPE is array (0 to 6) of std_logic_vector(7 downto 0);
   constant initROM       : INIT_ROM_TYPE := (  b"0011_0000",  -- Init
                                                b"0011_0000",  -- Init
                                                b"0011_0000",  -- Init
                                                b"0011_1000",  -- Function Set: 8 bit, 2 lines, 5x7 characters
                                                b"0000_1100",  -- Display On/Off Control: Display on, Cursor off, Blink off
                                                b"0000_0001",  -- Clear Display: Move cursor to home
                                                b"0000_0110"); -- Entry Mode Set: Auto increment cursor, don't shift display

   type CHAR_RAM_TYPE is array(0 to 39) of std_logic_vector(7 downto 0);
   signal charRAM         : CHAR_RAM_TYPE := (   0=>x"44", 1=>x"61", 2=>x"74", 3=>x"61", 4=>x"61", 5=>x"64", 6=>x"72",
                                                20=>x"57", 21=>x"72", 22=>x"74", 23=>x"64", 24=>x"61", 25=>x"74", 26=>X"61",
                                                others=>x"A0");

   signal setLine         : std_logic;
   signal lineNum         : integer range 0 to 1;
   signal initialising    : std_logic;

   signal initROMPointer  : integer range 0 to INIT_ROM_TYPE'high;
   signal charRAMPointer  : integer range 0 to CHAR_RAM_TYPE'high;

   type STATE_TYPE is (WARMUP, STAGE1, STAGE2, STAGE3, DELAY);
   signal state           : STATE_TYPE;

begin

--process (charRAM)
--begin
  
conv_char0 : LCDCharConverter PORT MAP(dIn32bit(3 downto 0), charRam(15));
conv_char1 : LCDCharConverter PORT MAP(dIn32bit(7 downto 4), charRam(14));
conv_char2 : LCDCharConverter PORT MAP(dIn32bit(11 downto 8), charRam(13));
conv_char3 : LCDCharConverter PORT MAP(dIn32bit(15 downto 12), charRam(12));
conv_char4 : LCDCharConverter PORT MAP(dIn32bit(19 downto 16), charRam(11));
conv_char5 : LCDCharConverter PORT MAP(dIn32bit(23 downto 20), charRam(10));
conv_char6 : LCDCharConverter PORT MAP(dIn32bit(27 downto 24), charRam(9));
conv_char7 : LCDCharConverter PORT MAP(dIn32bit(31 downto 28), charRam(8));

conv_char8 : LCDCharConverter PORT MAP(dIn32bit2(3 downto 0), charRam(35));
conv_char9 : LCDCharConverter PORT MAP(dIn32bit2(7 downto 4), charRam(34));
conv_char10 : LCDCharConverter PORT MAP(dIn32bit2(11 downto 8), charRam(33));
conv_char11 : LCDCharConverter PORT MAP(dIn32bit2(15 downto 12), charRam(32));
conv_char12 : LCDCharConverter PORT MAP(dIn32bit2(19 downto 16), charRam(31));
conv_char13 : LCDCharConverter PORT MAP(dIn32bit2(23 downto 20), charRam(30));
conv_char14 : LCDCharConverter PORT MAP(dIn32bit2(27 downto 24), charRam(29));
conv_char15 : LCDCharConverter PORT MAP(dIn32bit2(31 downto 28), charRam(28));


lcdRW <= LCD_WRITE;

TickGen : process(clk)
   variable tickCounter : TICK_COUNTER_TYPE;
begin
   if (clk'event and clk='1') then
      if (tickCounter = 0) then
         tickCounter := TICK_COUNTER_TYPE'high-1;
         tick <= '1';
      else
         tickCounter := tickCounter - 1;
         tick <= '0';
      end if;
   end if;
end process;

--CharRAMWrite : process(clk)
--   variable add : integer range 0 to 39;
--begin
--   if (clk'event and clk='1') then
--      if (wEn='1') then
--         add := to_integer(unsigned(charNum));
--         charRAM(add) <= dIn;
--      end if;
--   end if;
--end process;

Controller : process (clk)
begin
   if (clk'event and clk='1') then

      if (reset='1') then
         timer          <= WARMUP_DELAY;
         initROMPointer <= 0;
         charRAMPointer <= 0;

         lcdRS          <= INSN_CODE;
         lcdE           <= '0';
         lcdData        <= (others => '0');

         initialising   <= '1';
         setLine        <= '0';
         lineNum        <= 0;
         state          <= WARMUP;

      elsif (tick='1') then

         case state is

            -- Perform initial long warmup delay
            when WARMUP =>
               if (timer=0) then
                  state <= STAGE1;
               else
                  timer <= timer - 1;
               end if;

            -- Set the LCD data
            -- Set the LCD RS
            -- Initialise the timer with the required delay
            when STAGE1 =>
               if (initialising='1') then
                  timer    <= INIT_DELAY;
                  lcdRS    <= INSN_CODE;
                  lcdData  <= initROM(initROMPointer);

               elsif (setLine='1') then
                  timer    <= CHAR_DELAY;
                  lcdRS    <= INSN_CODE;
                  case lineNum is
                     when 0 => lcdData   <= b"1000_0000"; -- x00
                     when 1 => lcdData   <= b"1100_0000"; -- x40
                  end case;

               else
                  timer    <= CHAR_DELAY;
                  lcdRS    <= DATA_CODE;
                  lcdData  <= charRAM(charRAMPointer);

               end if;

               state <= STAGE2;

            -- Set lcdE (latching RS and RW)
            when STAGE2 =>
               if (initialising='1') then
                  if (initROMPointer=INIT_ROM_TYPE'high) then
                     initialising <= '0';
                  else
                     initROMPointer <= initROMPointer + 1;
                  end if;

               elsif (setLine='1') then
                  setLine <= '0';

               else

                  if (charRAMPointer=19) then
                     setLine <= '1';
                     lineNum <= 1;

                  elsif (charRAMPointer=39) then
                     setLine <= '1';
                     lineNum <= 0;
                  end if;

                  if (charRAMPointer=CHAR_RAM_TYPE'high) then
                     charRAMPointer <= 0;
                  else
                     charRAMPointer <= charRAMPointer + 1;
                  end if;

               end if;

               lcdE  <= '1';
               state <= STAGE3;

            -- Clear lcdE (latching data)
            when STAGE3 =>
               lcdE  <= '0';
               state <= DELAY;

            -- Provide delay to allow instruciton to execute
            when DELAY =>
               if (timer=0) then
                  state <= STAGE1;
               else
                  timer <= timer - 1;
               end if;

         end case;
      end if;
   end if;
end process;

end Structural;