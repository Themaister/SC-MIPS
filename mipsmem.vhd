--------------------------------------------------
-- Author: Hans-Kristian Arntzen
--------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; 
use ieee.std_logic_arith.all;

entity dmem is -- data memory
   port
   (
      clk : in std_logic_vector(5 downto 0); -- 6-stage clock for eventual SRAM.
      reset : in std_logic;
      we : in std_logic;
      wsize : in std_logic_vector(1 downto 0); -- sb, sh
      a, wd : in std_logic_vector(31 downto 0);
      rd : out std_logic_vector(31 downto 0);
      switch : in std_logic_vector(15 downto 0);
      led : out std_logic_vector(15 downto 0);
      ledg : out std_logic_vector(7 downto 0);
      hex : out std_logic_vector(31 downto 0);

      sram_addr : out std_logic_vector(17 downto 0);
      sram_dq : inout std_logic_vector(15 downto 0);
      sram_we_n : out std_logic;
      sram_oe_n : out std_logic;
      sram_ub_n : out std_logic;
      sram_lb_n : out std_logic;
      sram_ce_n : out std_logic
   );
end;

-- This stuff is memory mapped.
-- Writable MMIO is mapped to 0x005-----
-- Readable MMIO is mapped to 0x006-----
-- Generic RAM is mapped to 0x007-----
-- Globals ROM is mapped to 0x003-----

architecture behave of dmem is

   component sram_de2 is
      port (
              clk : in std_logic_vector(5 downto 0); -- 6-staged clock
              reset : in std_logic;
              a : in std_logic_vector(18 downto 0); -- 512kB RAM
              byteen : in std_logic_vector(3 downto 0); -- sb/sh
              wd : in std_logic_vector(31 downto 0); -- Write data
              we : in std_logic;

              rd : out std_logic_vector(31 downto 0);

              sram_addr : out std_logic_vector(17 downto 0);
              sram_dq : inout std_logic_vector(15 downto 0);
              sram_we_n : out std_logic;
              sram_oe_n : out std_logic;
              sram_ub_n : out std_logic;
              sram_lb_n : out std_logic;
              sram_ce_n : out std_logic
           );
   end component;

   COMPONENT grom IS
      PORT
      (
         address		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
         clock		: IN STD_LOGIC  := '1';
         q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
      );
   END COMPONENT;

   type ramtype is array (7 downto 0) of std_logic_vector(31 downto 0);
   signal mem_wr : ramtype;
   signal mem_rd : ramtype; 
   signal ram_dir : std_logic_vector(3 downto 0);
   signal rd_rd : std_logic_vector(31 downto 0); -- Our readable MMIO buffer.
   signal rd_wr : std_logic_vector(31 downto 0); -- Is our writable MMIO buffer.

   signal rd_ram : std_logic_vector(31 downto 0); -- Readable RAM buffer.
   signal byteena : std_logic_vector(3 downto 0); -- byte-enable buffer.
   signal wd_map : std_logic_vector(31 downto 0); -- Shifted wd_map depending on write mode.
   signal we_map : std_logic; -- Can we write to RAM?

   signal rd_grom : std_logic_vector(31 downto 0);
begin

   -- Process wsize and figure out what byteenable we need.
   process (a, we, wsize, ram_dir, wd_map, wd) begin
      if (we = '1') and (ram_dir = x"7") then
         if wsize = "01" then -- sb
            case a(1 downto 0) is
               when "00" => byteena <= "1000"; wd_map <= wd(7 downto 0) & x"000000";
               when "01" => byteena <= "0100"; wd_map <= x"00" & wd(7 downto 0) & x"0000";
               when "10" => byteena <= "0010"; wd_map <= x"0000" & wd(7 downto 0) & x"00";
               when "11" => byteena <= "0001"; wd_map <= wd;
               when others => byteena <= "0000";
            end case;
         elsif wsize = "10" then -- sh
            case a(1) is
               when '0' => byteena <= "1100"; wd_map <= wd(15 downto 0) & x"0000";
               when '1' => byteena <= "0011"; wd_map <= wd;
            end case;
         else
            byteena <= "1111";
            wd_map <= wd;
         end if;
         we_map <= '1';
      else
         byteena <= "1111";
         we_map <= '0';
         wd_map <= conv_std_logic_vector(0, 32);
      end if;
   end process;

   -- SRAM controller
   sram_de2_1 : sram_de2 
      port map(clk, reset, a(18 downto 0), byteena, wd_map, we_map, rd_ram, 
         sram_addr, sram_dq, sram_we_n, sram_oe_n, sram_ub_n, sram_lb_n, sram_ce_n);

   grom_1 : grom 
      port map(a(13 downto 2), clk(0) or clk(2), rd_grom); 
  -- A ROM that holds our global and static data. 
  -- This will have to be transferred to regular RAM. Had to do this since DE2 cannot handle
  -- reprogrammable RAM apparently :/
  -- An ASM routine will transfer from this ROM to RAM in the CRT startup. 

   ram_dir <= a(23 downto 20);

   -- Shuffle MMIO writes around since we write to words pretty much.
   process(a, clk(0), wd, wsize, ram_dir) begin
      if rising_edge(clk(0)) then
         if we = '1' then
            if (ram_dir = x"5") then
               if (wsize = "01") then -- sb
                  case a(1 downto 0) is
                     when "00" =>
                        mem_wr(conv_integer(a(4 downto 2)))(31 downto 24) <= wd(7 downto 0);
                     when "01" =>
                        mem_wr(conv_integer(a(4 downto 2)))(23 downto 16) <= wd(7 downto 0);
                     when "10" => 
                        mem_wr(conv_integer(a(4 downto 2)))(15 downto 8) <= wd(7 downto 0);
                     when others =>
                        mem_wr(conv_integer(a(4 downto 2)))(7 downto 0) <= wd(7 downto 0);
                  end case;
               elsif (wsize = "10") then -- sh
                  case a(1) is
                     when '0' =>
                        mem_wr(conv_integer(a(4 downto 2)))(31 downto 16) <= wd(15 downto 0);
                     when others =>
                        mem_wr(conv_integer(a(4 downto 2)))(15 downto 0) <= wd(15 downto 0);
                  end case;
               else
                  mem_wr(conv_integer(a(4 downto 2))) <= wd;
               end if; 
            end if; 
         end if;

         mem_rd(0) <= x"0000" & switch; -- Fills our readable MMIO buffer.

      end if;
   end process;

   -- Here we map our writable MMIO buffer to the HW.
   process (clk(2)) begin
      if rising_edge(clk(2)) then
         led <= mem_wr(0)(15 downto 0);
         ledg <= mem_wr(1)(7 downto 0);
         hex <= mem_wr(2);
      end if;
   end process;

   -- Map readable buffer to rd.
   process(a(4 downto 2), mem_rd) begin
      rd_rd <= mem_rd(conv_integer(a(4 downto 2)));
   end process;

   process (ram_dir, rd_ram, rd_rd, rd_grom) begin
      case ram_dir is
         when x"7" => rd <= rd_ram; -- RAM read
         when x"6" => rd <= rd_rd; -- Readable MMIO.
         when x"3" => rd <= rd_grom; -- Globals ROM. Not accessed by regular C/asm code.
         when others => rd <= x"00000000";
      end case;
   end process;

end;

