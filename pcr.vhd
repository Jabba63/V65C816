library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 16 bit program counter register "PC"
entity pcr is
  port(       clk:  in STD_LOGIC;
                i:  in STD_LOGIC;
            fwait:  in STD_LOGIC;   
		     brk_op:  in STD_LOGIC;                            -- forced BRK (by interrupt request) 
		 branch_flg:  in STD_LOGIC;                            -- branch flag   
		      mov_f:  in STD_LOGIC;                            -- MVN/MVP end transfer
               fc:  in STD_LOGIC_VECTOR(3 downto 0);
             din1:  in STD_LOGIC_VECTOR(7 downto 0);
             din2:  in STD_LOGIC_VECTOR(15 downto 0);
             dout: out STD_LOGIC_VECTOR(15 downto 0)
      );
end pcr;

architecture rtl of pcr is
constant NOP_P: STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- PC no operation
constant LSB_P: STD_LOGIC_VECTOR(3 downto 0) := "0001"; -- PC load lsb
constant MSB_P: STD_LOGIC_VECTOR(3 downto 0) := "0010"; -- PC load msb
constant INC_P: STD_LOGIC_VECTOR(3 downto 0) := "0011"; -- PC increment by 1
constant LOD_P: STD_LOGIC_VECTOR(3 downto 0) := "0100"; -- PC load lsb\msb  (used by JMP\JSR instructions)
constant LML_P: STD_LOGIC_VECTOR(3 downto 0) := "0101"; -- PC load lsb\msb from oper register (used for JML\JSL instructions)
constant IN2_P: STD_LOGIC_VECTOR(3 downto 0) := "0110"; -- PC = PC +2 (BRK opcode)
constant DE3_P: STD_LOGIC_VECTOR(3 downto 0) := "0111"; -- PC = PC -3 (MVN/MVP opcodes)
constant BRA_P: STD_LOGIC_VECTOR(3 downto 0) := "1000"; -- PC branch
constant BRL_P: STD_LOGIC_VECTOR(3 downto 0) := "1001"; -- PC branch long 

signal reg: STD_LOGIC_VECTOR(15 downto 0);

begin

  process(clk)
    begin
      if (clk'event and clk = '1') then
        if fwait = '1' then
          reg <= reg;
        else  
          if i = '1' then
            reg <= reg +1;
          else
            case fc is
              when LSB_P  => reg(7 downto 0) <= din1; reg(15 downto 8) <= reg(15 downto 8);
              when MSB_P  => reg(15 downto 8) <= din1; reg(7 downto 0) <= reg(7 downto 0);
              when INC_P  => reg <= reg +1;
              when LOD_P  => reg(15 downto 8) <= din1; reg(7 downto 0) <= din2(7 downto 0);
              when BRA_P  => 
				    if branch_flg = '1' THEN                                                                     -- if branch taken
				       if din1(7) = '0' THEN                                                                     -- if branch forward
						           reg <= reg + "0000000000000001" + ("00000000" & din1);
						 else                                                                                      -- if branch backwards
						           reg <= reg + "0000000000000001" - ("00000000" & (0 - din1));
						 end if;
					 else                                                                                         -- if branch not taken  
                   reg <= reg + "0000000000000001";					 
		          end if;              				 
              when BRL_P  =>                                                            
		          if din1(7) = '0' THEN                                                                        -- if branch forward
						           reg <= reg + "0000000000000001" + (din1 & din2(7 downto 0));
					 else                                                                                         -- if branch backwards
						           reg <= reg + "0000000000000001" - (0 - (din1 & din2(7 downto 0)));
					 end if;
					 
              when LML_P  => reg <= din2;
              when IN2_P  =>                      
				          if brk_op = '1' then                                                                   -- if BRK opcode PC=PC+2
				                 reg <= reg +1;                                                                  -- PC already incremented by 1 by cpufsm
						    else
							        reg <= reg;
							 end if;	  
              when DE3_P  => 
				          if mov_f = '0' then                                                                    -- if MVN/MVP transfer not finished 
				                 reg <= reg - "0000000000000011";
							 else
							        reg <= reg;
							 end if;	  
              when NOP_P  => reg <= reg;
              when others => reg <= reg;
            end case;
          end if;  
        end if;
      end if;    
  end process;
  dout <= reg;
end rtl;


