library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity divider is
  port (
    SW : in std_logic_vector(17 downto 0);
    LEDR : out std_logic_vector(15 downto 0));
end;

architecture synth of divider is
	component array_div is
	port (
		a : in std_logic_vector(15 downto 0);
		b : in std_logic_vector(15 downto 0);
		D_out : out std_logic_vector(15 downto 0);
		R_out : out std_logic_vector(15 downto 0));
	end component;
	
	component iabs is
		generic ( N : integer );
		port ( a : in std_logic_vector(N-1 downto 0);
				aout : out std_logic_vector(N-1 downto 0);
				p : in std_logic);
	end component;
	
	component mux2 is
		generic ( N : integer );
		port (
			a : in std_logic_vector(N-1 downto 0);
			b : in std_logic_vector(N-1 downto 0);
			s : in std_logic;
			o : out std_logic_vector(N-1 downto 0));
	end component;

	signal num, denom, div, res : std_logic_vector(15 downto 0);
	signal num_abs, denom_abs, div_abs, res_abs : std_logic_vector(15 downto 0);
	signal num_u, denom_u : std_logic_vector(15 downto 0);
	signal use_unsigned : std_logic;
	
	type bus_t is array(15 downto 0) of std_logic_vector(15 downto 0);
	signal d : bus_t;
	signal r : bus_t;
	
begin
	num <= conv_std_logic_vector(0, 8) & SW(15 downto 8);
	denom <= conv_std_logic_vector(0, 8) & SW(7 downto 0);
	use_unsigned <= SW(17);
	LEDR(15 downto 8) <= div_abs(7 downto 0);
	LEDR(7 downto 0) <= res_abs(7 downto 0); 
	
	abs_1 : iabs generic map(16) port map(num, num_abs, '1');
	abs_2 : iabs generic map(16) port map(denom, denom_abs, '1');
	abs_3 : iabs generic map(16) port map(res, res_abs, (not num(7)) or use_unsigned);
	abs_4 : iabs generic map(16) port map(div, div_abs, (not (num(7) xor denom(7))) or use_unsigned);
	
	mux_1 : mux2 generic map(16) port map(num_abs, num, use_unsigned, num_u);
	mux_2 : mux2 generic map(16) port map(denom_abs, denom, use_unsigned, denom_u);

	-- Oh dear...
	div1 : array_div port map(num_u, denom_u, d(0), r(0));
	div2 : array_div port map(r(0), denom_u, d(1), r(1));
	div3 : array_div port map(r(1), denom_u, d(2), r(2));
	div4 : array_div port map(r(2), denom_u, d(3), r(3));
	div5 : array_div port map(r(3), denom_u, d(4), r(4));
	div6 : array_div port map(r(4), denom_u, d(5), r(5));
	div7 : array_div port map(r(5), denom_u, d(6), r(6));
	div8 : array_div port map(r(6), denom_u, d(7), r(7));
	div9 : array_div port map(r(7), denom_u, d(8), r(8));
	div10 : array_div port map(r(8), denom_u, d(9), r(9));
	div11 : array_div port map(r(9), denom_u, d(10), r(10));
	div12 : array_div port map(r(10), denom_u, d(11), r(11));
	div13 : array_div port map(r(11), denom_u, d(12), r(12));
	div14 : array_div port map(r(12), denom_u, d(13), r(13));
	div15 : array_div port map(r(13), denom_u, d(14), r(14));
	div16 : array_div port map(r(14), denom_u, d(15), r(15));
	
	div <= 	d(0) + d(1) + d(2) +
			d(3) + d(4) + d(5) + d(6) + d(7) +
			d(8) + d(9) + d(10) +
			d(11) + d(12) + d(13) + d(14) + d(15);
	res <= r(15);
end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity array_div_elem is
  generic ( N : integer );
  port (
    a : in std_logic_vector(N downto 0);
    b : in std_logic_vector(N downto 0);
    D : in std_logic_vector(N downto 0);
    R : in std_logic_vector(N downto 0);
    a_out : out std_logic_vector(N downto 0);
    b_out : out std_logic_vector(N downto 0);
    D_out : out std_logic_vector(N downto 0);
    R_out : out std_logic_vector(N downto 0));
end;

architecture synth of array_div_elem is
  signal comp : std_logic_vector(N downto 0);
  signal is_neg : std_logic;
  signal shift_in : std_logic;
begin
  is_neg <= comp(N);
  comp <= a + (not b) + '1';
  
  a_out <= a;
  
  shift_in <= '1' when D = conv_std_logic_vector(0, N) else '0';
  
  b_out <= (b(N-1 downto 0) & '0') when is_neg = '0' else b;
  D_out <= (D(N-1 downto 0) & shift_in) when is_neg = '0' else D;
  R_out <= comp when is_neg = '0' else R;
end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity array_div is
	port (
		a : in std_logic_vector(15 downto 0);
		b : in std_logic_vector(15 downto 0);
		D_out : out std_logic_vector(15 downto 0);
		R_out : out std_logic_vector(15 downto 0));
