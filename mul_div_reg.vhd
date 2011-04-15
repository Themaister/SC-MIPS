---------------------------------
-- Hans-Kristian Arntzen - 2010
---------------------------------

-- HI/LO reg used with MUL/DIV, etc.

library ieee;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
entity mul_div_reg is
   port 
   (
      clk : in std_logic;
      we_hi : in std_logic;
      we_lo : in std_logic;
      hi : in std_logic_vector(31 downto 0);
      lo : in std_logic_vector(31 downto 0);

      read_hi_lo : in std_logic;

      output : out std_logic_vector(31 downto 0)
   );
end;

architecture synth of mul_div_reg is

   signal internal_hi, internal_lo : std_logic_vector(31 downto 0);

begin
   process(clk) begin
      if rising_edge(clk) then
         if we_hi = '1' then
            internal_hi <= hi;
         end if;
         if we_lo = '1' then
            internal_lo <= lo;
         end if;
      end if;
   end process;

   output <= internal_hi when read_hi_lo = '1' else internal_lo;
end;

