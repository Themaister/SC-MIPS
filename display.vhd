--------------------------------------------------
-- seven segment decoder 32 bit
--
-- input: 32 bit signal
-- output: 32 bit signal displayed on hex7 to hex1
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ssd_32bit is
   port(ssd_in_32bit   : in std_logic_vector (31 downto 0);
   ssd0, ssd1, ssd2, ssd3, ssd4, ssd5, ssd6, ssd7  : out std_logic_vector (6 downto 0)); 
end ssd_32bit;

architecture ssd_32bit_beh of ssd_32bit is

   component ssd is
   port(ssd_in   : in std_logic_vector (3 downto 0);
        ssd_out  : out std_logic_vector (6 downto 0)); 
   end component;

begin              
   ssd0disp : ssd port map( ssd_in_32bit(3 downto 0), ssd0);
   ssd1disp : ssd port map( ssd_in_32bit(7 downto 4), ssd1);
   ssd2disp : ssd port map( ssd_in_32bit(11 downto 8), ssd2);
   ssd3disp : ssd port map( ssd_in_32bit(15 downto 12), ssd3);
   ssd4disp : ssd port map( ssd_in_32bit(19 downto 16), ssd4);
   ssd5disp : ssd port map( ssd_in_32bit(23 downto 20), ssd5);
   ssd6disp : ssd port map( ssd_in_32bit(27 downto 24), ssd6);
   ssd7disp : ssd port map( ssd_in_32bit(31 downto 28), ssd7);

end ssd_32bit_beh;



--------------------------------------------------
-- seven segment decoder
--
-- input: 4 bit signal
-- output 7 bit signal
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ssd is
   port(ssd_in   : in std_logic_vector (3 downto 0);
        ssd_out  : out std_logic_vector (6 downto 0)); 
end ssd;

architecture ssd_beh of ssd is
begin
   process (ssd_in)
   begin
      case ssd_in is
         when "0000" => ssd_out <= not "0111111"; -- 0
         when "0001" => ssd_out <= not "0000110"; -- 1
         when "0010" => ssd_out <= not "1011011"; -- 2
         when "0011" => ssd_out <= not "1001111"; -- 3
         when "0100" => ssd_out <= not "1100110"; -- 4
         when "0101" => ssd_out <= not "1101101"; -- 5
         when "0110" => ssd_out <= not "1111101"; -- 6
         when "0111" => ssd_out <= not "0000111"; -- 7
         when "1000" => ssd_out <= not "1111111"; -- 8
         when "1001" => ssd_out <= not "1101111"; -- 9
         when "1010" => ssd_out <= not "1110111"; -- a
         when "1011" => ssd_out <= not "1111100"; -- b
         when "1100" => ssd_out <= not "0111001"; -- c
         when "1101" => ssd_out <= not "1011110"; -- d
         when "1110" => ssd_out <= not "1111001"; -- e
         when "1111" => ssd_out <= not "1110001"; -- f
         when others => ssd_out <= not "1000000"; -- -              
      end case;
   end process;
end ssd_beh;


--------------------------------------------------
-- lcd char converter
--
-- input: 4 bit signal
-- output 8 bit signal
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcdcharconverter is
   port( char    : in std_logic_vector(3 downto 0);
         charlcd : out std_logic_vector(7 downto 0));
end lcdcharconverter;

architecture lcdcharconverter_beh of lcdcharconverter is
begin
   process (char)
   begin
      case char is
         when "0000" => charlcd <= x"30"; -- 0
         when "0001" => charlcd <= x"31"; -- 1
         when "0010" => charlcd <= x"32"; -- 2
         when "0011" => charlcd <= x"33"; -- 3
         when "0100" => charlcd <= x"34"; -- 4
         when "0101" => charlcd <= x"35"; -- 5
         when "0110" => charlcd <= x"36"; -- 6
         when "0111" => charlcd <= x"37"; -- 7
         when "1000" => charlcd <= x"38"; -- 8
         when "1001" => charlcd <= x"39"; -- 9
         when "1010" => charlcd <= x"41"; -- a
         when "1011" => charlcd <= x"42"; -- b
         when "1100" => charlcd <= x"43"; -- c
         when "1101" => charlcd <= x"44"; -- d
         when "1110" => charlcd <= x"45"; -- e
         when "1111" => charlcd <= x"46"; -- f
         when others => charlcd <= x"a0"; -- -
      end case;
   end process;
