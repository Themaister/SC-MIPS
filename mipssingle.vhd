--------------------------------------------------
-- mipssingle.vhd
-- sarah_harris@hmc.edu 27 may 2007
-- single-cycle mips processor - vhdl
--------------------------------------------------

--------------------------------------------------
-- Extensions by Hans-Kristian Arntzen
--------------------------------------------------

library ieee; use ieee.std_logic_1164.all;

entity mipssingle is -- single cycle mips processor
   port(clk, reset:        in  std_logic;
        pc:                inout std_logic_vector(31 downto 0);
        instr:             in  std_logic_vector(31 downto 0);
        memwrite:          out std_logic;
   aluresult, writedata: inout std_logic_vector(31 downto 0);
   readdata:          in  std_logic_vector(31 downto 0));
end;

architecture struct of mipssingle is
   component controller
      port(op, funct:          in  std_logic_vector(5 downto 0);
           zero:               in  std_logic;
      memtoreg, memwrite: out std_logic;
      pcsrc:              out std_logic;
      alusrc:             out std_logic_vector(1 downto 0); --lui
      regdst:             out std_logic_vector(1 downto 0); --jal
      regwrite:           out std_logic;
      jump:               out std_logic;
      alucontrol:         out std_logic_vector(6 downto 0); --sll
      ltez:               inout std_logic;                 --blez
      jal:                out std_logic;                    --jal
      lh:                 out std_logic;                   --lh
      rt0:                in std_logic);                    --bltzgez
   end component;
   component datapath
      port(clk, reset:        in  std_logic;
      memtoreg, pcsrc:   in  std_logic;
      alusrc:            in  std_logic_vector(1 downto 0); --lui
      regdst:            in  std_logic_vector(1 downto 0); --jal
      regwrite, jump:    in  std_logic;
      alucontrol:        in  std_logic_vector(6 downto 0); --sll
      zero:              inout std_logic;
      pc:                inout std_logic_vector(31 downto 0);
      instr:             in  std_logic_vector(31 downto 0);
      aluresult, writedata: inout std_logic_vector(31 downto 0);
      readdata:          in  std_logic_vector(31 downto 0);
      ltez:              out std_logic;  --blez
      jal:               in  std_logic;  --jal
      lh:                in  std_logic; --lh
      rt0:               out std_logic); --bltzgez  
   end component;
   signal memtoreg: std_logic;
   signal alusrc: std_logic_vector(1 downto 0); --lui
   signal regdst: std_logic_vector(1 downto 0); --jal
   signal regwrite, jump: std_logic;
   signal pcsrc, zero: std_logic;
   signal alucontrol: std_logic_vector(6 downto 0); --sll
   signal ltez: std_logic; --blez
   signal jal: std_logic;  --jal
   signal lh: std_logic;   --lh
   signal rt0: std_logic; --bltzgez
begin
   cont: controller port map(instr(31 downto 26), instr(5 downto 0),
   zero, memtoreg, memwrite, pcsrc, alusrc,
   regdst, regwrite, jump, alucontrol,
   ltez,  --blez
   jal,   --jal
   lh, rt0);   --lh
   dp: datapath port map(clk, reset, memtoreg, pcsrc, alusrc, regdst,
   regwrite, jump, alucontrol, zero, pc, instr,
   aluresult, writedata, readdata,
   ltez,   --blez
   jal,    --jal
   lh, rt0);    --lh
end;


library ieee; use ieee.std_logic_1164.all;
entity controller is -- single cycle control decoder
   port(op, funct:          in  std_logic_vector(5 downto 0);
        zero:               in  std_logic;
   memtoreg, memwrite: out std_logic;
   pcsrc:              out std_logic;
   alusrc:             out std_logic_vector(1 downto 0); --lui
   regdst:             out std_logic_vector(1 downto 0); --jal
   regwrite:           out std_logic;
   jump:               out std_logic;
   alucontrol:         out std_logic_vector(6 downto 0); --sll
   ltez:               inout std_logic;                    --blez
   jal:                out std_logic;                    --jal
   lh:                 out std_logic; --lh
   rt0:                in std_logic);                   --bltzgez
end;


