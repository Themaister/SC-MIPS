--------------------------------------------------
-- mipsparts.vhd
-- sarah_harris@hmc.edu 23 october 2005
-- components used in mips processor
--------------------------------------------------

--------------------------------------------------------------------
-- Hans-Kristian Arntzen: Added several more necessary components
--------------------------------------------------------------------


library ieee; use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
entity regfile is -- three-port register file
   port
   (
      clk : in  std_logic;
      we3 : in  std_logic;
      ra1, ra2, wa3 : in  std_logic_vector(4 downto 0);
      wd3 : in  std_logic_vector(31 downto 0);
      rd1, rd2 : out std_logic_vector(31 downto 0)
   );
end;

architecture behave of regfile is
   type ramtype is array (31 downto 0) of std_logic_vector(31 downto 0);
   signal mem : ramtype;
begin
  -- three-ported register file
  -- read two ports combinationally
  -- write third port on rising edge of clock
  process(clk) begin
     if rising_edge(clk) then
        if we3 = '1' then 
           mem(conv_integer(wa3)) <= wd3;
        end if;
     end if;
  end process;

  rd1 <= x"00000000" when (conv_integer(ra1) = 0) -- register 0 holds 0
         else mem(conv_integer(ra1));
  rd2 <= x"00000000" when (conv_integer(ra2) = 0) -- register 0 holds 0
         else mem(conv_integer(ra2));
end;

-- Dunno why this was a component ...
library ieee; use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
entity adder is -- adder
   port
   (
      a, b : in  std_logic_vector(31 downto 0);
      y : out std_logic_vector(31 downto 0)
   );
end;

architecture behave of adder is
begin
   y <= a + b;
end;

library ieee; use ieee.std_logic_1164.all;
entity sl2 is -- shift left by 2
   port
   (
      a: in  std_logic_vector(31 downto 0);
      y: out std_logic_vector(31 downto 0)
   );
end;

architecture behave of sl2 is
begin
   y <= a(29 downto 0) & "00";
end;

library ieee; use ieee.std_logic_1164.all;
entity signext is -- sign extender
   port
   (
      a: in  std_logic_vector(15 downto 0);
      y: out std_logic_vector(31 downto 0)
   );
end;

architecture behave of signext is
begin
   y <= x"0000" & a when a(15) = '0' else x"ffff" & a; 
end;

library ieee; use ieee.std_logic_1164.all;
entity signext16 is -- variable sign extender
   port
   (
      a: in  std_logic_vector(15 downto 0);
      s: in std_logic;
      y: out std_logic_vector(31 downto 0)
   );
end;

architecture behave of signext16 is
   signal should_sign : std_logic;
begin
   should_sign <= '1' when (a(15) = '1') else '0';
   y <= x"ffff" & a when ((should_sign and s) = '1') else x"0000" & a; 
end;

library ieee; use ieee.std_logic_1164.all;
entity signext8 is -- sign extender for 8-bit to 32-bit (lb)
   port
   (
      a: in  std_logic_vector(7 downto 0);
      s: in std_logic;
      y: out std_logic_vector(31 downto 0)
   );
end;

architecture behave of signext8 is
   signal should_sign : std_logic;
begin
   should_sign <= '1' when (a(7) = '1') else '0';
   y <= x"ffffff" & a when ((should_sign and s) = '1') else x"000000" & a; 
end;

library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_arith.all;
entity flopr is -- flip-flop with synchronous reset
   generic(width : integer);
   port
   (
      clk, reset : in  std_logic;
      d : in  std_logic_vector(width-1 downto 0);
      q : out std_logic_vector(width-1 downto 0)
   );
end;

architecture asynchronous of flopr is
begin
  process(clk, reset) begin
     if reset = '1' then
        q <= conv_std_logic_vector(0, width);
     elsif rising_edge(clk) then
        q <= d;
     end if;
  end process;
end;

-- Flip-flop we use for our PC, reset needs a certain reset vector (0x00400000).
library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_arith.all;
entity flopr_pc is -- flip-flop with synchronous reset
   port
   (
      clk, reset: in  std_logic;
      d : in  std_logic_vector(31 downto 0);
      q : out std_logic_vector(31 downto 0)
   );
end;

architecture asynchronous of flopr_pc is
begin
  process(clk, reset) begin
     if reset = '1' then 
        q <= x"00400000"; -- Our entry point
     elsif rising_edge(clk) then
        q <= d;
     end if;
  end process;
end;


library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_arith.all;
entity floprs is -- boolean flip-flop
   port 
   (
      clk, reset : in std_logic;
      d : in std_logic;
      q : out std_logic
   );
end;

