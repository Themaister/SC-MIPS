library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity divider is
  port (
    SW : in std_logic_vector(5 downto 0);
    LEDR : out std_logic_vector(5 downto 0));
end;

architecture synth of divider is
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

	signal num, denom, div, res : std_logic_vector(2 downto 0);
	
	type bus_t is array(2 downto 0) of std_logic_vector(3 downto 0);
	type buses_t is array(2 downto 0) of bus_t;
	signal dres : bus_t;
	signal d : buses_t;
	signal r : buses_t;
	signal a : buses_t;
	signal b : buses_t;
	signal tmp_res : std_logic_vector(3 downto 0);
begin
	num <= SW(5 downto 3);
	denom <= SW(2 downto 0);
	LEDR(5 downto 3) <= div;
	LEDR(2 downto 0) <= res; 
	
	dres(0) <= d(0)(2);
	dres(1) <= d(1)(2);
	dres(2) <= d(2)(2);
	tmp_res <= r(2)(2);

	div1_1 : array_div_elem generic map(3) 
		port map(	'0' & num, '0' & denom, conv_std_logic_vector(0, 4), '0' & num, 
					a(0)(0), b(0)(0), d(0)(0), r(0)(0));
	div1_2 : array_div_elem generic map(3) 
		port map(	a(0)(0), b(0)(0), d(0)(0), r(0)(0), 
					a(0)(1), b(0)(1), d(0)(1), r(0)(1));
	div1_3 : array_div_elem generic map(3) 
		port map(	a(0)(1), b(0)(1), d(0)(1), r(0)(1), 
					a(0)(2), b(0)(2), d(0)(2), r(0)(2));
	
	div2_1 : array_div_elem generic map(3) 
		port map(	r(0)(2), '0' & denom, conv_std_logic_vector(0, 4), r(0)(2), 
					a(1)(0), b(1)(0), d(1)(0), r(1)(0));
	div2_2 : array_div_elem generic map(3) 
		port map(	a(1)(0), b(1)(0), d(1)(0), r(1)(0), 
					a(1)(1), b(1)(1), d(1)(1), r(1)(1));
	div2_3 : array_div_elem generic map(3) 
		port map(	a(1)(1), b(1)(1), d(1)(1), r(1)(1), 
					a(1)(2), b(1)(2), d(1)(2), r(1)(2));
					
	div3_1 : array_div_elem generic map(3) 
		port map(	r(1)(2), '0' & denom, conv_std_logic_vector(0, 4), r(1)(2), 
					a(2)(0), b(2)(0), d(2)(0), r(2)(0));
	div3_2 : array_div_elem generic map(3) 
		port map(	a(2)(0), b(2)(0), d(2)(0), r(2)(0), 
					a(2)(1), b(2)(1), d(2)(1), r(2)(1));
	div3_3 : array_div_elem generic map(3) 
		port map(	a(2)(1), b(2)(1), d(2)(1), r(2)(1), 
					a(2)(2), b(2)(2), d(2)(2), r(2)(2));
	
	div <= dres(0)(2 downto 0) + dres(1)(2 downto 0) + dres(2)(2 downto 0);
	res <= tmp_res(2 downto 0);
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
