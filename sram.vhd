library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity sram is
	port ( 
		SW : in std_logic_vector(17 downto 0);
		KEY : in std_logic_vector(0 downto 0);
		LEDR : out std_logic_vector(17 downto 0)
	);
end;

architecture synth of sram is

COMPONENT rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (4 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END COMPONENT;

signal q : std_logic_vector(31 downto 0);

begin
	rom_1 : rom port map(SW(4 downto 0), not KEY(0), q);
	
	LEDR <= q (17 downto 0);
end;






library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
		
entity sram_old is 
	port ( 
		SW : in std_logic_vector(17 downto 0);
		KEY : in std_logic_vector(0 downto 0);
		LEDR : out std_logic_vector(17 downto 0);
		
		SRAM_ADDR : out std_logic_vector(17 downto 0);
		SRAM_DQ : inout std_logic_vector(15 downto 0);
		
		SRAM_WE_N : out std_logic;
		SRAM_CE_N : out std_logic;
		SRAM_UB_N, SRAM_LB_N : out std_logic;
		SRAM_OE_N : out std_logic
	);
end;

architecture synth of sram_old is
	signal clk : std_logic;
begin
	clk <= not KEY(0);
	
	process(clk) begin
		if rising_edge(clk) then
			SRAM_ADDR <= "00000000000000" & SW(3 downto 0);
			if SW(17) = '1' then
				SRAM_DQ <= "0000" & SW(15 downto 4);
				SRAM_WE_N <= '0';
			else
				SRAM_DQ <= (others => 'Z');
				SRAM_WE_N <= '1';
			end if;
		end if;
	end process;

	--SRAM_WE_N <= not SW(17);
	SRAM_CE_N <= '0';
	SRAM_UB_N <= '0';
	SRAM_LB_N <= '0';
	SRAM_OE_N <= '0';
	
	LEDR(15 downto 0) <= SRAM_DQ;
	LEDR(17) <= SW(17);
	--SRAM_DQ <= ("0000" & SW(15 downto 4)) when SW(17) = '1' else (others => 'Z'); 
end;
