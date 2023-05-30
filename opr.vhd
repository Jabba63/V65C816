library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 8 bit opcode hold register
entity opr is
  port(   clk:  in STD_LOGIC;
          clr:  in STD_LOGIC;
        fwait:  in STD_LOGIC;                       
           ld:  in STD_LOGIC;
          din:  in STD_LOGIC_VECTOR(7 downto 0);
        brk_f: out STD_LOGIC;
        cop_f: out STD_LOGIC;
         dout: out STD_LOGIC_VECTOR(7 downto 0)
      );
end opr;

architecture rtl of opr is
constant BRK_OP: STD_LOGIC_VECTOR(7 downto 0) := "00000000"; -- 0x00 BRK/IRQ/NMI/RES
constant COP_OP: STD_LOGIC_VECTOR(7 downto 0) := "00000010"; -- 0x02 COP
signal      reg: STD_LOGIC_VECTOR(7 downto 0);
signal       bf: STD_LOGIC; 
signal       cf: STD_LOGIC; 
begin
  process(clk)
  begin
    if(clk'event and clk = '1')then
      if fwait = '1' then
        reg <= reg;
      else  
        if clr = '1' then                  -- clr serves to force an "BRK" opcode on RES-NMI-IRQ interrupt
          reg <= BRK_OP;
          bf <= '0';
        else  
          if ld = '1' then
            reg <= din;
            if din = BRK_OP then           -- check if the opcode "BRK" was loaded as normal instruction or it was forced 
              bf <= '1';                   -- by an interrupt request, thus in order to set properly the flag "B" of status register     
				  cf <= '0';
            else
				  if din = COP_OP THEN
				     cf <= '1';
				  else	  
				     cf <= '0';
				  end if;	  
              bf <= '0';
            end if;    
          else
            reg <= reg;  
            bf <= bf;
          end if; 
        end if;  
      end if;  
    end if;     
  end process;
  brk_f <= bf;
  cop_f <= cf;
  dout <= reg;
end rtl;


