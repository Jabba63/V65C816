library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 16 bit accumulator register "A"
entity ar is
  port(       clk:  in STD_LOGIC;
            fwait:  in STD_LOGIC; 
             size:  in STD_LOGIC;
           ld_lsb:  in STD_LOGIC;
           ld_msb:  in STD_LOGIC;
	    ld_mul_lsb:  in STD_LOGIC;
		   	    d:  in STD_LOGIC;
		  end_count: out STD_LOGIC;
              din:  in STD_LOGIC_VECTOR(15 downto 0); 
			 mul_lsb:  in STD_LOGIC_VECTOR(15 downto 0); 	  
             dout: out STD_LOGIC_VECTOR(15 downto 0)
      );
end ar;

architecture rtl of ar is
signal reg: STD_LOGIC_VECTOR(15 downto 0);
signal op:  STD_LOGIC_VECTOR(3 downto 0);
begin
  op <= ld_mul_lsb & d & ld_msb & ld_lsb;
  process(clk)
    begin
      if (clk'event and clk = '1') then
        if fwait = '1' then
          reg <= reg;
        else  
		    if size = '1' then 
				 case op is
					when   "0001" => reg(7 downto 0) <= din(7 downto 0);             -- load lsb
			                       reg(15 downto 8) <= reg(15 downto 8);
					when   "0010" => reg(15 downto 8) <= din(7 downto 0);            -- load msb
								  		  reg(7 downto 0) <= reg(7 downto 0);
					when   "0011" => reg(7 downto 0) <= din(7 downto 0);             -- load msb & lsb						
			                       reg(15 downto 8) <= reg(15 downto 8);
					when   "0100" => reg <= reg - "0000000000000001";                -- decrement
					when   "1000" => reg <= mul_lsb;                                 -- load multiplication lsb result
					when others   => reg <= reg;
				 end case;
			 else
				 case op is
					when   "0001" => reg(7 downto 0) <= din(7 downto 0);             -- load lsb
										 reg(15 downto 8) <= reg(15 downto 8);
					when   "0010" => reg(15 downto 8) <= din(7 downto 0);            -- load msb
										 reg(7 downto 0) <= reg(7 downto 0);
					when   "0011" => reg <= din;                                     -- load msb & lsb						
					when   "0100" => reg <= reg - "0000000000000001";                -- decrement
					when   "1000" => reg <= mul_lsb;                                 -- load multiplication lsb result
					when others  => reg <= reg;
				 end case;
          end if;			 
        end if;             
      end if;  
  end process;
  dout <= reg;
  
  -- used for MVN/MVP instructions
  process(reg)
  begin
		if reg = "1111111111111111" then
			end_count <= '1';
		else
			end_count <= '0';
		end if;
  end process;
end rtl;


