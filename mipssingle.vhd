--------------------------------------------------
-- mipssingle.vhd
-- Sarah_Harris@hmc.edu 27 May 2007
-- Single-cycle MIPS processor - VHDL
--------------------------------------------------

library IEEE; use IEEE.STD_LOGIC_1164.all;

entity mipssingle is -- single cycle MIPS processor
  port(clk, reset:        in  STD_LOGIC;
       pc:                inout STD_LOGIC_VECTOR(31 downto 0);
       instr:             in  STD_LOGIC_VECTOR(31 downto 0);
       memwrite:          out STD_LOGIC;
       aluresult, writedata: inout STD_LOGIC_VECTOR(31 downto 0);
       readdata:          in  STD_LOGIC_VECTOR(31 downto 0));
end;

architecture struct of mipssingle is
  component controller
    port(op, funct:          in  STD_LOGIC_VECTOR(5 downto 0);
         zero:               in  STD_LOGIC;
         memtoreg, memwrite: out STD_LOGIC;
         pcsrc:              out STD_LOGIC;
			alusrc:             out STD_LOGIC_VECTOR(1 downto 0); --LUI
         regdst:             out STD_LOGIC_VECTOR(1 downto 0); --JAL
			regwrite:           out STD_LOGIC;
         jump:               out STD_LOGIC;
         alucontrol:         out STD_LOGIC_VECTOR(6 downto 0); --SLL
			ltez:               inout STD_LOGIC;                 --BLEZ
			jal:                out STD_LOGIC;                    --JAL
			lh:                 out STD_LOGIC);                   --LH
  end component;
  component datapath
    port(clk, reset:        in  STD_LOGIC;
         memtoreg, pcsrc:   in  STD_LOGIC;
         alusrc:            in  STD_LOGIC_VECTOR(1 downto 0); --LUI
		   regdst:            in  STD_LOGIC_VECTOR(1 downto 0); --JAL
         regwrite, jump:    in  STD_LOGIC;
         alucontrol:        in  STD_LOGIC_VECTOR(6 downto 0); --SLL
         zero:              inout STD_LOGIC;
         pc:                inout STD_LOGIC_VECTOR(31 downto 0);
         instr:             in  STD_LOGIC_VECTOR(31 downto 0);
         aluresult, writedata: inout STD_LOGIC_VECTOR(31 downto 0);
         readdata:          in  STD_LOGIC_VECTOR(31 downto 0);
	  	   ltez:              out STD_LOGIC;  --BLEZ
		   jal:               in  STD_LOGIC;  --JAL
		   lh:                in  STD_LOGIC); --LH  
  end component;
  signal memtoreg: STD_LOGIC;
  signal alusrc: STD_LOGIC_VECTOR(1 downto 0); --LUI
  signal regdst: STD_LOGIC_VECTOR(1 downto 0); --JAL
  signal regwrite, jump: STD_LOGIC;
  signal pcsrc, zero: STD_LOGIC;
  signal alucontrol: STD_LOGIC_VECTOR(6 downto 0); --SLL
  signal ltez: STD_LOGIC; --BLEZ
  signal jal: STD_LOGIC;  --JAL
  signal lh: STD_LOGIC;   --LH
begin
  cont: controller port map(instr(31 downto 26), instr(5 downto 0),
                            zero, memtoreg, memwrite, pcsrc, alusrc,
                            regdst, regwrite, jump, alucontrol,
									 ltez,  --BLEZ
									 jal,   --JAL
									 lh);   --LH
  dp: datapath port map(clk, reset, memtoreg, pcsrc, alusrc, regdst,
                        regwrite, jump, alucontrol, zero, pc, instr,
                        aluresult, writedata, readdata,
								ltez,   --BLEZ
								jal,    --JAL
								lh);    --LH
end;


library IEEE; use IEEE.STD_LOGIC_1164.all;
entity controller is -- single cycle control decoder
    port(op, funct:          in  STD_LOGIC_VECTOR(5 downto 0);
         zero:               in  STD_LOGIC;
         memtoreg, memwrite: out STD_LOGIC;
         pcsrc:              out STD_LOGIC;
			alusrc:             out STD_LOGIC_VECTOR(1 downto 0); --LUI
         regdst:             out STD_LOGIC_VECTOR(1 downto 0); --JAL
			regwrite:           out STD_LOGIC;
         jump:               out STD_LOGIC;
         alucontrol:         out STD_LOGIC_VECTOR(6 downto 0); --SLL
			ltez:               inout STD_LOGIC;                    --BLEZ
			jal:                out STD_LOGIC;                    --JAL
			lh:                 out STD_LOGIC);                   --LH
