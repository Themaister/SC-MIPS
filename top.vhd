--------------------------------------------------
-- top.vhd
-- sarah_harris@hmc.edu 27 may 2007
-- top-level module for mips single-cycle
-- processor
--------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; use ieee.std_logic_unsigned.all;

entity top is -- top-level design for testing
   port(KEY:           in    std_logic_vector(1 downto 0);
        CLOCK_50:      in    std_logic;
        readdata:             inout std_logic_vector(31 downto 0);
   writedata, dataadr:   inout std_logic_vector(31 downto 0);
   memwrite:             inout std_logic;
   hex0, hex1, hex2, hex3, hex4, hex5, hex6, hex7 : out std_logic_vector(6 downto 0);
   LEDR : out std_logic_vector(17 downto 0);
   sw: in std_logic_vector(15 downto 0);
   LEDG : out std_logic_vector(8 downto 0);
   LCD_ON : out std_logic
);
end;

architecture synth of top is
   component mipssingle 
      port(clk, reset:        in  std_logic;
           pc:                inout std_logic_vector(31 downto 0);
           instr:             in  std_logic_vector(31 downto 0);
           memwrite:          out std_logic;
           memwrite_size:     out std_logic_vector(1 downto 0);
      aluresult, writedata: inout std_logic_vector(31 downto 0);
      readdata:          in  std_logic_vector(31 downto 0));
   end component;

   component dmem
      port(clk, we:  in  std_logic;
      wsize: in std_logic_vector(1 downto 0); -- sb, sh
      a, wd:    in  std_logic_vector(31 downto 0);
      rd:       out std_logic_vector(31 downto 0);
      switch : in std_logic_vector(15 downto 0);
      led : out std_logic_vector(15 downto 0);
      ledg : out std_logic_vector(7 downto 0);
      hex : out std_logic_vector(31 downto 0));
   end component;

   component insmem is
      port (
              a : in std_logic_vector(31 downto 0);
              rd : out std_logic_vector(31 downto 0)
           );
   end component;
   
    COMPONENT insmem_rom IS
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
	END COMPONENT;
   
   component clock_1hz is
      port (
              clk : in std_logic;
              clk_out : out std_logic;
              clk_out_ram : out std_logic
           );
   end component;

   
   component ssd_32bit is
   port(ssd_in_32bit   : in std_logic_vector (31 downto 0);
   ssd0, ssd1, ssd2, ssd3, ssd4, ssd5, ssd6, ssd7  : out std_logic_vector (6 downto 0)); 
   end component;

   signal pc, instr:    std_logic_vector(31 downto 0);
   signal internal_clk: std_logic;
   signal internal_clk_rom: std_logic;
   signal memwrite_size : std_logic_vector(1 downto 0);
   
   signal hex_buf : std_logic_vector(31 downto 0);

begin
  -- instantiate processor and memories
   
   mips1: mipssingle port map(internal_clk, not KEY(1), pc, instr, memwrite, memwrite_size, dataadr, 
   writedata, readdata);
   
   dmem1: dmem port map(internal_clk, memwrite, memwrite_size, dataadr, writedata, readdata, 
   SW(15 downto 0),
   LEDR(15 downto 0), LEDG(7 downto 0), hex_buf);
   
   
   -- Remedy weird shit.
   LEDR(17 downto 16) <= "00";
   LCD_ON <= '0';
   LEDG(8) <= '0';
   

   --insmem1: insmem port map (pc, instr);
   insmem1: insmem_rom port map (pc(11 downto 2), internal_clk_rom, instr); 

ssd_32bit1: ssd_32bit port map(hex_buf, hex0, hex1, hex2, hex3, hex4, hex5, hex6, hex7);
clock_1hz1: clock_1hz port map(CLOCK_50, internal_clk, internal_clk_rom);

   

--ledg <= pc(7 downto 0);

end;

