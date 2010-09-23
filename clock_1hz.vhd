library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity clock_1hz is
port (
	clk : in std_logic;
	clk_out : out std_logic
);
end;

architecture synth of clock_1hz is

	signal count : std_logic_vector(31 downto 0);
	
begin
	process (clk) begin
		if rising_edge(clk) then
			if (count = X"00100000") then
				clk_out <= '1';
				count <= X"00000000";
			else
				count <= count + '1';
				clk_out <= '0';
			end if;
		end if;
	end process;
end;