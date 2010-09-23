--------------------------------------------------
-- mipsmem.vhd
-- sarah_harris@hmc.edu 27 may 2007
-- external memories used by mips single-cycle
-- processor
--------------------------------------------------

library ieee; use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_unsigned.all; use ieee.std_logic_arith.all;

entity dmem is -- data memory
   port(clk, we:  in std_logic;
   a, wd:    in std_logic_vector(31 downto 0);
   rd:       out std_logic_vector(31 downto 0);
   switch1, switch2, switch3, switch4: in std_logic_vector(3 downto 0);
   led1: out std_logic_vector(7 downto 0));
end;

architecture behave of dmem is
   type ramtype is array (63 downto 0) of std_logic_vector(31 downto 0);
   signal mem: ramtype; 
begin
  process(clk) begin
     if clk'event and clk = '1' then
        if we = '1' then
           if (a(7 downto 2) > 3) then
              mem(conv_integer(a(7 downto 2))) <= wd;
           else
              mem(0) <= x"0000000" & switch1;
              mem(1) <= x"0000000" & switch2;
              mem(2) <= x"0000000" & switch3;
              mem(3) <= x"0000000" & switch4; 
           end if;
        else
           mem(0) <= x"0000000" & switch1;
           mem(1) <= x"0000000" & switch2;
           mem(2) <= x"0000000" & switch3;
           mem(3) <= x"0000000" & switch4; 
        end if;
     end if;
  end process;

  --memory mapping? :d
  led1 <= mem(4)(7 downto 0);

  rd <= mem(conv_integer(a(7 downto 2)));
end;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; use ieee.std_logic_arith.all;
entity insmem is -- instruction memory
   port (
           a : in std_logic_vector(31 downto 0);
           rd : out std_logic_vector(31 downto 0)
        );
end;

architecture behave of insmem is
   signal addr: std_logic_vector(7 downto 0);
begin

   addr <= a(7 downto 0);
process(addr) begin
   case addr is
      when x"98" =>
         rd <= x"8c040000";
      when x"9c" =>
         rd <= x"8c050004";
      when x"a0" =>
         rd <= x"0c100030";

      when x"a8" =>
         rd <= x"ac020010";

      when x"ac" =>
         rd <= x"08100024";

      when x"c0" =>
         rd <= x"00851024";
      when x"c4" =>
      rd <= x"34420010";

   when x"c8" =>
      rd <= x"03e00008";

   when others =>
      rd <= x"00000000";

end case;
   end process; 


end;