architecture struct of controller is
   component maindec
   port(op:                 in  std_logic_vector(5 downto 0);
   memtoreg, memwrite: out std_logic;
   branch:             out std_logic;
   bne:                out std_logic;
   alusrc:             out std_logic_vector(1 downto 0); --lui
   regdst:             out std_logic_vector(1 downto 0); --jal
   regwrite:           out std_logic;
   jump:               out std_logic;
   aluop:              out std_logic_vector(2 downto 0);
   blez:               out std_logic;  --blez
   bgtz:			   out std_logic; --bgtz
   bltzgez:            out std_logic; --blezgtz
   jal:                out std_logic;  --jal
   lh:                 out std_logic); --lh
   end component;
   component aludec
   port(funct:      in  std_logic_vector(5 downto 0);
        aluop:      in  std_logic_vector(2 downto 0);
        alucontrol: out std_logic_vector(6 downto 0));  --sll
   end component;
   signal aluop: std_logic_vector(2 downto 0);
   signal beq: std_logic; -- beq
   signal blez: std_logic;  --blez
   signal bgtz: std_logic; --bgtz
   
   signal bltzgez, bltz, bgez: std_logic; --blezgtz
   
   signal bne: std_logic; --bne
begin
   md: maindec port map(op, memtoreg, memwrite, beq, bne,
   alusrc, regdst, regwrite, jump, aluop,
   blez, bgtz, bltzgez, jal, lh);  --blez, jal, lh
   ad: aludec port map(funct, aluop, alucontrol);
   
   bltz <= bltzgez and (not rt0);
   bgez <= bltzgez and rt0;

   pcsrc <= (beq and zero) or 
			(blez and ltez) or 
			(bne and (not zero)) or 
			(bgtz and (not ltez)) or
			(bltz and ltez and (not zero)) or
			(bgez and (zero or (not ltez)));  --blez
end;

library ieee; use ieee.std_logic_1164.all;
entity maindec is -- main control decoder
   port(op:                 in  std_logic_vector(5 downto 0);
   memtoreg, memwrite: out std_logic;
   branch:             out std_logic; -- beq
   bne:				   out std_logic; -- bne
   alusrc:             out std_logic_vector(1 downto 0); --lui
   regdst:             out std_logic_vector(1 downto 0); --jal
   regwrite:           out std_logic;
   jump:               out std_logic;
   aluop:              out std_logic_vector(2 downto 0);
   blez:               out std_logic;  --blez
   bgtz:               out std_logic;  --bgtz
   bltzgez:            out std_logic;  --bltzgez
   jal:                out std_logic;  --jal
   lh:                 out std_logic); --lh
end;

architecture behave of maindec is
  -- increase number of control signals for lui, blez, jal, lh
   signal controls: std_logic_vector(17 downto 0);
begin
  process(op) begin
     case op is
        when "000000" => controls <= "000101000000010000"; --rtype
        when "100011" => controls <= "000100010010000000"; --lw
        when "101011" => controls <= "000000010100000000"; --sw
        when "000100" => controls <= "000000001000001000"; --beq
        when "000101" => controls <= "010000000000001000"; --bne
        when "000001" => controls <= "100000000000001000"; --bltzgez
        when "001000" => controls <= "000100010000000000"; --addi
        when "001001" => controls <= "000100010000000000"; --addiu
        when "000010" => controls <= "000000000001000000"; --j
        when "001010" => controls <= "000100010000011000"; --slti
        when "001111" => controls <= "000100100000000000"; --lui
        when "000110" => controls <= "000000000000001100"; --blez
        when "000111" => controls <= "001000000000001000"; --bgtz
        when "000011" => controls <= "000110000001000010"; --jal
        when "100001" => controls <= "000100010010000001"; --lh
        when "001100" => controls <= "000100010000100000"; --andi
        when "001110" => controls <= "000100010000111000"; --xori
        when "001101" => controls <= "000100010000101000"; --ori
        when others   => controls <= "------------------"; -- illegal op
     end case;
  end process;
  bltzgez  <= controls(17);
  bne      <= controls(16);
  bgtz     <= controls(15);
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

