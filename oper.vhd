library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 16 bit operand hold operand register
entity oper is
  port(    clk:  in STD_LOGIC;
           clr:  in STD_LOGIC;
         fwait:  in STD_LOGIC;                       
            ld:  in STD_LOGIC;
        ld_lsb:  in STD_LOGIC;
        ld_msb:  in STD_LOGIC;
           din:  in STD_LOGIC_VECTOR(15 downto 0);
          dout: out STD_LOGIC_VECTOR(15 downto 0)
      );
end oper;

architecture rtl of oper is
signal reg: STD_LOGIC_VECTOR(15 downto 0);
begin
  process(clk)
    begin
      if (clk'event and clk = '1') then
        if fwait = '1' then
          reg <= reg;
        else  
		    if clr = '1' then
             reg <= "0000000000000000";
			 else	 
				 if ld = '1' then
					reg <= din;
				 end if;	
				 if ld_lsb = '1' then
					reg(7 downto 0) <= din(7 downto 0);
					reg(15 downto 8) <= reg(15 downto 8);
				 end if;
				 if ld_msb = '1' then
					reg(15 downto 8) <= din(7 downto 0);
					reg(7 downto 0) <= reg(7 downto 0);
				 end if;
			 end if;	 
        end if;      
      end if;  
  end process;
  dout <= reg;
end rtl;


