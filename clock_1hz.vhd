library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity clock_1hz is
   port (
           clk : in std_logic;
           reset : in std_logic;
           
           insmem_clk : out std_logic_vector(2 downto 0);
           ram_clk : out std_logic_vector(2 downto 0);
           cpu_clk : out std_logic
        );
end;

architecture synth of clock_1hz is

   signal count : integer := 0;
   signal clk_cnt : std_logic_vector(6 downto 0) := "0000001";

begin
   process (clk, reset) begin
      if (reset = '1') then
		  count <= 0;
		  clk_cnt <= "0000001";
      elsif rising_edge(clk) then 
         if (count = 8) then
            clk_cnt <= clk_cnt(5 downto 0) & clk_cnt(6); -- rotate the clk bits
            count <= 0;
         else
            count <= count + 1;
            
         end if;
      end if;
   end process;
   insmem_clk <= clk_cnt(2 downto 0);
   ram_clk <= clk_cnt(5 downto 3);
   cpu_clk <= clk_cnt(6);
end;
