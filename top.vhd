--------------------------------------------------
-- top.vhd
-- sarah_harris@hmc.edu 27 may 2007
-- top-level module for mips single-cycle
-- processor
--------------------------------------------------

--------------------------------------------------
-- Extensions by Hans-Kristian Arntzen
-- Mostly memory subsystem is completely reworked.
--------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; use ieee.std_logic_unsigned.all;

-- Top level design that couples CPU, external hardware and memory.
entity top is
   port
   (
      KEY : in std_logic_vector(1 downto 0);
      CLOCK_50 : in std_logic;

      -- MMIO
      HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7 : out std_logic_vector(6 downto 0);
      LEDR : out std_logic_vector(17 downto 0);
      SW : in std_logic_vector(15 downto 0);
      LEDG : out std_logic_vector(8 downto 0);
      LCD_ON : out std_logic;

      -- SRAM
      SRAM_ADDR : out std_logic_vector(17 downto 0);
      SRAM_DQ : inout std_logic_vector(15 downto 0);
      SRAM_WE_N : out std_logic;
      SRAM_OE_N : out std_logic;
      SRAM_UB_N : out std_logic;
      SRAM_LB_N : out std_logic;
      SRAM_CE_N : out std_logic
   );
end;

architecture synth of top is

   component mipssingle 
      port
      (
         clk, reset : in  std_logic;
         pc : out std_logic_vector(31 downto 0);
         instr : in  std_logic_vector(31 downto 0);
         memwrite : out std_logic;
         memwrite_size : out std_logic_vector(1 downto 0);
         aluresult, writedata : out std_logic_vector(31 downto 0);
         readdata : in  std_logic_vector(31 downto 0)
      );
   end component;
   
   -- DMEM module. Here we handle SRAM, MMIO and reading from global memory.
   component dmem is
	   port
      (
         clk : in std_logic_vector(5 downto 0); -- 6-stage clock for eventual SRAM.
         reset : in std_logic; -- Reset SRAM controller state machine.

         we :  in std_logic;
         wsize : in std_logic_vector(1 downto 0); -- sb, sh
         a, wd : in std_logic_vector(31 downto 0);
         rd : out std_logic_vector(31 downto 0);

         -- MMIO
         switch : in std_logic_vector(15 downto 0);
         led : out std_logic_vector(15 downto 0);
         ledg : out std_logic_vector(7 downto 0);
         hex : out std_logic_vector(31 downto 0);
         
         -- SRAM
         sram_addr : out std_logic_vector(17 downto 0);
         sram_dq : inout std_logic_vector(15 downto 0);
         sram_we_n : out std_logic;
         sram_oe_n : out std_logic;
         sram_ub_n : out std_logic;
         sram_lb_n : out std_logic;
         sram_ce_n : out std_logic
      );
	end component;
 
   -- Altera MF. In-memory controller editable.
	COMPONENT insmem_rom IS
		PORT
		(
			address		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
		);
	END COMPONENT;
   
   component clock_1hz is
      port 
      (
         clk : in std_logic;
         reset : in std_logic;

         insmem_clk : out std_logic_vector(2 downto 0);
         ram_clk : out std_logic_vector(5 downto 0);
         cpu_clk : out std_logic
      );
   end component;

   component ssd_32bit is
      port
      (
         ssd_in_32bit   : in std_logic_vector (31 downto 0);
         ssd0, ssd1, ssd2, ssd3, ssd4, ssd5, ssd6, ssd7  : out std_logic_vector (6 downto 0)
      ); 
   end component;

   signal pc, instr : std_logic_vector(31 downto 0);
   signal cpu_clk : std_logic;
   signal ram_clk : std_logic_vector(5 downto 0);
   signal insmem_clk : std_logic_vector(2 downto 0);
   signal memwrite_size : std_logic_vector(1 downto 0);

   signal hex_buf : std_logic_vector(31 downto 0);
   signal reset : std_logic;

   -- MIPS I/O.
   signal readdata : std_logic_vector(31 downto 0);
   signal writedata, dataadr : std_logic_vector(31 downto 0);
   signal memwrite : std_logic;

begin

  -- Instansiate CPU, clock and memory subsystems.
   
   mips1: mipssingle 
   port map(cpu_clk, reset, pc, instr, memwrite, memwrite_size, dataadr, 
      writedata, readdata);
   
   -- Data memory, MMIO, etc.
   dmem1: dmem 
   port map(ram_clk, reset, memwrite, memwrite_size, dataadr, writedata, readdata, 
	   SW(15 downto 0),
	   LEDR(15 downto 0), LEDG(7 downto 0), hex_buf,
	   SRAM_ADDR, SRAM_DQ, SRAM_WE_N, SRAM_OE_N, SRAM_UB_N, SRAM_LB_N, SRAM_CE_N);
   
   
   -- Remedy weird stuff that seems to happen if I don't do this ...
   LEDR(17 downto 16) <= "00";
   LCD_ON <= '0';
   LEDG(8) <= '0';
   ---------

   reset <= not KEY(1);
   
   -- Instruction memory.
   insmem1: insmem_rom port map (pc(13 downto 2), insmem_clk(0) or insmem_clk(2), instr); 

   -- HEX display MMIO.
   ssd_32bit1: ssd_32bit port map(hex_buf, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);

   -- Our modest clock generator. (It's more like 2MHz for the CPU ...)
   clock_1hz1: clock_1hz port map(CLOCK_50, reset, insmem_clk, ram_clk, cpu_clk);

end;