end;


architecture struct of controller is
  component maindec
  port(op:                 in  STD_LOGIC_VECTOR(5 downto 0);
       memtoreg, memwrite: out STD_LOGIC;
       branch:             out STD_LOGIC;
		 alusrc:             out STD_LOGIC_VECTOR(1 downto 0); --LUI
       regdst:             out STD_LOGIC_VECTOR(1 downto 0); --JAL
		 regwrite:           out STD_LOGIC;
       jump:               out STD_LOGIC;
       aluop:              out STD_LOGIC_VECTOR(2 downto 0);
		 blez:               out STD_LOGIC;  --BLEZ
		 jal:                out STD_LOGIC;  --JAL
		 lh:                 out STD_LOGIC); --LH
  end component;
  component aludec
    port(funct:      in  STD_LOGIC_VECTOR(5 downto 0);
         aluop:      in  STD_LOGIC_VECTOR(2 downto 0);
         alucontrol: out STD_LOGIC_VECTOR(6 downto 0));  --SLL
  end component;
  signal aluop: STD_LOGIC_VECTOR(2 downto 0);
  signal branch: STD_LOGIC;
  signal blez: STD_LOGIC;  --BLEZ
begin
  md: maindec port map(op, memtoreg, memwrite, branch,
                       alusrc, regdst, regwrite, jump, aluop,
							  blez, jal, lh);  --BLEZ, JAL, LH
  ad: aludec port map(funct, aluop, alucontrol);

  pcsrc <= (branch and zero) or (blez and ltez);  --BLEZ
end;

library IEEE; use IEEE.STD_LOGIC_1164.all;
entity maindec is -- main control decoder
  port(op:                 in  STD_LOGIC_VECTOR(5 downto 0);
       memtoreg, memwrite: out STD_LOGIC;
       branch:             out STD_LOGIC;
		 alusrc:             out STD_LOGIC_VECTOR(1 downto 0); --LUI
       regdst:             out STD_LOGIC_VECTOR(1 downto 0); --JAL
		 regwrite:           out STD_LOGIC;
       jump:               out STD_LOGIC;
       aluop:              out STD_LOGIC_VECTOR(2 downto 0);
		 blez:               out STD_LOGIC;  --BLEZ
		 jal:                out STD_LOGIC;  --JAL
		 lh:                 out STD_LOGIC); --LH
end;

architecture behave of maindec is
  -- increase number of control signals for LUI, BLEZ, JAL, LH
  signal controls: STD_LOGIC_VECTOR(14 downto 0);
begin
  process(op) begin
    case op is
      when "000000" => controls <= "101000000010000"; --Rtype
      when "100011" => controls <= "100010010000000"; --LW
      when "101011" => controls <= "000010100000000"; --SW
      when "000100" => controls <= "000001000001000"; --BEQ
      when "001000" => controls <= "100010000000000"; --ADDI
      when "001001" => controls <= "100010000000000"; --ADDIU
      when "000010" => controls <= "000000001000000"; --J
      when "001010" => controls <= "100010000011000"; --SLTI
      when "001111" => controls <= "100100000000000"; --LUI
      when "000110" => controls <= "000000000001100"; --BLEZ
      when "000011" => controls <= "110000001000010"; --JAL
      when "100001" => controls <= "100010010000001"; --LH
      when "001100" => controls <= "100010000100000"; --ANDI
      when "001101" => controls <= "100010000101000"; --ORI
      when others   => controls <= "---------------"; -- illegal op
    end case;
  end process;

  regwrite <= controls(14);
  regdst   <= controls(13 downto 12);
  alusrc   <= controls(11 downto 10);
  branch   <= controls(9);
  memwrite <= controls(8);
  memtoreg <= controls(7);
  jump     <= controls(6);
  aluop    <= controls(5 downto 3);
  blez     <= controls(2);
  jal      <= controls(1);
  lh       <= controls(0);
end;

library IEEE; use IEEE.STD_LOGIC_1164.all;
entity aludec is -- ALU control decoder
  port(funct:      in  STD_LOGIC_VECTOR(5 downto 0);
       aluop:      in  STD_LOGIC_VECTOR(2 downto 0);
       alucontrol: out STD_LOGIC_VECTOR(6 downto 0));  --SLL
end;

