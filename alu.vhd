
--------------------------------------------------
-- alu.vhd
-- sarah_harris@hmc.edu 23 october 2005
-- 32-bit alu used by mips single-cycle processor
--------------------------------------------------

--------------------------------------------------
-- (Lots of) extensions by Hans-Kristian Arntzen
--------------------------------------------------

-- Not the most efficient ALU for sure. We do some awkward stuff here like jr/jalr logic. 
-- The MUL/DIV register logic also resides here.

library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity alu is
   port
   (
      clk : in std_logic; -- for mul/div reg
      a, b : in std_logic_vector(31 downto 0);
      f : in std_logic_vector(7 downto 0); -- ALU function. A bit hacky. bits 0-3 for general stuff, 4-6 for mul/div ops, 7 for unsigned op.
      shamt : in std_logic_vector(4 downto 0); -- Shifts
      alu_out : out std_logic_vector(31 downto 0); -- Final result
      zero : inout std_logic;  -- Branching
      ltez : out std_logic; -- Branching
      jr : out std_logic; -- jr
      link : out std_logic; -- jalr
      write_reg : out std_logic -- Can we write to register? Not always the case, due to jr or mul/div.
   );
end;

architecture synth of alu is
   signal s, bout : std_logic_vector(31 downto 0);
   signal mul_div_write_op : std_logic;
   signal jump_reg : std_logic;
   signal can_link : std_logic;

   signal we_hi, we_lo, read_hi_lo, read_mul_div_reg : std_logic;
   signal alu_res : std_logic_vector(63 downto 0); -- mult :3
   signal output_mul_div : std_logic_vector(31 downto 0);
   signal divider_quot, divider_rem : std_logic_vector(31 downto 0);
   signal mult_res : std_logic_vector(63 downto 0);
   signal slt : std_logic;

   component mul_div_reg is
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
   end component;

   component mux2 is
      generic(width: integer);
      port
      (
         d0, d1: in  std_logic_vector(width-1 downto 0);
         s:      in  std_logic;
         y:      out std_logic_vector(width-1 downto 0)
      );
   end component;
   
   component divider is
      port 
      (
         num : in std_logic_vector(31 downto 0);
         denom : in std_logic_vector(31 downto 0);
         quotient : out std_logic_vector(31 downto 0);
         remainder : out std_logic_vector(31 downto 0);
         use_unsigned : in std_logic
      );  
   end component;
   
   component mips_multiplier is
      port 
      (
         a : in std_logic_vector(31 downto 0);
         b : in std_logic_vector(31 downto 0);
         output : out std_logic_vector(63 downto 0);
         is_unsigned : in std_logic
      );
   end component;
begin

   -- HI/LO register for use with mul/div instructions, and the "never used" - mtlo, mthi.
   muldivreg_1 : mul_div_reg 
   port map (clk, we_hi, we_lo, 
      alu_res(63 downto 32), alu_res(31 downto 0),
      read_hi_lo, output_mul_div
   );

   mux2_1 : mux2 generic map(32) 
   port map (alu_res(31 downto 0), output_mul_div, 
      read_mul_div_reg, alu_out 
   );
   
   -- Single cycle divider megafunction. This and MUL is our critical path (it's insane ...).
   divider_1 : divider
   port map (a, b, divider_quot, divider_rem, f(7));
   
   -- Single cycle multiplier megafunction. Does signed and unsigned.
   multiplier_1 : mips_multiplier port map(a, b, mult_res, f(7));

   bout <= (not b) when (f(3) = '1') else b;
   s <= a + bout + f(3);


   process (f, a, b, bout, s) begin
      case f(6 downto 0) is

         -- Basic ALU stuff.
         when "0000000" => alu_res <= x"00000000" & (a and bout);
         when "0000001" => alu_res <= x"00000000" & (a or b);
         when "0001001" => alu_res <= x"00000000" & (a xor b);
         when "0001111" => alu_res <= x"00000000" & (a nor b);
         when "0001010" => alu_res <= x"00000000" & s;
         when "0000010" => alu_res <= x"00000000" & s;
         when "0001011" => alu_res <= conv_std_logic_vector(0, 63) & slt; -- slt/sltu

          -- Shifting
         when "0000100" => alu_res <= x"00000000" & to_stdlogicvector(to_bitvector(b) sll conv_integer(shamt)); -- sll
         when "0000101" => alu_res <= x"00000000" & to_stdlogicvector(to_bitvector(b) srl conv_integer(shamt)); -- srl
         when "0000110" => alu_res <= x"00000000" & to_stdlogicvector(to_bitvector(b) sra conv_integer(shamt)); -- sra
         when "0001100" => alu_res <= x"00000000" & to_stdlogicvector(to_bitvector(b) sll conv_integer(a(4 downto 0))); -- sllv
         when "0001101" => alu_res <= x"00000000" & to_stdlogicvector(to_bitvector(b) srl conv_integer(a(4 downto 0))); -- srlv
         when "0001110" => alu_res <= x"00000000" & to_stdlogicvector(to_bitvector(b) sra conv_integer(a(4 downto 0))); -- srav

         when "1100000" => alu_res <= mult_res; -- Multiplier
         when "1110000" => alu_res <= divider_rem & divider_quot; -- Divider

         when "1000000" => alu_res <= a & x"00000000"; -- mthi
         when "1010000" => alu_res <= x"00000000" & a; -- mtlo

         when others => alu_res(63 downto 0) <= conv_std_logic_vector(0, 64);

      end case;
   end process;

   zero <= '1' when (alu_res(31 downto 0) = x"00000000") else '0'; -- beq/bne
   jump_reg <= '1' when (f(3 downto 0) = "1000") else '0';
   jr <= jump_reg;
   can_link <= '0' when (a = x"00000000") else '1';
   link <= jump_reg and can_link;

   -- Not very pretty logic ... ;) But works.
   mul_div_write_op <= f(6);
   we_hi <= f(6) and (not (f(5) xor f(4)));
   we_lo <= f(6) and (f(5) or f(4));
   read_mul_div_reg <= f(5) or f(4);
   read_hi_lo <= f(4);

   write_reg <= (jump_reg and not can_link) nor mul_div_write_op;
   ltez <= zero or s(31);  -- blez/bgtz

    -- Calculate SLT, if unsigned we have to do some additional checks.
   process (s(31), f(7), a(31), b(31))
   begin

      if f(7) = '0' then
         slt <= s(31);
      else
         slt <= ((not (a(31) xor b(31))) and s(31)) or (a(31) and (not b(31)));
      end if;

   end process;
end;

