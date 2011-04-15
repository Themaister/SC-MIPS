library ieee; use ieee.std_logic_1164.all;
-- Our dreaded SRAM controller. It is quite complex since we write and read 32-bit values at a time.

entity sram_de2 is
   port 
   (
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
end;

architecture synth of sram_de2 is

   component tristate16 is
      port 
      (
         input : in std_logic_vector(15 downto 0);
         oe : in std_logic;
         output : out std_logic_vector(15 downto 0)
      );
   end component;

   signal a_0, a_1 : std_logic_vector(17 downto 0);
   signal ub_0, lb_0, ub_1, lb_1 : std_logic; -- sh/lb

   signal rd_0 : std_logic_vector(15 downto 0);
   signal rd_1 : std_logic_vector(15 downto 0);

   signal cat_clk : std_logic;

   -- Nifty state machines.
   type state_type is (s0, s1, s2, s3, s4, s5);
   signal ram_state : state_type := s0;

   signal ub_buf : std_logic := '0';
   signal lb_buf : std_logic := '0';
   signal we_buf : std_logic := '0';
   signal wd_buf : std_logic_vector(15 downto 0);
   signal rd_buf : std_logic_vector(15 downto 0);
   signal a_buf : std_logic_vector(17 downto 0);

begin

   -- Or all the separate clocks together to form a counting clock.
   cat_clk <= clk(0) or clk(1) or clk(2) or clk(3) or clk(4) or clk(5);

   -- Tristate the SRAM bus.
   tristate1 : tristate16 port map(wd_buf, we_buf, sram_dq);
   tristate2 : tristate16 port map(sram_dq, not we_buf, rd_buf);

   -- Write enable.
   sram_we_n <= not we_buf;
   -- Output enable (read enable).
   sram_oe_n <= we_buf;

   -- Write upper and lower byte.
   sram_ub_n <= not ub_buf;
   sram_lb_n <= not lb_buf;

   process (cat_clk, reset)
   begin
      if reset = '1' then
         ram_state <= s0;
      elsif rising_edge(cat_clk) then
         case ram_state is

            -- Set up data to write, byte masks, and adress. Turn write-enable off.
            when s0 =>
               ram_state <= s1;

               we_buf <= '0';
               sram_addr <= a_0;
               wd_buf <= wd(31 downto 16);
               ub_buf <= ub_0;
               lb_buf <= lb_0;

            -- Set write-enable if needed.
            when s1 =>
               ram_state <= s2;
               we_buf <= we;

            -- Turn off write, read first 16 bits.
            when s2 =>
               ram_state <= s3;
               rd_0 <= rd_buf;
               we_buf <= '0';

            -- Set new address, data and byte masks.
            when s3 =>
               ram_state <= s4;
               sram_addr <= a_1;
               wd_buf <= wd(15 downto 0);
               ub_buf <= ub_1;
               lb_buf <= lb_1;

            -- Enable write
            when s4 =>
               ram_state <= s5;
               we_buf <= we;

            -- Read result, turn off write.
            when s5 =>
               ram_state <= s0;
               rd_1 <= rd_buf;
               we_buf <= '0';

            -- Safety net.
            when others =>
               ram_state <= s0;

         end case;
      end if;
   end process;

   -- We read and write in two stages since the SRAM is 16-bit only :\
   a_0 <= a(18 downto 2) & '0';
   a_1 <= a(18 downto 2) & '1';
   ub_0 <= byteen(3);
   lb_0 <= byteen(2);
   ub_1 <= byteen(1);
   lb_1 <= byteen(0);

   sram_ce_n <= '0'; -- Enable the chip.
   rd <= rd_0 & rd_1; -- Concatenate for final output.
end;
