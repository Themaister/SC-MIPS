--------------------------------------------------
-- mipsmem.vhd
-- sarah_harris@hmc.edu 27 may 2007
-- external memories used by mips single-cycle
-- processor
--------------------------------------------------

--------------------------------------------------
-- Extensions by Hans-Kristian Arntzen
--------------------------------------------------

library ieee; use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_unsigned.all; use ieee.std_logic_arith.all;

entity dmem is -- data memory
   port(clk, we:  in std_logic;
   wsize: in std_logic_vector(1 downto 0); -- sb, sh
   a, wd:    in std_logic_vector(31 downto 0);
   rd:       out std_logic_vector(31 downto 0);
   switch : in std_logic_vector(15 downto 0);
   led: out std_logic_vector(15 downto 0);
   ledg : out std_logic_vector(7 downto 0);
   hex : out std_logic_vector(31 downto 0));
end;

architecture behave of dmem is
   type ramtype is array (63 downto 0) of std_logic_vector(31 downto 0);
   signal mem_wr: ramtype;
   signal mem_rd : ramtype; 
   signal ram_dir : std_logic_vector(3 downto 0);
   signal rd_rd : std_logic_vector(31 downto 0);
   signal rd_wr : std_logic_vector(31 downto 0);
begin

  ram_dir <= a(23 downto 20);

  process(clk) begin
     if clk'event and clk = '1' then
        if we = '1' then
           if (ram_dir = x"5") then
              if (wsize = "01") then -- sb
			    case a(1 downto 0) is
				   when "00" =>
					mem_wr(conv_integer(a(7 downto 2)))(31 downto 24) <= wd(7 downto 0);
				   when "01" =>
					mem_wr(conv_integer(a(7 downto 2)))(23 downto 16) <= wd(7 downto 0);
				   when "10" => 
					mem_wr(conv_integer(a(7 downto 2)))(15 downto 8) <= wd(7 downto 0);
				   when others =>
				    mem_wr(conv_integer(a(7 downto 2)))(7 downto 0) <= wd(7 downto 0);
				end case;
			  elsif (wsize = "10") then -- sh
				case a(1) is
					when '0' =>
						mem_wr(conv_integer(a(7 downto 2)))(31 downto 16) <= wd(15 downto 0);
					when others =>
						mem_wr(conv_integer(a(7 downto 2)))(15 downto 0) <= wd(15 downto 0);
				end case;
              else
				mem_wr(conv_integer(a(7 downto 2))) <= wd;
			  end if; 
           end if; 
        end if;
        
        mem_rd(0) <= x"0000" & switch;
     end if;
     
     
  end process;

  --memory mapping? :d
  led <= mem_wr(0)(15 downto 0);
  ledg <= mem_wr(1)(7 downto 0);
  hex <= mem_wr(2);

  rd_wr <= mem_wr(conv_integer(a(7 downto 2)));
  rd_rd <= mem_rd(conv_integer(a(7 downto 2)));
  
  process (ram_dir, rd_wr, rd_rd) begin
	  case ram_dir is
			when x"5" =>
				rd <= rd_wr;
			when x"6" =>
				rd <= rd_rd;
			when others =>
				rd <= x"00000000";
	   end case;
   end process;
  
end;

