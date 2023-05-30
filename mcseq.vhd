library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- opcode => microcode address generation
entity mcseq is
  port(    clk:  in STD_LOGIC;
           clr:  in STD_LOGIC;
        mc_nop:  in STD_LOGIC;
         fwait:  in STD_LOGIC;
             q: out STD_LOGIC_VECTOR(3 downto 0)
      );
end mcseq;

architecture comb of mcseq is
signal reg: STD_LOGIC_VECTOR(3 downto 0);
begin
  process(clk)
  begin
    if(clk'event and clk = '1')then
      if fwait = '1' then
        reg <= reg;
      else  
        if clr = '1' then
          reg <= "0000";
        else
          if mc_nop = '1' then
            reg <= "1111";
          else
            reg <= reg +1;
          end if;  
        end if;    
      end if;
    end if;
  end process;        
  q <= reg;
end comb;


