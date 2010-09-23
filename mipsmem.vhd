--------------------------------------------------
-- mipsmem.vhd
-- Sarah_Harris@hmc.edu 27 May 2007
-- External memories used by MIPS single-cycle
-- processor
--------------------------------------------------

library IEEE; use IEEE.STD_LOGIC_1164.all;
use STD.TEXTIO.all;
use IEEE.STD_LOGIC_UNSIGNED.all; use IEEE.STD_LOGIC_ARITH.all;

entity dmem is -- data memory
  port(clk, we:  in STD_LOGIC;
       a, wd:    in STD_LOGIC_VECTOR(31 downto 0);
       rd:       out STD_LOGIC_VECTOR(31 downto 0);
       switch1, switch2, switch3, switch4: in std_logic_vector(3 downto 0);
       led1: out std_logic_vector(7 downto 0));
end;

architecture behave of dmem is
  type ramtype is array (63 downto 0) of STD_LOGIC_VECTOR(31 downto 0);
  signal mem: ramtype; 
  --signal tmp1, tmp2, tmp3, tmp4: std_logic_vector(31 downto 0);
begin
  process(clk) begin
    if clk'event and clk = '1' then
      if we = '1' then
			if (a(7 downto 2) > 3) then
				mem(CONV_INTEGER(a(7 downto 2))) <= wd;
			else
				mem(0) <= X"0000000" & switch1;
				mem(1) <= X"0000000" & switch2;
				mem(2) <= X"0000000" & switch3;
				mem(3) <= X"0000000" & switch4; 
			end if;
	  else
        mem(0) <= X"0000000" & switch1;
		mem(1) <= X"0000000" & switch2;
		mem(2) <= X"0000000" & switch3;
		mem(3) <= X"0000000" & switch4; 
      end if;
   end if;
  end process;
  
  --memory mapping? :D
  led1 <= mem(4)(7 downto 0);
  
  rd <= mem(CONV_INTEGER(a(7 downto 2)));
end;

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all; use IEEE.STD_LOGIC_ARITH.all;
entity insmem is -- instruction memory
	port (
		a : in std_logic_vector(31 downto 0);
		rd : out std_logic_vector(31 downto 0)
	);
end;

architecture behave of insmem is
	signal addr: std_logic_vector(7 downto 0);
begin
	
		-- All choice expressions in a VHDL case statement must be constant
-- and unique.	Also, the case statement must be complete, or it must
-- include an others clause. 
	addr <= a(7 downto 0);
	process(addr) begin
	case addr is
		when X"98" =>
			rd <= X"8C040000";
		when X"9c" =>
			rd <= X"8C050004";
		when X"a0" =>
			rd <= X"0C100030";
		
		when X"a8" =>
			rd <= X"AC020010";
		
		when X"ac" =>
			rd <= X"08100024";
		
		when X"c0" =>
			rd <= X"00851024";
		when X"c4" =>
			rd <= X"34420010";
			
		when X"c8" =>
			rd <= X"03e00008";
			
		when others =>
			rd <= X"00000000";

	end case;
	end process; 

	
end;




