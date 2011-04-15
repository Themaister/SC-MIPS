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
        memwrite_size:     out std_logic_vector(1 downto 0);
   aluresult, writedata: inout std_logic_vector(31 downto 0);
   readdata:          in  std_logic_vector(31 downto 0));
end;

architecture struct of mipssingle is
   component controller
      port(op, funct:          in  std_logic_vector(5 downto 0);
           zero:               in  std_logic;
      memtoreg, memwrite: out std_logic;
      memwrite_size:      out std_logic_vector(1 downto 0);
      pcsrc:              out std_logic;
      alusrc:             out std_logic_vector(1 downto 0); --lui
      regdst:             out std_logic_vector(1 downto 0); --jal
      regwrite:           out std_logic;
      jump:               out std_logic;
      alucontrol:         out std_logic_vector(7 downto 0); --sll
      ltez:               inout std_logic;                 --blez
      jal:                out std_logic;                    --jal
      lh:                 out std_logic;                   --lh
      lb:                 out std_logic;                   --lb
      lbhsign:            out std_logic;                   --lb/lh
      alu_unsigned:       out std_logic;                   --unsigned ops
      rt0:                in std_logic);                    --bltzgez
   end component;
   component datapath
      port(clk, reset:        in  std_logic;
      memtoreg, pcsrc:   in  std_logic;
      alusrc:            in  std_logic_vector(1 downto 0); --lui
      regdst:            in  std_logic_vector(1 downto 0); --jal
      regwrite, jump:    in  std_logic;
      alucontrol:        in  std_logic_vector(7 downto 0); --sll
      zero:              inout std_logic;
      pc:                inout std_logic_vector(31 downto 0);
      instr:             in  std_logic_vector(31 downto 0);
      aluresult, writedata: inout std_logic_vector(31 downto 0);
      readdata:          in  std_logic_vector(31 downto 0);
      ltez:              out std_logic;  --blez
      jal:               in  std_logic;  --jal
      lh:                in  std_logic; --lh
      lb:                in  std_logic; --lb
      lbhsign:           in  std_logic; --lb/--lh
      alu_unsigned:      in std_logic; --unsigned ops
      rt0:               out std_logic); --bltzgez  
   end component;
   signal memtoreg: std_logic;
   signal alusrc: std_logic_vector(1 downto 0); --lui
   signal regdst: std_logic_vector(1 downto 0); --jal
   signal regwrite, jump: std_logic;
   signal pcsrc, zero: std_logic;
   signal alucontrol: std_logic_vector(7 downto 0); --sll
   signal ltez: std_logic; --blez
   signal jal: std_logic;  --jal
   signal lh: std_logic;   --lh
   signal lb: std_logic;   --lb
   signal lbhsign: std_logic; --lb/lh
   signal alu_unsigned: std_logic; --unsigned ops
   signal rt0: std_logic; --bltzgez
begin
   cont: controller port map(instr(31 downto 26), instr(5 downto 0),
   zero, memtoreg, memwrite, memwrite_size, pcsrc, alusrc,
   regdst, regwrite, jump, alucontrol,
   ltez,  --blez
   jal,   --jal
   lh, lb, lbhsign, alu_unsigned, rt0);   --lh
   dp: datapath port map(clk, reset, memtoreg, pcsrc, alusrc, regdst,
   regwrite, jump, alucontrol, zero, pc, instr,
   aluresult, writedata, readdata,
   ltez,   --blez
   jal,    --jal
   lh, lb, lbhsign, alu_unsigned, rt0);    --lh
end;


library ieee; use ieee.std_logic_1164.all;
entity controller is -- single cycle control decoder
   port(op, funct:          in  std_logic_vector(5 downto 0);
        zero:               in  std_logic;
   memtoreg, memwrite: out std_logic;
   memwrite_size:      out std_logic_vector(1 downto 0); --sb, sh
   pcsrc:              out std_logic;
   alusrc:             out std_logic_vector(1 downto 0); --lui
   regdst:             out std_logic_vector(1 downto 0); --jal
   regwrite:           out std_logic;
   jump:               out std_logic;
   alucontrol:         out std_logic_vector(7 downto 0); --sll
   ltez:               inout std_logic;                    --blez
   jal:                out std_logic;                    --jal
   lh:                 out std_logic; --lh
   lb:                 out std_logic; --lb
   lbhsign:            out std_logic; --lb/lh;
   alu_unsigned:       out std_logic; --unsigned ops
   rt0:                in std_logic);                   --bltzgez