library ieee; use ieee.std_logic_1164.all;
entity aludec is -- alu control decoder
   port(funct:      in  std_logic_vector(5 downto 0);
        aluop:      in  std_logic_vector(2 downto 0);
        alucontrol: out std_logic_vector(6 downto 0));  --sll
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
        when "111" => alucontrol <= "0001001"; -- xori
        when others => case funct is         -- r-type instructions
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
           when "001001" => alucontrol <= "0001000"; -- jalr, getting advanced here! 
           -- We will deduce if we have to link from value in srcA. Linking to address 0 is undefined.
           when "010000" => alucontrol <= "0010000"; -- mfhi
           when "010001" => alucontrol <= "1000000"; -- mthi
           when "010010" => alucontrol <= "0100000"; -- mflo
           when "010011" => alucontrol <= "1010000"; -- mtlo
           when "011000" => alucontrol <= "1100000"; -- mult
           when "011001" => alucontrol <= "1100000"; -- multu, but we don't care
           when "011010" => alucontrol <= "1110000"; -- div :d
           when "011011" => alucontrol <= "1110000"; -- divu, but we don't care
           
        when others   => alucontrol <= "-------"; -- ???
     end case;
    end case;
 end process;
end;

library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_arith.all;
entity datapath is  -- mips datapath
   port(clk, reset:        in  std_logic;
   memtoreg, pcsrc:   in  std_logic;
   alusrc:            in  std_logic_vector(1 downto 0); --lui
   regdst:            in  std_logic_vector(1 downto 0); --jal
   regwrite, jump:    in  std_logic;
   alucontrol:        in  std_logic_vector(6 downto 0); --sll
   zero:              inout std_logic;
   pc:                inout std_logic_vector(31 downto 0);
   instr:             in  std_logic_vector(31 downto 0);
   aluresult, writedata: inout std_logic_vector(31 downto 0);
   readdata:          in  std_logic_vector(31 downto 0);
   ltez:              out std_logic;  --blez
   jal:               in  std_logic;  --jal
   lh:                in  std_logic;  --lh
   rt0:               out std_logic); --blezgtz
end;

architecture struct of datapath is
   component alu
   port(clk: in std_logic;
   a, b: in     std_logic_vector(31 downto 0);
   f:    in     std_logic_vector(6 downto 0); --sll - 6-4 mul/div stuff
   shamt: in    std_logic_vector(4 downto 0); --sll
   alu_out:    inout std_logic_vector(31 downto 0);
   zero: inout  std_logic;  --blez
   ltez: out    std_logic; --blez
   jr: out std_logic; --jr
   link: out std_logic; -- jalr
   write_reg: out std_logic); --write mul/div op or jr 
   end component;
   component regfile
   port(clk:           in  std_logic;
        we3:           in  std_logic;
   ra1, ra2, wa3: in  std_logic_vector(4 downto 0);
   wd3:           in  std_logic_vector(31 downto 0);
   rd1, rd2:      out std_logic_vector(31 downto 0));
   end component;
   component adder
      port(a, b: in  std_logic_vector(31 downto 0);
           y:    out std_logic_vector(31 downto 0));
   end component;
   component sl2
   port(a: in  std_logic_vector(31 downto 0);
        y: out std_logic_vector(31 downto 0));
   end component;
   component signext
   port(a: in  std_logic_vector(15 downto 0);
        y: out std_logic_vector(31 downto 0));
   end component;
   component flopr generic(width: integer);
      port(clk, reset: in  std_logic;
           d:          in  std_logic_vector(width-1 downto 0);
           q:          out std_logic_vector(width-1 downto 0));
   end component;
   component floprs is -- boolean flip-flop
   port (clk, reset: in std_logic;
			d: in std_logic;
			q: out std_logic);
   end component;
   component mux2 generic(width: integer);
      port(d0, d1: in  std_logic_vector(width-1 downto 0);
           s:      in  std_logic;
           y:      out std_logic_vector(width-1 downto 0));
   end component;
   component upimm --lui
   port(a: in  std_logic_vector(15 downto 0);
        y: out std_logic_vector(31 downto 0));
   end component;
   component mux3 generic(width: integer);  --lui
      port(d0, d1, d2: in  std_logic_vector(width-1 downto 0);
           s:          in  std_logic_vector(1 downto 0);
           y:          out std_logic_vector(width-1 downto 0));
   end component;
   signal writereg: std_logic_vector(4 downto 0);
   signal pcjump, pcjump_delayed, pcnext, pcnextbr, 
   pcplus4, pcplus8, pcbranch, pcrealbranch:  std_logic_vector(31 downto 0);
   signal signimm, signimmsh: std_logic_vector(31 downto 0);
   signal upperimm: std_logic_vector(31 downto 0); --lui
   signal srca, srca_delayed, srcb, result: std_logic_vector(31 downto 0);
   signal writeresult: std_logic_vector(31 downto 0); --jal
   signal half: std_logic_vector(15 downto 0); --lh
   signal signhalf, memdata: std_logic_vector(31 downto 0); --lh
   signal jr, jr_delayed: std_logic; --jr
   signal jump_delayed: std_logic; --j
   signal jal_delayed: std_logic; --jal
   signal alu_link, alu_link_delayed: std_logic; --jalr
   signal alu_can_write_reg: std_logic;
   signal regdst_delayed: std_logic_vector(1 downto 0);
   signal mask_reg: std_logic_vector(4 downto 0); --bltz/bgez
