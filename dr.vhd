library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 16 bit zero page/direct register "D"
entity dr is
  port(     clk:  in STD_LOGIC;
            clr:  in STD_LOGIC;
          fwait:  in STD_LOGIC; 
         ld_lsb:  in STD_LOGIC;                        -- load lsb
         ld_msb:  in STD_LOGIC;                        -- load msb
            din:  in STD_LOGIC_VECTOR(15 downto 0); 
           dout: out STD_LOGIC_VECTOR(15 downto 0)
      );
end dr;

architecture rtl of dr is
signal reg: STD_LOGIC_VECTOR(15 downto 0);
signal op:  STD_LOGIC_VECTOR(1 downto 0);
begin
  op <= ld_msb & ld_lsb;
  process(clk)
    begin
      if (clk'event and clk = '1') then
        if fwait = '1' then
          reg <= reg;
        else  
          if clr = '1' then
            reg <= "0000000000000000";
          else  
				 case op is
					when   "01" => reg(7 downto 0) <= din(7 downto 0);              -- load lsb
										reg(15 downto 8) <= reg(15 downto 8);
					when   "10" => reg(15 downto 8) <= din(7 downto 0);             -- load msb
										reg(7 downto 0) <= reg(7 downto 0);
					when   "11" => reg <= din;                                      -- load msb & lsb						
					when others => reg <= reg;
				 end case;
          end if;  
        end if;              
      end if;  
  end process;
  dout <= reg;
end rtl;