end;


architecture struct of controller is
   component maindec
   port(op:                 in  std_logic_vector(5 downto 0);
	   memtoreg, memwrite: out std_logic;
	   memwrite_size:      out std_logic_vector(1 downto 0); --sb, sh
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
	   lh:                 out std_logic;  --lh
	   lb:                 out std_logic;  --lb
	   lbhsign:            out std_logic; --lb/lh
	   alu_unsigned:       out std_logic); --unsigned
   end component;
   component aludec
   port(funct:      in  std_logic_vector(5 downto 0);
        aluop:      in  std_logic_vector(2 downto 0);
        alucontrol: out std_logic_vector(7 downto 0);  --sll
        alu_unsigned: in std_logic);
   end component;
   signal aluop: std_logic_vector(2 downto 0);
   signal beq: std_logic; -- beq
   signal blez: std_logic;  --blez
   signal bgtz: std_logic; --bgtz
   
   signal bltzgez, bltz, bgez: std_logic; --blezgtz
   
   signal bne: std_logic; --bne
   signal alu_is_unsigned: std_logic;
begin
   md: maindec port map(op, memtoreg, memwrite, memwrite_size, beq, bne,
   alusrc, regdst, regwrite, jump, aluop,
   blez, bgtz, bltzgez, jal, lh, lb, lbhsign, alu_is_unsigned);  --blez, jal, lh, lb
   ad: aludec port map(funct, aluop, alucontrol, alu_is_unsigned);
   
   bltz <= bltzgez and (not rt0);
   bgez <= bltzgez and rt0;

   pcsrc <= (beq and zero) or 
			(blez and ltez) or 
			(bne and (not zero)) or 
			(bgtz and (not ltez)) or
			(bltz and ltez and (not zero)) or
			(bgez and (zero or (not ltez)));  --blez
			
   alu_unsigned <= alu_is_unsigned;
end;

library ieee; use ieee.std_logic_1164.all;
entity maindec is -- main control decoder
   port(op:                 in  std_logic_vector(5 downto 0);
   memtoreg, memwrite: out std_logic;
   memwrite_size:      out std_logic_vector(1 downto 0); --sb, sh
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
   lh:                 out std_logic;  --lh
   lb:                 out std_logic;  --lb
   lbhsign:            out std_logic; --lb/lh sign extend
   alu_unsigned:       out std_logic); --unsigned ops
end;

architecture behave of maindec is
  -- increase number of control signals for lui, blez, jal, lh, lb, sb, sh
   signal controls: std_logic_vector(22 downto 0);
begin
  process(op) begin
     case op is
        when "100000" => controls <= "00011000100010010000000"; --lb
        when "100100" => controls <= "00001000100010010000000"; --lbu
        when "000000" => controls <= "00000000101000000010000"; --rtype
        when "100011" => controls <= "00000000100010010000000"; --lw
        when "101011" => controls <= "01100000000010100000000"; --sw
        when "101001" => controls <= "01000000000010100000000"; --sh
        when "101000" => controls <= "00100000000010100000000"; --sb
        when "000100" => controls <= "00000000000001000001000"; --beq
        when "000101" => controls <= "00000010000000000001000"; --bne
        when "000001" => controls <= "00000100000000000001000"; --bltzgez
        when "001000" => controls <= "00000000100010000000000"; --addi
        when "001001" => controls <= "10000000100010000000000"; --addiu
        when "000010" => controls <= "00000000000000001000000"; --j
        when "001010" => controls <= "00000000100010000011000"; --slti
        when "001011" => controls <= "10000000100010000011000"; --sltiu
        when "001111" => controls <= "00000000100100000000000"; --lui
        when "000110" => controls <= "00000000000000000001100"; --blez
        when "000111" => controls <= "00000001000000000001000"; --bgtz
        when "000011" => controls <= "00000000110000001000010"; --jal
        when "100001" => controls <= "00010000100010010000001"; --lh
        when "100101" => controls <= "00000000100010010000001"; --lhu
        when "001100" => controls <= "10000000100010000100000"; --andi
        when "001110" => controls <= "10000000100010000111000"; --xori
        when "001101" => controls <= "10000000100010000101000"; --ori
        when others   => controls <= "-----------------------"; -- illegal op
     end case;
  end process;
  alu_unsigned <= controls(22);
  memwrite_size <= controls(21 downto 20);
  lbhsign  <= controls(19);
  lb       <= controls(18);
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
        alucontrol: out std_logic_vector(7 downto 0);  --sll
        alu_unsigned: in std_logic);
