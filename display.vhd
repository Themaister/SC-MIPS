--------------------------------------------------
-- seven segment decoder 32 bit
--
-- input: 32 bit signal
-- output: 32 bit signal displayed on hex7 to hex1
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
entity ssd_32bit is
   port
   (
      ssd_in_32bit : in std_logic_vector (31 downto 0);
      ssd0, ssd1, ssd2, ssd3, ssd4, ssd5, ssd6, ssd7 : out std_logic_vector (6 downto 0)
   ); 
end;

architecture synth of ssd_32bit is
   component ssd is
      port
      (
         ssd_in : in std_logic_vector (3 downto 0);
         ssd_out : out std_logic_vector (6 downto 0)
      ); 
   end component;
begin              
   ssd0disp : ssd port map( ssd_in_32bit(3 downto 0), ssd0);
   ssd1disp : ssd port map( ssd_in_32bit(7 downto 4), ssd1);
   ssd2disp : ssd port map( ssd_in_32bit(11 downto 8), ssd2);
   ssd3disp : ssd port map( ssd_in_32bit(15 downto 12), ssd3);
   ssd4disp : ssd port map( ssd_in_32bit(19 downto 16), ssd4);
   ssd5disp : ssd port map( ssd_in_32bit(23 downto 20), ssd5);
   ssd6disp : ssd port map( ssd_in_32bit(27 downto 24), ssd6);
   ssd7disp : ssd port map( ssd_in_32bit(31 downto 28), ssd7);
end;

--------------------------------------------------
-- seven segment decoder
--
-- input: 4 bit signal
-- output 7 bit signal
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
entity ssd is
   port
   (
      ssd_in : in std_logic_vector (3 downto 0);
      ssd_out : out std_logic_vector (6 downto 0)
   ); 
end;

architecture synth of ssd is
begin
   process (ssd_in)
   begin
      case ssd_in is
         when "0000" => ssd_out <= not "0111111"; -- 0
         when "0001" => ssd_out <= not "0000110"; -- 1
         when "0010" => ssd_out <= not "1011011"; -- 2
         when "0011" => ssd_out <= not "1001111"; -- 3
         when "0100" => ssd_out <= not "1100110"; -- 4
         when "0101" => ssd_out <= not "1101101"; -- 5
         when "0110" => ssd_out <= not "1111101"; -- 6
         when "0111" => ssd_out <= not "0000111"; -- 7
         when "1000" => ssd_out <= not "1111111"; -- 8
         when "1001" => ssd_out <= not "1101111"; -- 9
         when "1010" => ssd_out <= not "1110111"; -- a
         when "1011" => ssd_out <= not "1111100"; -- b
         when "1100" => ssd_out <= not "0111001"; -- c
         when "1101" => ssd_out <= not "1011110"; -- d
         when "1110" => ssd_out <= not "1111001"; -- e
         when "1111" => ssd_out <= not "1110001"; -- f
         when others => ssd_out <= not "1000000"; -- -              
      end case;
   end process;
end;