architecture behave of aludec is
begin
  process(aluop, funct) begin
    case aluop is
      when "000" => alucontrol <= "0000010"; -- add (for lb/sb/addi)
      when "001" => alucontrol <= "0001010"; -- sub (for beq)
      when "011" => alucontrol <= "0001011"; -- slt (for slti)
      when "100" => alucontrol <= "0000000"; -- andi
      when "101" => alucontrol <= "0000001"; -- ori
      when others => case funct is         -- R-type instructions
                         when "100000" => alucontrol <= "0000010"; -- add
                         when "100001" => alucontrol <= "0000010"; -- addu
                         when "100010" => alucontrol <= "0001010"; -- sub
                         when "100011" => alucontrol <= "0001010"; -- subu
                         when "100100" => alucontrol <= "0000000"; -- and
                         when "100101" => alucontrol <= "0000001"; -- or
                         when "100110" => alucontrol <= "0001001"; -- xor
                         when "100111" => alucontrol <= "0001111"; -- nor
                         when "101010" => alucontrol <= "0001011"; -- slt
                         -- shifting
                         when "000000" => alucontrol <= "0000100"; -- sll
                         when "000010" => alucontrol <= "0000101"; -- srl
                         when "000011" => alucontrol <= "0000110"; -- sra
                         when "000100" => alucontrol <= "0001100"; -- sllv
                         when "000110" => alucontrol <= "0001101"; -- srlv
                         when "000111" => alucontrol <= "0001110"; -- srav
                         -- end shifting
                         when "001000" => alucontrol <= "0001000"; -- jr
                         when "010000" => alucontrol <= "0010000"; -- mfhi
                         when "010001" => alucontrol <= "1000000"; -- mthi
                         when "010010" => alucontrol <= "0100000"; -- mflo
                         when "010011" => alucontrol <= "1010000"; -- mtlo
                         when "011000" => alucontrol <= "1100000"; -- mult
                         when "011001" => alucontrol <= "1100000"; -- multu, but we don't care
                         when "011010" => alucontrol <= "1110000"; -- div :D
                         when "011011" => alucontrol <= "1110000"; -- divu, but we don't care
                         
                         when others   => alucontrol <= "-------"; -- ???
                     end case;
    end case;
  end process;
end;

library IEEE; use IEEE.STD_LOGIC_1164.all; use IEEE.STD_LOGIC_ARITH.all;
entity datapath is  -- MIPS datapath
  port(clk, reset:        in  STD_LOGIC;
       memtoreg, pcsrc:   in  STD_LOGIC;
       alusrc:            in  STD_LOGIC_VECTOR(1 downto 0); --LUI
		 regdst:            in  STD_LOGIC_VECTOR(1 downto 0); --JAL
       regwrite, jump:    in  STD_LOGIC;
       alucontrol:        in  STD_LOGIC_VECTOR(6 downto 0); --SLL
       zero:              inout STD_LOGIC;
       pc:                inout STD_LOGIC_VECTOR(31 downto 0);
       instr:             in  STD_LOGIC_VECTOR(31 downto 0);
       aluresult, writedata: inout STD_LOGIC_VECTOR(31 downto 0);
       readdata:          in  STD_LOGIC_VECTOR(31 downto 0);
		 ltez:              out STD_LOGIC;  --BLEZ
		 jal:               in  STD_LOGIC;  --JAL
		 lh:                in  STD_LOGIC); --LH
end;