end;

architecture behave of aludec is
   signal l_alucontrol : std_logic_vector(7 downto 0);
begin
  process(aluop, funct) begin
     case aluop is
        when "000" => l_alucontrol <= "00000010"; -- add (for lb/sb/addi)
        when "001" => l_alucontrol <= "00001010"; -- sub (for beq)
        when "011" => l_alucontrol <= "00001011"; -- slt (for slti)
        when "100" => l_alucontrol <= "00000000"; -- andi
        when "101" => l_alucontrol <= "00000001"; -- ori
        when "111" => l_alucontrol <= "00001001"; -- xori
        when others => case funct is         -- r-type instructions
           when "100000" => l_alucontrol <= "00000010"; -- add
           when "100001" => l_alucontrol <= "10000010"; -- addu
           when "100010" => l_alucontrol <= "00001010"; -- sub
           when "100011" => l_alucontrol <= "10001010"; -- subu
           when "100100" => l_alucontrol <= "10000000"; -- and
           when "100101" => l_alucontrol <= "10000001"; -- or
           when "100110" => l_alucontrol <= "10001001"; -- xor
           when "100111" => l_alucontrol <= "10001111"; -- nor
           when "101010" => l_alucontrol <= "00001011"; -- slt
           when "101011" => l_alucontrol <= "10001011"; -- sltu
                                                     -- shifting
           when "000000" => l_alucontrol <= "00000100"; -- sll
           when "000010" => l_alucontrol <= "00000101"; -- srl
           when "000011" => l_alucontrol <= "00000110"; -- sra
           when "000100" => l_alucontrol <= "00001100"; -- sllv
           when "000110" => l_alucontrol <= "00001101"; -- srlv
           when "000111" => l_alucontrol <= "00001110"; -- srav
                                                     -- end shifting
           when "001000" => l_alucontrol <= "00001000"; -- jr
           when "001001" => l_alucontrol <= "00001000"; -- jalr, getting advanced here! 
           -- We will deduce if we have to link from value in srcA. Linking to address 0 is undefined.
           when "010000" => l_alucontrol <= "00010000"; -- mfhi
           when "010001" => l_alucontrol <= "01000000"; -- mthi
           when "010010" => l_alucontrol <= "00100000"; -- mflo
           when "010011" => l_alucontrol <= "01010000"; -- mtlo
           when "011000" => l_alucontrol <= "01100000"; -- mult
           when "011001" => l_alucontrol <= "11100000"; -- multu, but we don't care (yet)
           when "011010" => l_alucontrol <= "01110000"; -- div
           when "011011" => l_alucontrol <= "11110000"; -- divu
           
        when others   => l_alucontrol <= "--------"; -- ???
     end case;
    end case;
 end process;
 alucontrol <= (alu_unsigned or l_alucontrol(7)) & l_alucontrol(6 downto 0);
end;

library ieee; use ieee.std_logic_1164.all; use ieee.std_logic_arith.all;
entity datapath is  -- mips datapath
   port(clk, reset:        in  std_logic;
   memtoreg, pcsrc:   in  std_logic;
   alusrc:            in  std_logic_vector(1 downto 0); --lui
   regdst:            in  std_logic_vector(1 downto 0); --jal
   regwrite, jump:    in  std_logic;
   alucontrol:        in  std_logic_vector(7 downto 0); --sll
   zero:              inout std_logic;
   pc:                inout std_logic_vector(31 downto 0);
   instr:             in  std_logic_vector(31 downto 0);
   aluresult, writedata: inout std_logic_vector(31 downto 0);
   readdata:          in  std_logic_vector(31 downto 0);
   ltez:              out std_logic;  --blez
   jal:               in  std_logic;  --jal
   lh:                in  std_logic;  --lh
   lb:                in  std_logic;  --lb
   lbhsign:           in  std_logic; --lb/lh
   alu_unsigned:      in std_logic;  --unsigned ops
   rt0:               out std_logic); --blezgtz
