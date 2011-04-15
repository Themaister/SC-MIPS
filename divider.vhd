-- Ah... The single cycle 32-bit divider. It is batshit insane ;)
-- Thanks to Altera for making this possible at all! :D
library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_arith.all;
entity divider is
   port 
   (
      num : in std_logic_vector(31 downto 0);
      denom : in std_logic_vector(31 downto 0);
      quotient : out std_logic_vector(31 downto 0);
      remainder : out std_logic_vector(31 downto 0);
      use_unsigned : in std_logic
   );  
end;

architecture synth of divider is
   COMPONENT mipsdiv IS
      PORT
      (
         denom		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         numer		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         quotient		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
         remain		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
      );
   END COMPONENT;

   component iabs is
      generic ( N : integer );
      port 
      ( 
         a : in std_logic_vector(N-1 downto 0);
         aout : out std_logic_vector(N-1 downto 0);
         p : in std_logic
      );
   end component;

   component mux2 is -- two-input multiplexer
      generic(width: integer);
      port
      (
         d0, d1 : in  std_logic_vector(width-1 downto 0);
         s :      in  std_logic;
         y :      out std_logic_vector(width-1 downto 0)
      );
   end component;

   signal num_pos, denom_pos, quot_out, remain_out : std_logic_vector(31 downto 0);
   signal num_u, denom_u : std_logic_vector(31 downto 0);
   signal quot_out_real, remain_out_real : std_logic_vector(31 downto 0);

begin
   iabs_1 : iabs generic map(32) port map(num, num_pos, '1');
   iabs_2 : iabs generic map(32) port map(denom, denom_pos, '1');
   mux2_1 : mux2 generic map(32) port map(num_pos, num, use_unsigned, num_u);
   mux2_2 : mux2 generic map(32) port map(denom_pos, denom, use_unsigned, denom_u);

   mipsdiv_1 : mipsdiv port map(denom_u, num_u, quot_out, remain_out);

   iabs_3 : iabs generic map(32) 
   port map(quot_out, quot_out_real, (not (num(31) xor denom(31))) or use_unsigned); 
   iabs_4 : iabs generic map(32) 
   port map(remain_out, remain_out_real, (not (num(31))) or use_unsigned); 

   quotient <= quot_out_real;
   remainder <= remain_out_real;

end;
