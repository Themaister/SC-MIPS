--------------------------------------------------
-- top.vhd
-- Sarah_Harris@hmc.edu 27 May 2007
-- Top-level module for MIPS single-cycle
-- processor
--------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all; use IEEE.STD_LOGIC_UNSIGNED.all;

entity top is -- top-level design for testing
  port(KEY:           in    STD_LOGIC_VECTOR(1 downto 0);
       CLOCK_50:      in    std_logic;
       readdata:             inout STD_LOGIC_VECTOR(31 downto 0);
       writedata, dataadr:   inout STD_LOGIC_VECTOR(31 downto 0);
       memwrite:             inout STD_LOGIC;
       HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0);
       LEDR : out std_logic_vector(15 downto 0);
       SW: in std_logic_vector(15 downto 0);
       LEDG : out std_logic_vector(7 downto 0)
       );
end;

architecture synth of top is
  component mipssingle 
    port(clk, reset:        in  STD_LOGIC;
         pc:                inout STD_LOGIC_VECTOR(31 downto 0);
         instr:             in  STD_LOGIC_VECTOR(31 downto 0);
         memwrite:          out STD_LOGIC;
         aluresult, writedata: inout STD_LOGIC_VECTOR(31 downto 0);
         readdata:          in  STD_LOGIC_VECTOR(31 downto 0));
  end component;

  component dmem
    port(clk, we:  in  STD_LOGIC;
         a, wd:    in  STD_LOGIC_VECTOR(31 downto 0);
         rd:       out STD_LOGIC_VECTOR(31 downto 0);
         switch1, switch2, switch3, switch4 : in std_logic_vector(3 downto 0);
		led1 : out std_logic_vector(7 downto 0));
  end component;
  
   component insmem is
	port (
		a : in std_logic_vector(31 downto 0);
		rd : out std_logic_vector(31 downto 0)
	);
	end component;
	
	component clock_1hz is
	port (
		clk : in std_logic;
		clk_out : out std_logic
	);
	end component;
		
  
	component ssd_32bit IS
	  PORT(ssd_in_32bit   : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		   ssd0, ssd1, ssd2, ssd3, ssd4, ssd5, ssd6, ssd7  : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)); 
	END component;

  signal pc, instr:    STD_LOGIC_VECTOR(31 downto 0);
  signal internal_clk: std_logic;
  
begin
  -- instantiate processor and memories
  
  --internal_clk <= KEY(0);
  
  mips1: mipssingle port map(internal_clk, not KEY(1), pc, instr, memwrite, dataadr, 
                       writedata, readdata);
  dmem1: dmem port map(internal_clk, memwrite, dataadr, writedata, readdata, 
		SW(3 downto 0), SW(7 downto 4), SW(11 downto 8), SW(15 downto 12),
		LEDR(7 downto 0)
 );
 
  insmem1: insmem port map (pc, instr);
  ssd_32bit1: ssd_32bit port map(instr, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);
  clock_1hz1: clock_1hz port map(CLOCK_50, internal_clk);
  
  --LEDR(3 downto 0) <= pc(5 downto 2);
  --LEDG(3 downto 0) <= writedata(3 downto 0);
  LEDG <= pc(7 downto 0);
  
end;