architecture synth of floprs is
begin
   process (clk, reset) begin
      if reset = '1' then 
         q <= '0';
      elsif rising_edge(clk) then
         q <= d;
      end if;
   end process;
end;

library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_arith.all;
entity flopenr is -- flip-flop with synchronous reset
   generic(width: integer);
   port
   (
      clk, reset : in  std_logic;
      d : in  std_logic_vector(width-1 downto 0);
      en : in  std_logic;
      q : out std_logic_vector(width-1 downto 0)
   );
end;

architecture asynchronous of flopenr is
begin
  process(clk, reset) begin
     if reset = '1' then  
        q <= conv_std_logic_vector(0, width);
     elsif rising_edge(clk) and en = '1' then
        q <= d;
     end if;
  end process;
end;

library ieee; use ieee.std_logic_1164.all;
entity mux2 is -- two-input multiplexer
   generic(width: integer);
   port
   (
      d0, d1 : in  std_logic_vector(width-1 downto 0);
      s : in  std_logic;
      y : out std_logic_vector(width-1 downto 0)
   );
end;

architecture behave of mux2 is
begin
   y <= d0 when s = '0' else d1;
end;

-- upimm needed for lui
library ieee; use ieee.std_logic_1164.all;
entity upimm is
   port
   (
      a: in  std_logic_vector(15 downto 0);
      y: out std_logic_vector(31 downto 0)
   );
end;

architecture behave of upimm is
begin
   y <= a & x"0000"; 
end;

-- mux3 needed for lui
library ieee; use ieee.std_logic_1164.all;
entity mux3 is -- three-input multiplexer
   generic(width: integer);
   port
   (
      d0, d1, d2 : in  std_logic_vector(width-1 downto 0);
      s : in  std_logic_vector(1 downto 0);
      y : out std_logic_vector(width-1 downto 0)
   );
end;

architecture behave of mux3 is
begin
  process(s, d0, d1, d2) begin
     case s is
        when "00" => y <= d0;
        when "01" => y <= d1;
        when "10" => y <= d2;
        when others => y <= d0;
     end case;
  end process;
end;

library ieee; use ieee.std_logic_1164.all;
entity mux4 is -- four-input multiplexer
   generic(width: integer);
   port
   (
      d0, d1, d2, d3 : in  std_logic_vector(width-1 downto 0);
      s : in  std_logic_vector(1 downto 0);
      y : out std_logic_vector(width-1 downto 0)
   );
end;

architecture behave of mux4 is
begin
  process(s, d0, d1, d2, d3) begin
     case s is
        when "00" => y <= d0;
        when "01" => y <= d1;
        when "10" => y <= d2;
        when "11" => y <= d3;
        when others => y <= d0;
     end case;
  end process;
end;

-- Allows us to force either negative or positive.
library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_unsigned.all;
entity iabs is
   generic(N : integer);
   port
   ( 
      a : in std_logic_vector(N-1 downto 0);
      aout : out std_logic_vector(N-1 downto 0);
      p : in std_logic
   );
end;

architecture synth of iabs is
   signal neg : std_logic_vector(N-1 downto 0);
begin
   neg <= (not a) + '1';
   aout <= a when (a(N-1) xor p) = '1' else neg;
end;


-- Tristate buffer needed for SRAM handler.
library altera; use altera.altera_primitives_components.all;
library ieee; use ieee.std_logic_1164.all;
entity tristate16 is
   port 
   (
      input : in std_logic_vector(15 downto 0);
      oe : in std_logic;
      output : out std_logic_vector(15 downto 0)
   );
end;

architecture synth of tristate16 is -- Gief for-loop plx :v
begin
   tribuf0 :  TRI port map (input(0),  oe, output(0));
   tribuf1 :  TRI port map (input(1),  oe, output(1));
   tribuf2 :  TRI port map (input(2),  oe, output(2));
   tribuf3 :  TRI port map (input(3),  oe, output(3));
   tribuf4 :  TRI port map (input(4),  oe, output(4));
   tribuf5 :  TRI port map (input(5),  oe, output(5));
   tribuf6 :  TRI port map (input(6),  oe, output(6));
   tribuf7 :  TRI port map (input(7),  oe, output(7));
   tribuf8 :  TRI port map (input(8),  oe, output(8));
   tribuf9 :  TRI port map (input(9),  oe, output(9));
   tribuf10 : TRI port map (input(10), oe, output(10));
   tribuf11 : TRI port map (input(11), oe, output(11));
   tribuf12 : TRI port map (input(12), oe, output(12));
   tribuf13 : TRI port map (input(13), oe, output(13));
   tribuf14 : TRI port map (input(14), oe, output(14));
   tribuf15 : TRI port map (input(15), oe, output(15));
end;



