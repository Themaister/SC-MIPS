library ieee;
use ieee.std_logic_1164.all;
entity mips_multiplier is
	port (
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		output : out std_logic_vector(63 downto 0);
		is_unsigned : in std_logic);
end;

architecture synth of mips_multiplier is
	COMPONENT multiplier IS
		PORT
		(
			dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			result		: OUT STD_LOGIC_VECTOR (63 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT multiplier_signed IS
		PORT
		(
			dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
			result		: OUT STD_LOGIC_VECTOR (63 DOWNTO 0)
		);
	END COMPONENT;
	
	component mux2 is -- two-input multiplexer
		generic(width: integer);
	   port(d0, d1: in  std_logic_vector(width-1 downto 0);
			s:      in  std_logic;
			y:      out std_logic_vector(width-1 downto 0));
	end component;
	
	signal result_unsigned, result_signed : std_logic_vector(63 downto 0);
	
begin
	mult1 : multiplier port map(a, b, result_unsigned);
	mult2 : multiplier port map(a, b, result_signed);
	mux : mux2 generic map(64) port map(result_signed, result_unsigned, is_unsigned, output);
end;