end lcdcharconverter_beh;





---------------------------------------------------
-- lcd driver module for driving hd44780 controller
-- a. greensted, june 2007
--
-- modified by jorgen k dohlie, january 2010
--

-- generic ticknum must be set such that:
-- ticknum = 10us / period clk
-- this provides an internal tick every 10us
-- clk: 100 mhz, ticknum: 1000
-- clk: 32 mhz, ticknum: 320
-- clk: 10 mhz, ticknum: 100
-- clk: 50 mhz, ticknum 500
---------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lcddriver is
   generic ( ticknum    : positive := 500);
   port    ( clk        : in    std_logic; 			-- de2: clock_50
             reset       : in    std_logic;			-- de2: optional. can use key0 (remember not)

             din32bit    : in    std_logic_vector(31 downto 0);	-- dataadr
             din32bit2   : in    std_logic_vector(31 downto 0);	-- writedata
             wen         : in    std_logic;			-- always '1'

            -- lcd interface
             lcddata     : out   std_logic_vector(7 downto 0);	-- de2: lcd_data		
             lcdrs       : out   std_logic;			-- de2: lcd_rs
             lcdrw       : out   std_logic;			-- de2: lcd_rw
             lcde        : out   std_logic);			-- de2: lcd_en

end lcddriver;

architecture structural of lcddriver is

   component lcdcharconverter is
   port(char    : in std_logic_vector(3 downto 0);
        charlcd : out std_logic_vector(7 downto 0));
   end component;  


   -- lcd interface constants
   constant lcd_read      : std_logic := '1';
   constant lcd_write     : std_logic := '0';
   constant data_code     : std_logic := '1';
   constant insn_code     : std_logic := '0';

   -- tick generation
   subtype tick_counter_type is integer range 0 to ticknum;
   signal tick            : std_logic;

   constant warmup_delay  : integer := 2000;  -- 2000: 20ms
   constant init_delay    : integer := 500;   -- 500:  5ms
   constant char_delay    : integer := 10;    -- 10:   100us

   subtype delay_type is integer range 0 to warmup_delay;
   signal timer           : delay_type;

   type init_rom_type is array (0 to 6) of std_logic_vector(7 downto 0);
   constant initrom       : init_rom_type := (  b"0011_0000",  -- init
   b"0011_0000",  -- init
   b"0011_0000",  -- init
   b"0011_1000",  -- function set: 8 bit, 2 lines, 5x7 characters
   b"0000_1100",  -- display on/off control: display on, cursor off, blink off
   b"0000_0001",  -- clear display: move cursor to home
   b"0000_0110"); -- entry mode set: auto increment cursor, don't shift display

   type char_ram_type is array(0 to 39) of std_logic_vector(7 downto 0);
   signal charram         : char_ram_type := (   0=>x"44", 1=>x"61", 2=>x"74", 3=>x"61", 4=>x"61", 5=>x"64", 6=>x"72",
   20=>x"57", 21=>x"72", 22=>x"74", 23=>x"64", 24=>x"61", 25=>x"74", 26=>x"61",
   others=>x"a0");

   signal setline         : std_logic;
   signal linenum         : integer range 0 to 1;
   signal initialising    : std_logic;

   signal initrompointer  : integer range 0 to init_rom_type'high;
   signal charrampointer  : integer range 0 to char_ram_type'high;

   type state_type is (warmup, stage1, stage2, stage3, delay);
   signal state           : state_type;

begin

