library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity clock_1hz is
   port (
           clk : in std_logic;
           clk_out : out std_logic;
           clk_out_ram : out std_logic
        );
end;

architecture synth of clock_1hz is

   signal count : std_logic_vector(31 downto 0);
   signal clk_cnt : std_logic_vector(1 downto 0);

begin
   process (clk) begin
      if rising_edge(clk) then
      
      
         if (count = x"000000004") then
            if (clk_cnt = "11") then
				clk_cnt <= "00";
			else
				clk_cnt <= clk_cnt + '1';
			end if;
            count <= x"00000000";
         else
            count <= count + '1';
            
         end if;
      end if;
   end process;
   clk_out <= clk_cnt(1);
   clk_out_ram <= clk_cnt(0);
end;
