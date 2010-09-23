--------------------------------------------------
-- alu.vhd
-- Sarah_Harris@hmc.edu 23 October 2005
-- 32-bit ALU used by MIPS single-cycle processor
--------------------------------------------------

library IEEE; 
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity alu is
  port(clk : in std_logic; -- For MUL/DIV reg
		 A, B:  in     STD_LOGIC_VECTOR(31 downto 0);
       F:     in     STD_LOGIC_VECTOR(6 downto 0); --SLL - 6 to 4 MUL/DIV
		 shamt: in     STD_LOGIC_VECTOR(4 downto 0); --SLL
       alu_out:     out  STD_LOGIC_VECTOR(31 downto 0);
       Zero:  inout  STD_LOGIC;  --BLEZ
		 ltez:  out    STD_LOGIC; --BLEZ
		 jr: out STD_LOGIC; --JR
		 write_reg: out STD_LOGIC); --MUL/DIV nor JR 
end;

architecture synth of alu is
  signal S, Bout:      STD_LOGIC_VECTOR(31 downto 0);
  signal mul_div_write_op : std_logic;
  signal jump_reg : std_logic;
  
  signal we_hi, we_lo, read_hi_lo, read_mul_div_reg : std_logic;
  signal alu_res : std_logic_vector(63 downto 0); -- MULT :3
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
		port(d0, d1: in  STD_LOGIC_VECTOR(width-1 downto 0);
       s:      in  STD_LOGIC;
       y:      out STD_LOGIC_VECTOR(width-1 downto 0));
	end component;
begin

	
	
	MULDIVREG_1 : mul_div_reg port map (clk, we_hi, we_lo, 
			alu_res(63 downto 32), alu_res(31 downto 0),
			read_hi_lo, output_mul_div);
			
	MUX2_1 : mux2 generic map(32) port map (alu_res(31 downto 0), output_mul_div, 
		read_mul_div_reg, alu_out );
  

  Bout <= (not B) when (F(3) = '1') else B;
  S <= A + Bout + F(3);
  

  -- alu function
  process (F, A, Bout, S) begin
    case F is
      when "0000000" => 
		alu_res <= X"00000000" & (A and Bout);
      when "0000001" => 
		alu_res <= X"00000000" & (A or Bout);
	  when "0001001" =>
		alu_res <= X"00000000" & (A xor Bout);
	  when "0001111" =>
		alu_res <= X"00000000" & (A nor Bout);
      when "0001010" => 
		alu_res <= X"00000000" & S;
	  when "0000010" =>
		alu_res <= X"00000000" & S;
      when "0001011" => 
		alu_res <= 
        (X"00000000" & "0000000000000000000000000000000" & S(31));
      
      -- shifting
	  when "0000100" => 
		alu_res <= 
		   X"00000000" & to_stdlogicvector(to_bitvector(B) sll conv_integer(shamt)); --SLL
	when "0000101" => 
		alu_res <=
		   X"00000000" & to_stdlogicvector(to_bitvector(B) srl conv_integer(shamt)); --SRL
	when "0000110" => 
		alu_res <=
		   X"00000000" & to_stdlogicvector(to_bitvector(B) sra conv_integer(shamt)); --SRA
    when "0001100" => 
		alu_res <= 
		   X"00000000" & to_stdlogicvector(to_bitvector(B) sll conv_integer(A(4 downto 0))); --SLLV
	when "0001101" => 
		alu_res <=
		   X"00000000" & to_stdlogicvector(to_bitvector(B) srl conv_integer(A(4 downto 0))); --SRLV
	when "0001110" => 
		alu_res <=
		   X"00000000" & to_stdlogicvector(to_bitvector(B) sra conv_integer(A(4 downto 0))); --SRAV
		   
    -- end shifting
		when "1100000" => 
			alu_res <=
				A * B;
			
		when "1110000" => 
			--alu_res(31 downto 0) <= A / B;
			--alu_res(63 downto 32) <= A mod B; Doesn't synth, use some dummy stuff :D
			alu_res <= X"0101010101010101";
			
		when "1000000" =>
			alu_res <= A & X"00000000";
		when "1010000" =>
			alu_res <= X"00000000" & A;
			
      when others => 
		alu_res(63 downto 0) <= X"0000000000000000";
    end case;
  end process;

  Zero <= '1' when (alu_res(31 downto 0) = X"00000000") else '0';
  jump_reg <= '1' when (F(3 downto 0) = "1000") else '0';
  jr <= jump_reg;
  
  mul_div_write_op <= F(6);
  we_hi <= F(6) and (not (F(5) and F(4)));
  we_lo <= F(6) and (F(5) or F(4));
  read_mul_div_reg <= F(5) or F(4);
  read_hi_lo <= F(4);
  
  write_reg <= jump_reg nor mul_div_write_op;
  ltez <= Zero or S(31);  -- BLEZ
  
end;

