library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;

entity clock_1hz is
   port (
           clk : in std_logic;
           reset : in std_logic;
           
           insmem_clk : out std_logic_vector(2 downto 0);
           ram_clk : out std_logic_vector(5 downto 0);
           cpu_clk : out std_logic
        );
end;

architecture synth of clock_1hz is

   signal count : integer := 0;
   signal clk_cnt : std_logic_vector(19 downto 0) := x"00000";

begin
   process (clk, reset) begin
      if (reset = '1') then
		  count <= 0;
		  clk_cnt <= x"80000";
      elsif rising_edge(clk) then 
         case count is
            -- instruction mem clk
			when 1 => clk_cnt <= x"00001";
			when 2 => clk_cnt <= x"00002";
			when 3 => clk_cnt <= x"00004";
			when 4 => clk_cnt <= x"00008";
			when 5 => clk_cnt <= x"00010";
			when 6 => clk_cnt <= x"00020";
			
			-- SRAM clock - Stall a bit so the CPU has time to figure out what to load from RAM.
			
			when 10 => clk_cnt <= x"00040";
			when 11 => clk_cnt <= x"00080";
			when 12 => clk_cnt <= x"00100";
			when 13 => clk_cnt <= x"00200";
			when 14 => clk_cnt <= x"00400";
			when 15 => clk_cnt <= x"00800";
			when 16 => clk_cnt <= x"01000";
			when 17 => clk_cnt <= x"02000";
			when 18 => clk_cnt <= x"04000";
			when 19 => clk_cnt <= x"08000";
			when 20 => clk_cnt <= x"10000";
			when 21 => clk_cnt <= x"20000";
			
			-- CPU clock - Stall a bit more...
			when 31 => clk_cnt <= x"40000";
			when 32 => clk_cnt <= x"80000";
			
            when others => clk_cnt <= x"00000";
         end case;
         
         if count = 33 then -- Freq ~ 1.5MHz
			count <= 0;
		 else
			count <= count + 1;
		 end if;
      end if;
   end process;
   insmem_clk <= clk_cnt(4) & clk_cnt(2) & clk_cnt(0);
   ram_clk <= clk_cnt(16) & clk_cnt(14) & clk_cnt(12) & clk_cnt(10) & clk_cnt(8) & clk_cnt(6);
   cpu_clk <= clk_cnt(18);
end;