end;

architecture struct of datapath is
   component alu
   port(clk: in std_logic;
	   a, b: in     std_logic_vector(31 downto 0);
	   f:    in     std_logic_vector(7 downto 0); --sll - 6-4 mul/div stuff
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
   port(a: in std_logic_vector(15 downto 0);
	    y: out std_logic_vector(31 downto 0));
   end component;
   component signext16 --lh
   port(a: in  std_logic_vector(15 downto 0);
        s: in std_logic;
        y: out std_logic_vector(31 downto 0));
   end component;
   component signext8 is -- lb
   port(a: in  std_logic_vector(7 downto 0);
        s: in  std_logic;
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
   component mux4 is -- lb
   generic(width: integer);
   port(d0, d1, d2, d3: in  std_logic_vector(width-1 downto 0);
        s:          in  std_logic_vector(1 downto 0);
        y:          out std_logic_vector(width-1 downto 0));
   end component;
   
   signal writereg: std_logic_vector(4 downto 0);
   signal pcjump, pcjump_delayed, pcnext, pcnextbr, 
   pcplus4, pcplus8, pcbranch, pcbranch_delayed, pcrealbranch:  std_logic_vector(31 downto 0);
   signal pcsrc_delayed : std_logic;
   signal signimm, signimmsh: std_logic_vector(31 downto 0);
   signal upperimm: std_logic_vector(31 downto 0); --lui
   signal srca, srca_delayed, srcb, result: std_logic_vector(31 downto 0);
   signal writeresult: std_logic_vector(31 downto 0); --jal
   signal half: std_logic_vector(15 downto 0); --lh
   signal lbbyte: std_logic_vector(7 downto 0); --lb
   signal signhalf, signbyte, memdata: std_logic_vector(31 downto 0); --lh/lb
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
   pcbrmux: mux2 generic map(32) port map(pcplus4, pcbranch_delayed, 
   pcsrc_delayed, pcnextbr);
   pcmux: mux2 generic map(32) port map(pcnextbr, pcjump_delayed, jump_delayed, pcrealbranch);
   pcjumpreg: mux2 generic map(32) port map(pcrealbranch, srca_delayed, jr_delayed, pcnext);
   
   -- Set up branch delay slots. We don't really need this stuff when doing single cycle,
   -- but this is what MIPS does it seems :D 
   -- Implemented as simple flip-flops that delay our data for a single cycle.
   jump_delayslot: floprs port map(clk, reset, jump, jump_delayed);
   jr_delayslot: floprs port map(clk, reset, jr, jr_delayed);
   alu_link_delayslot: floprs port map(clk, reset, alu_link, alu_link_delayed);
   jal_delayslot: floprs port map(clk, reset, jal, jal_delayed);
   srca_delayslot: flopr generic map(32) port map(clk, reset, srca, srca_delayed);
   pcjump_delayslot: flopr generic map(32) port map(clk, reset, pcjump, pcjump_delayed);
   pcscr_delayslot: floprs port map(clk, reset, pcsrc, pcsrc_delayed);
   pcbranch_delayslot: flopr generic map(32) port map(clk, reset, pcbranch, pcbranch_delayed);


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
   lhmux1: mux2 generic map(16) port map(readdata(31 downto 16), 
   readdata(15 downto 0), 
   aluresult(1), half); --lh
   lhse: signext16 port map(half, lbhsign, signhalf); --lh
   
   -- hardware to support lb
   lbmux1: mux4 generic map(8) port map(
			readdata(31 downto 24), readdata(23 downto 16), 
			readdata(15 downto 8), readdata(7 downto 0),
			aluresult(1 downto 0), lbbyte); -- lb
   lbse: signext8 port map(lbbyte, lbhsign, signbyte); --lb

   -- mux either straight data or 16-bit/8-bit versions of these...
   lhbmux1: mux3 generic map(32) port map(readdata, signbyte, signhalf, 
   lh & lb, memdata);  --lh/lb

   resmux: mux2 generic map(32) port map(aluresult, memdata,  --lh/lb
   memtoreg, result);
   se: signext16 port map(instr(15 downto 0), not alu_unsigned, signimm);
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