architecture struct of datapath is
  component alu
    port(clk: in std_logic;
		 A, B: in     STD_LOGIC_VECTOR(31 downto 0);
         F:    in     STD_LOGIC_VECTOR(6 downto 0); --SLL - 6-4 MUL/DIV stuff
		   shamt: in    STD_LOGIC_VECTOR(4 downto 0); --SLL
         alu_out:    inout STD_LOGIC_VECTOR(31 downto 0);
         Zero: inout  STD_LOGIC;  --BLEZ
		   ltez: out    STD_LOGIC; --BLEZ
		   jr: out STD_LOGIC; --JR
		   write_reg: out STD_LOGIC); --write MUL/DIV op or jr 
  end component;
  component regfile
    port(clk:           in  STD_LOGIC;
         we3:           in  STD_LOGIC;
         ra1, ra2, wa3: in  STD_LOGIC_VECTOR(4 downto 0);
         wd3:           in  STD_LOGIC_VECTOR(31 downto 0);
         rd1, rd2:      out STD_LOGIC_VECTOR(31 downto 0));
  end component;
  component adder
    port(a, b: in  STD_LOGIC_VECTOR(31 downto 0);
         y:    out STD_LOGIC_VECTOR(31 downto 0));
  end component;
  component sl2
    port(a: in  STD_LOGIC_VECTOR(31 downto 0);
         y: out STD_LOGIC_VECTOR(31 downto 0));
  end component;
  component signext
    port(a: in  STD_LOGIC_VECTOR(15 downto 0);
         y: out STD_LOGIC_VECTOR(31 downto 0));
  end component;
  component flopr generic(width: integer);
    port(clk, reset: in  STD_LOGIC;
         d:          in  STD_LOGIC_VECTOR(width-1 downto 0);
         q:          out STD_LOGIC_VECTOR(width-1 downto 0));
  end component;
  component mux2 generic(width: integer);
    port(d0, d1: in  STD_LOGIC_VECTOR(width-1 downto 0);
         s:      in  STD_LOGIC;
         y:      out STD_LOGIC_VECTOR(width-1 downto 0));
  end component;
  component upimm --LUI
  port(a: in  STD_LOGIC_VECTOR(15 downto 0);
       y: out STD_LOGIC_VECTOR(31 downto 0));
  end component;
  component mux3 generic(width: integer);  --LUI
  port(d0, d1, d2: in  STD_LOGIC_VECTOR(width-1 downto 0);
       s:          in  STD_LOGIC_VECTOR(1 downto 0);
       y:          out STD_LOGIC_VECTOR(width-1 downto 0));
  end component;
  signal writereg: STD_LOGIC_VECTOR(4 downto 0);
  signal pcjump, pcnext, pcnextbr, 
         pcplus4, pcbranch, pcrealbranch:  STD_LOGIC_VECTOR(31 downto 0);
  signal signimm, signimmsh: STD_LOGIC_VECTOR(31 downto 0);
  signal upperimm: STD_LOGIC_VECTOR(31 downto 0); --LUI
  signal srca, srcb, result: STD_LOGIC_VECTOR(31 downto 0);
  signal writeresult: STD_LOGIC_VECTOR(31 downto 0); --JAL
  signal half: STD_LOGIC_VECTOR(15 downto 0); --LH
  signal signhalf, memdata: STD_LOGIC_VECTOR(31 downto 0); --LH
  signal jr: STD_LOGIC; --JR
  signal alu_can_write_reg: STD_LOGIC;
begin
  -- next PC logic
  pcjump <= pcplus4(31 downto 28) & instr(25 downto 0) & "00";
  pcreg: flopr generic map(32) port map(clk, reset, pcnext, pc);
  pcadd1: adder port map(pc, X"00000004", pcplus4);
  immsh: sl2 port map(signimm, signimmsh);
  pcadd2: adder port map(pcplus4, signimmsh, pcbranch);
  pcbrmux: mux2 generic map(32) port map(pcplus4, pcbranch, 
                                         pcsrc, pcnextbr);
  pcmux: mux2 generic map(32) port map(pcnextbr, pcjump, jump, pcrealbranch);
  pcjumpreg: mux2 generic map(32) port map(pcrealbranch, srca, jr, pcnext);

  -- register file logic
  rf: regfile port map(clk, regwrite and alu_can_write_reg, instr(25 downto 21), 
                      instr(20 downto 16), writereg, 
							 writeresult,  --JAL
							 srca, writedata);
							 
  ramux: mux2 generic map(32)  port map(result, pcplus4, jal, 
                       writeresult);  -- JAL

  wrmux: mux3 generic map(5) port map(instr(20 downto 16), 
                                      instr(15 downto 11), "11111", --JAL 
												  regdst, writereg);

  -- hardware to support LH
  lhmux1: mux2 generic map(16) port map(readdata(15 downto 0), 
                                        readdata(31 downto 16), 
                                        aluresult(1), half); --LH
  lhse: signext port map(half, signhalf); --LH
  lhmux2: mux2 generic map(32) port map(readdata, signhalf, 
                                        lh, memdata);  --LH

  resmux: mux2 generic map(32) port map(aluresult, memdata,  --LH 
                                        memtoreg, result);
  se: signext port map(instr(15 downto 0), signimm);
  ue: upimm port map(instr(15 downto 0), upperimm); --LUI
  
  -- ALU logic
  srcbmux: mux3 generic map(32) port map(writedata, signimm, upperimm, --LUI
                                         alusrc, srcb);
  mainalu: alu port map(clk, srca, srcb, alucontrol, 
                        instr(10 downto 6),  --LUI
								aluresult, zero,     --BLEZ
								ltez, jr, alu_can_write_reg);
end;