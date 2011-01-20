
--------------------------------------------------
-- alu.vhd
-- sarah_harris@hmc.edu 23 october 2005
-- 32-bit alu used by mips single-cycle processor
--------------------------------------------------

--------------------------------------------------
-- Extensions by Hans-Kristian Arntzen
--------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity alu is
   port(clk:        in       std_logic; -- for mul/div reg
   a, b:       in       std_logic_vector(31 downto 0);
   f:          in       std_logic_vector(6 downto 0); --sll - 6 to 4 mul/div
   shamt:      in       std_logic_vector(4 downto 0); --sll
   alu_out:    out      std_logic_vector(31 downto 0);
   zero:       inout    std_logic;  --blez
   ltez:       out      std_logic; --blez
   jr:         out      std_logic; --jr
   write_reg:  out      std_logic
); --mul/div nor jr 
end;

architecture synth of alu is
   signal s, bout:      std_logic_vector(31 downto 0);
   signal mul_div_write_op : std_logic;
   signal jump_reg : std_logic;

   signal we_hi, we_lo, read_hi_lo, read_mul_div_reg : std_logic;
   signal alu_res : std_logic_vector(63 downto 0); -- mult :3
   signal output_mul_div : std_logic_vector(31 downto 0);

   component mul_div_reg is
      port (
              clk : in std_logic;
              we_hi : in std_logic;
              we_lo : in std_logic;
              hi : in std_logic_vector(31 downto 0);
              lo : in std_logic_vector(31 downto 0);

              read_hi_lo : in std_logic;

              output : out std_logic_vector(31 downto 0)
           );
   end component;

   component mux2 is -- two-input multiplexer
      generic(width: integer);
      port(d0, d1: in  std_logic_vector(width-1 downto 0);
           s:      in  std_logic;
           y:      out std_logic_vector(width-1 downto 0));
   end component;
begin

   muldivreg_1 : mul_div_reg 
   port map (clk, we_hi, we_lo, 
      alu_res(63 downto 32), alu_res(31 downto 0),
      read_hi_lo, output_mul_div
   );

   mux2_1 : mux2 generic map(32) 
   port map (alu_res(31 downto 0), output_mul_div, 
      read_mul_div_reg, alu_out 
   );


   bout <= (not b) when (f(3) = '1') else b;
   s <= a + bout + f(3);


  -- alu function
process (f, a, bout, s) begin
   case f is
      when "0000000" => 
         alu_res <= x"00000000" & (a and bout);
      when "0000001" => 
         alu_res <= x"00000000" & (a or bout);
      when "0001001" =>
         alu_res <= x"00000000" & (a xor (not bout));
      when "0001111" =>
         alu_res <= x"00000000" & (a nor (not bout));
      when "0001010" => 
         alu_res <= x"00000000" & s;
      when "0000010" =>
         alu_res <= x"00000000" & s;
      when "0001011" => 
         alu_res <= 
           (x"00000000" & "0000000000000000000000000000000" & s(31));

     -- shifting
       when "0000100" => 
            alu_res <= 
               x"00000000" & to_stdlogicvector(to_bitvector(b) sll conv_integer(shamt)); --sll
       when "0000101" => 
            alu_res <=
               x"00000000" & to_stdlogicvector(to_bitvector(b) srl conv_integer(shamt)); --srl
       when "0000110" => 
           alu_res <=
          x"00000000" & to_stdlogicvector(to_bitvector(b) sra conv_integer(shamt)); --sra
       when "0001100" => 
             alu_res <= 
                 x"00000000" & to_stdlogicvector(to_bitvector(b) sll conv_integer(a(4 downto 0))); --sllv
       when "0001101" => 
             alu_res <=
               x"00000000" & to_stdlogicvector(to_bitvector(b) srl conv_integer(a(4 downto 0))); --srlv
       when "0001110" => 
            alu_res <=
              x"00000000" & to_stdlogicvector(to_bitvector(b) sra conv_integer(a(4 downto 0))); --srav

         -- end shifting
       when "1100000" => 
           alu_res <=
             a * b;

       --when "1110000" => 
          --alu_res(31 downto 0) <= a / b;
          --alu_res(63 downto 32) <= a mod b; doesn't synth, use some dummy stuff :d
          --alu_res <=  (a mod b) & x"01010101";
          

       when "1000000" =>
          alu_res <= a & x"00000000";
       when "1010000" =>
          alu_res <= x"00000000" & a;

       when others => 
          alu_res(63 downto 0) <= x"0000000000000000";
   end case;
end process;

 zero <= '1' when (alu_res(31 downto 0) = x"00000000") else '0'; -- beq/bne
 jump_reg <= '1' when (f(3 downto 0) = "1000") else '0';
 jr <= jump_reg;

 mul_div_write_op <= f(6);
 we_hi <= f(6) and (f(5) nand f(4));
 we_lo <= f(6) and (f(5) or f(4));
 read_mul_div_reg <= f(5) or f(4);
 read_hi_lo <= f(4);

 write_reg <= jump_reg nor mul_div_write_op;
 ltez <= zero or s(31);  -- blez/bgtz

end;