--process (charram)
--begin

   conv_char0 : lcdcharconverter port map(din32bit(3 downto 0), charram(15));
   conv_char1 : lcdcharconverter port map(din32bit(7 downto 4), charram(14));
   conv_char2 : lcdcharconverter port map(din32bit(11 downto 8), charram(13));
   conv_char3 : lcdcharconverter port map(din32bit(15 downto 12), charram(12));
   conv_char4 : lcdcharconverter port map(din32bit(19 downto 16), charram(11));
   conv_char5 : lcdcharconverter port map(din32bit(23 downto 20), charram(10));
   conv_char6 : lcdcharconverter port map(din32bit(27 downto 24), charram(9));
   conv_char7 : lcdcharconverter port map(din32bit(31 downto 28), charram(8));

   conv_char8 : lcdcharconverter port map(din32bit2(3 downto 0), charram(35));
   conv_char9 : lcdcharconverter port map(din32bit2(7 downto 4), charram(34));
   conv_char10 : lcdcharconverter port map(din32bit2(11 downto 8), charram(33));
   conv_char11 : lcdcharconverter port map(din32bit2(15 downto 12), charram(32));
   conv_char12 : lcdcharconverter port map(din32bit2(19 downto 16), charram(31));
   conv_char13 : lcdcharconverter port map(din32bit2(23 downto 20), charram(30));
   conv_char14 : lcdcharconverter port map(din32bit2(27 downto 24), charram(29));
   conv_char15 : lcdcharconverter port map(din32bit2(31 downto 28), charram(28));


   lcdrw <= lcd_write;

   tickgen : process(clk)
      variable tickcounter : tick_counter_type;
   begin
      if (clk'event and clk='1') then
         if (tickcounter = 0) then
            tickcounter := tick_counter_type'high-1;
            tick <= '1';
         else
            tickcounter := tickcounter - 1;
            tick <= '0';
         end if;
      end if;
   end process;

--charramwrite : process(clk)
--   variable add : integer range 0 to 39;
--begin
--   if (clk'event and clk='1') then
--      if (wen='1') then
--         add := to_integer(unsigned(charnum));
--         charram(add) <= din;
--      end if;
--   end if;
--end process;

   controller : process (clk)
   begin
      if (clk'event and clk='1') then

         if (reset='1') then
            timer          <= warmup_delay;
            initrompointer <= 0;
            charrampointer <= 0;

            lcdrs          <= insn_code;
            lcde           <= '0';
            lcddata        <= (others => '0');

            initialising   <= '1';
            setline        <= '0';
            linenum        <= 0;
            state          <= warmup;

         elsif (tick='1') then

            case state is

            -- perform initial long warmup delay
               when warmup =>
                  if (timer=0) then
                     state <= stage1;
                  else
                     timer <= timer - 1;
                  end if;

            -- set the lcd data
            -- set the lcd rs
            -- initialise the timer with the required delay
               when stage1 =>
                  if (initialising='1') then
                     timer    <= init_delay;
                     lcdrs    <= insn_code;
                     lcddata  <= initrom(initrompointer);

                  elsif (setline='1') then
                     timer    <= char_delay;
                     lcdrs    <= insn_code;
                     case linenum is
                        when 0 => lcddata   <= b"1000_0000"; -- x00
                        when 1 => lcddata   <= b"1100_0000"; -- x40
                     end case;

                  else
                     timer    <= char_delay;
                     lcdrs    <= data_code;
                     lcddata  <= charram(charrampointer);

                  end if;

                  state <= stage2;

            -- set lcde (latching rs and rw)
               when stage2 =>
                  if (initialising='1') then
                     if (initrompointer=init_rom_type'high) then
                        initialising <= '0';
                     else
                        initrompointer <= initrompointer + 1;
                     end if;

                  elsif (setline='1') then
                     setline <= '0';

                  else

                     if (charrampointer=19) then
                        setline <= '1';
                        linenum <= 1;

                     elsif (charrampointer=39) then
                        setline <= '1';
                        linenum <= 0;
                     end if;

                     if (charrampointer=char_ram_type'high) then
                        charrampointer <= 0;
                     else
                        charrampointer <= charrampointer + 1;
                     end if;

                  end if;

                  lcde  <= '1';
                  state <= stage3;

            -- clear lcde (latching data)
               when stage3 =>
                  lcde  <= '0';
                  state <= delay;

            -- provide delay to allow instruciton to execute
               when delay =>
                  if (timer=0) then
                     state <= stage1;
                  else
                     timer <= timer - 1;
                  end if;

            end case;
         end if;
      end if;
   end process;

end structural;
