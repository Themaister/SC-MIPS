--------------------------------------------------
-- mipsparts.vhd
-- sarah_harris@hmc.edu 23 october 2005
-- components used in mips processor
--------------------------------------------------


library ieee; use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
entity regfile is -- three-port register file
   port(clk:           in  std_logic;
        we3:           in  std_logic;
   ra1, ra2, wa3: in  std_logic_vector(4 downto 0);
   wd3:           in  std_logic_vector(31 downto 0);
   rd1, rd2:      out std_logic_vector(31 downto 0));
end;

architecture behave of regfile is
   type ramtype is array (31 downto 0) of std_logic_vector(31 downto 0);
   signal mem: ramtype;
begin
  -- three-ported register file
  -- read two ports combinationally
  -- write third port on rising edge of clock
  process(clk) begin
     if (clk'event and clk = '1') then
        if we3 = '1' then mem(conv_integer(wa3)) <= wd3;
     end if;
  end if;
  end process;

  rd1 <= x"00000000" when (conv_integer(ra1) = 0) -- register 0 holds 0
         else mem(conv_integer(ra1));
     rd2 <= x"00000000" when (conv_integer(ra2) = 0) -- register 0 holds 0
            else mem(conv_integer(ra2));

     end;

library ieee; use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
entity adder is -- adder
   port(a, b: in  std_logic_vector(31 downto 0);
        y:    out std_logic_vector(31 downto 0));
end;

architecture behave of adder is
begin
   y <= a + b;
end;

library ieee; use ieee.std_logic_1164.all;
entity sl2 is -- shift left by 2
   port(a: in  std_logic_vector(31 downto 0);
        y: out std_logic_vector(31 downto 0));
end;

architecture behave of sl2 is
begin
   y <= a(29 downto 0) & "00";
end;

library ieee; use ieee.std_logic_1164.all;
entity signext is -- sign extender
   port(a: in  std_logic_vector(15 downto 0);
        y: out std_logic_vector(31 downto 0));
end;

architecture behave of signext is
begin
   y <= x"0000" & a when a(15) = '0' else x"ffff" & a; 
end;

library ieee; use ieee.std_logic_1164.all;
entity signext16 is -- variable sign extender
   port(a: in  std_logic_vector(15 downto 0);
        s: in std_logic;
        y: out std_logic_vector(31 downto 0));
end;

architecture behave of signext16 is
  signal should_sign : std_logic;
begin
   should_sign <= '1' when (a(15) = '1') else '0';
   y <= x"ffff" & a when ((should_sign and s) = '1') else x"0000" & a; 
end;

library ieee; use ieee.std_logic_1164.all;
entity signext8 is -- sign extender for 8-bit to 32-bit (lb)
   port(a: in  std_logic_vector(7 downto 0);
        s: in std_logic;
        y: out std_logic_vector(31 downto 0));
end;

architecture behave of signext8 is
  signal should_sign : std_logic;
begin
   should_sign <= '1' when (a(7) = '1') else '0';
   y <= x"ffffff" & a when ((should_sign and s) = '1') else x"000000" & a; 
end;

library ieee; use ieee.std_logic_1164.all;  use ieee.std_logic_arith.all;
entity flopr is -- flip-flop with synchronous reset
   generic(width: integer);
   port(clk, reset: in  std_logic;
        d:          in  std_logic_vector(width-1 downto 0);
        q:          out std_logic_vector(width-1 downto 0));
end;

architecture asynchronous of flopr is
begin
  process(clk, reset) begin
    --if reset = '1' then  q <= conv_std_logic_vector(0, width);
     if reset = '1' then q <= x"00400090"; -- gnu mips magic :d
  elsif clk'event and clk = '1' then
     q <= d;
  end if;
  end process;
end;

library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_arith.all;
entity floprs is -- boolean flip-flop
	port (clk, reset: in std_logic;
			d: in std_logic;
			q: out std_logic);
end;

architecture synth of floprs is
begin
	process (clk, reset) begin
		if reset = '1' then q <= '0';
		elsif rising_edge(clk) then
			q <= d;
		end if;
	end process;
end;

library ieee; use ieee.std_logic_1164.all;  use ieee.std_logic_arith.all;
entity flopenr is -- flip-flop with synchronous reset
   generic(width: integer);
   port(clk, reset: in  std_logic;
        d:          in  std_logic_vector(width-1 downto 0);
        en:         in  std_logic;
        q:          out std_logic_vector(width-1 downto 0));
end;

architecture asynchronous of flopenr is
begin
  process(clk, reset) begin
     if reset = '1' then  q <= conv_std_logic_vector(0, width);
  elsif clk'event and clk = '1' and en = '1' then
     q <= d;
  end if;
  end process;
end;

library ieee; use ieee.std_logic_1164.all;
entity mux2 is -- two-input multiplexer
   generic(width: integer);
   port(d0, d1: in  std_logic_vector(width-1 downto 0);
        s:      in  std_logic;
        y:      out std_logic_vector(width-1 downto 0));
end;

architecture behave of mux2 is
begin
   y <= d0 when s = '0' else d1;
end;

-- upimm needed for lui
library ieee; use ieee.std_logic_1164.all;
entity upimm is
   port(a: in  std_logic_vector(15 downto 0);
        y: out std_logic_vector(31 downto 0));
end;

architecture behave of upimm is
begin
   y <= a & x"0000"; 
end;

-- mux3 needed for lui
library ieee; use ieee.std_logic_1164.all;
entity mux3 is -- three-input multiplexer
   generic(width: integer);
   port(d0, d1, d2: in  std_logic_vector(width-1 downto 0);
        s:          in  std_logic_vector(1 downto 0);
        y:          out std_logic_vector(width-1 downto 0));
end;

architecture behave of mux3 is
begin
  process(s, d0, d1, d2) begin
     case s is
        when "00" =>   y <= d0;
        when "01" =>   y <= d1;
        when "10" =>   y <= d2;
        when others => y <= d0;
     end case;
  end process;
end;

library ieee; use ieee.std_logic_1164.all;
entity mux4 is -- four-input multiplexer
   generic(width: integer);
   port(d0, d1, d2, d3: in  std_logic_vector(width-1 downto 0);
        s:          in  std_logic_vector(1 downto 0);
        y:          out std_logic_vector(width-1 downto 0));
end;

architecture behave of mux4 is
begin
  process(s, d0, d1, d2, d3) begin
     case s is
        when "00" =>   y <= d0;
        when "01" =>   y <= d1;
        when "10" =>   y <= d2;
        when "11" =>   y <= d3;
        when others => y <= d0;
     end case;
  end process;
end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
entity iabs is
	generic ( N : integer );
	port ( a : in std_logic_vector(N-1 downto 0);
		   aout : out std_logic_vector(N-1 downto 0);
		   p : in std_logic);
end;

architecture synth of iabs is
	signal neg : std_logic_vector(N-1 downto 0);
begin
	neg <= (not a) + '1';
	aout <= a when (a(N-1) xor p) = '1' else neg;
end;



