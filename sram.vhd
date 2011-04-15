library ieee;
use ieee.std_logic_1164.all;

entity sram_de2 is
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
end;

architecture synth of sram_de2 is
	
	component tristate16 is
		port (
			input : in std_logic_vector(15 downto 0);
			oe : in std_logic;
			output : out std_logic_vector(15 downto 0));
	end component;
	
	signal a_0, a_1 : std_logic_vector(17 downto 0);
	signal ub_0, lb_0, ub_1, lb_1 : std_logic; -- sh/lb
	
	signal rd_0 : std_logic_vector(15 downto 0);
	signal rd_1 : std_logic_vector(15 downto 0);
	
	signal cat_clk : std_logic;
	
	type state_type is (s0, s1, s2, s3, s4, s5);
	signal ram_state : state_type := s0;
	
	signal ub_buf : std_logic := '0';
	signal lb_buf : std_logic := '0';
	signal we_buf : std_logic := '0';
	signal wd_buf : std_logic_vector(15 downto 0);
	signal rd_buf : std_logic_vector(15 downto 0);
	signal a_buf : std_logic_vector(17 downto 0);
	
begin

	cat_clk <= clk(0) or clk(1) or clk(2) or clk(3) or clk(4) or clk(5);
	tristate1 : tristate16 port map(wd_buf, we_buf, sram_dq);
	tristate2 : tristate16 port map(sram_dq, not we_buf, rd_buf);
	sram_we_n <= not we_buf;
	sram_oe_n <= we_buf;
	sram_ub_n <= not ub_buf;
	sram_lb_n <= not lb_buf;
	
	process (cat_clk, reset)
    begin
		if reset = '1' then
			ram_state <= s0;
		elsif rising_edge(cat_clk) then
			case ram_state is
				when s0 =>
					ram_state <= s1;
					
					we_buf <= '0';
					sram_addr <= a_0;
					wd_buf <= wd(31 downto 16);
					ub_buf <= ub_0;
					lb_buf <= lb_0;
					
				when s1 =>
					ram_state <= s2;
					we_buf <= we;
					
				when s2 =>
					ram_state <= s3;
					rd_0 <= rd_buf;
					we_buf <= '0';
					
				when s3 =>
					ram_state <= s4;
					sram_addr <= a_1;
					wd_buf <= wd(15 downto 0);
					ub_buf <= ub_1;
					lb_buf <= lb_1;
				
				when s4 =>
					ram_state <= s5;
					we_buf <= we;
				
				when s5 =>
					ram_state <= s0;
					rd_1 <= rd_buf;
					we_buf <= '0';
				
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
    rd <= rd_0 & rd_1;
end;