end;

architecture synth of array_div is
	component array_div_elem is
	  generic ( N : integer );
	  port (
		a : in std_logic_vector(N downto 0);
		b : in std_logic_vector(N downto 0);
		D : in std_logic_vector(N downto 0);
		R : in std_logic_vector(N downto 0);
		a_out : out std_logic_vector(N downto 0);
		b_out : out std_logic_vector(N downto 0);
		D_out : out std_logic_vector(N downto 0);
		R_out : out std_logic_vector(N downto 0));
	end component;
	
	type bus_t is array(16 downto 0) of std_logic_vector(16 downto 0);
	signal bus_a : bus_t;
	signal bus_b : bus_t;
	signal bus_D : bus_t;
	signal bus_R : bus_t;

begin
	bus_a(0) <= '0' & a;
	bus_b(0) <= '0' & b;
	bus_D(0) <= conv_std_logic_vector(0, 17);
	bus_R(0) <= '0' & a;
	D_out <= bus_D(16)(15 downto 0);
	R_out <= bus_R(16)(15 downto 0);
	
	-- Batshit crazy
	div1_1 : array_div_elem generic map(16) 
		port map(	bus_a(0), bus_b(0), bus_D(0), bus_R(0), 
					bus_a(1), bus_b(1), bus_D(1), bus_R(1));
	div1_2 : array_div_elem generic map(16) 
		port map(	bus_a(1), bus_b(1), bus_D(1), bus_R(1), 
					bus_a(2), bus_b(2), bus_D(2), bus_R(2));
	div1_3 : array_div_elem generic map(16) 
		port map(	bus_a(2), bus_b(2), bus_D(2), bus_R(2), 
					bus_a(3), bus_b(3), bus_D(3), bus_R(3));
	div1_4 : array_div_elem generic map(16) 
		port map(	bus_a(3), bus_b(3), bus_D(3), bus_R(3), 
					bus_a(4), bus_b(4), bus_D(4), bus_R(4));
	div1_5 : array_div_elem generic map(16) 
		port map(	bus_a(4), bus_b(4), bus_D(4), bus_R(4), 
					bus_a(5), bus_b(5), bus_D(5), bus_R(5));
	div1_6 : array_div_elem generic map(16) 
		port map(	bus_a(5), bus_b(5), bus_D(5), bus_R(5), 
					bus_a(6), bus_b(6), bus_D(6), bus_R(6));
	div1_7 : array_div_elem generic map(16) 
		port map(	bus_a(6), bus_b(6), bus_D(6), bus_R(6), 
					bus_a(7), bus_b(7), bus_D(7), bus_R(7));
	div1_8 : array_div_elem generic map(16) 
		port map(	bus_a(7), bus_b(7), bus_D(7), bus_R(7), 
					bus_a(8), bus_b(8), bus_D(8), bus_R(8));
	div1_9 : array_div_elem generic map(16) 
		port map(	bus_a(8), bus_b(8), bus_D(8), bus_R(8), 
					bus_a(9), bus_b(9), bus_D(9), bus_R(9));
	div1_10 : array_div_elem generic map(16) 
		port map(	bus_a(9), bus_b(9), bus_D(9), bus_R(9), 
					bus_a(10), bus_b(10), bus_D(10), bus_R(10));
	div1_11 : array_div_elem generic map(16) 
		port map(	bus_a(10), bus_b(10), bus_D(10), bus_R(10), 
					bus_a(11), bus_b(11), bus_D(11), bus_R(11));
	div1_12 : array_div_elem generic map(16) 
		port map(	bus_a(11), bus_b(11), bus_D(11), bus_R(11), 
					bus_a(12), bus_b(12), bus_D(12), bus_R(12));
	div1_13 : array_div_elem generic map(16) 
		port map(	bus_a(12), bus_b(12), bus_D(12), bus_R(12), 
					bus_a(13), bus_b(13), bus_D(13), bus_R(13));
	div1_14 : array_div_elem generic map(16) 
		port map(	bus_a(13), bus_b(13), bus_D(13), bus_R(13), 
					bus_a(14), bus_b(14), bus_D(14), bus_R(14));
	div1_15 : array_div_elem generic map(16) 
		port map(	bus_a(14), bus_b(14), bus_D(14), bus_R(14), 
					bus_a(15), bus_b(15), bus_D(15), bus_R(15));
	div1_16 : array_div_elem generic map(16) 
		port map(	bus_a(15), bus_b(15), bus_D(15), bus_R(15), 
					bus_a(16), bus_b(16), bus_D(16), bus_R(16));
					
end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity mux2 is
	generic ( N : integer );
	port (
		a : in std_logic_vector(N-1 downto 0);
		b : in std_logic_vector(N-1 downto 0);
		s : in std_logic;
		o : out std_logic_vector(N-1 downto 0));
end;

architecture synth of mux2 is
begin
	o <= b when s = '1' else a;
end;