begin
  -- next pc logic
   pcjump <= pcplus4(31 downto 28) & instr(25 downto 0) & "00";
   pcreg: flopr generic map(32) port map(clk, reset, pcnext, pc);
   pcadd1: adder port map(pc, x"00000004", pcplus4);
   pcadd_link: adder port map(pc, x"00000008", pcplus8);
   immsh: sl2 port map(signimm, signimmsh);
   pcadd2: adder port map(pcplus4, signimmsh, pcbranch);
   pcbrmux: mux2 generic map(32) port map(pcplus4, pcbranch, 
   pcsrc, pcnextbr);
   pcmux: mux2 generic map(32) port map(pcnextbr, pcjump_delayed, jump_delayed, pcrealbranch);
   pcjumpreg: mux2 generic map(32) port map(pcrealbranch, srca_delayed, jr_delayed, pcnext);
   
   -- Set up branch delay slots. We don't really need this stuff when doing single cycle,
   -- but this is what MIPS does it seems :D
   jump_delayslot: floprs port map(clk, reset, jump, jump_delayed);
   jr_delayslot: floprs port map(clk, reset, jr, jr_delayed);
   alu_link_delayslot: floprs port map(clk, reset, alu_link, alu_link_delayed);
   jal_delayslot: floprs port map(clk, reset, jal, jal_delayed);
   srca_delayslot: flopr generic map(32) port map(clk, reset, srca, srca_delayed);
   pcjump_delayslot: flopr generic map(32) port map(clk, reset, pcjump, pcjump_delayed);


   mask_reg <= "00000" when instr(31 downto 26) = "000001" else instr(20 downto 16);
  -- register file logic
   rf: regfile port map(clk, regwrite and alu_can_write_reg, instr(25 downto 21), 
   mask_reg, writereg, 
   writeresult,  --jal
   srca, writedata);

   ramux: mux2 generic map(32)  port map(result, pcplus8, jal or alu_link, -- Direct JAL or ALU initiated link?
   writeresult);  -- jal

   regdst_delayed <= "10" when ((jal or alu_link) = '1') else regdst; -- jal
   wrmux: mux3 generic map(5) port map(instr(20 downto 16), 
   instr(15 downto 11), "11111", --jal 
   regdst_delayed, writereg);

  -- hardware to support lh
   lhmux1: mux2 generic map(16) port map(readdata(15 downto 0), 
   readdata(31 downto 16), 
   aluresult(1), half); --lh
   lhse: signext port map(half, signhalf); --lh
   lhmux2: mux2 generic map(32) port map(readdata, signhalf, 
   lh, memdata);  --lh

   resmux: mux2 generic map(32) port map(aluresult, memdata,  --lh 
   memtoreg, result);
   se: signext port map(instr(15 downto 0), signimm);
   ue: upimm port map(instr(15 downto 0), upperimm); --lui

  -- alu logic
   srcbmux: mux3 generic map(32) port map(writedata, signimm, upperimm, --lui
   alusrc, srcb);
   mainalu: alu port map(clk, srca, srcb, alucontrol, 
   instr(10 downto 6),  --lui
   aluresult, zero,     --blez
   ltez, jr, alu_link, alu_can_write_reg);
   
   rt0 <= instr(16); --blezgtz
end;
