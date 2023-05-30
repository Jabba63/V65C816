library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 16 bit index register "X"
entity xr is
  port(       clk:  in STD_LOGIC;
            fwait:  in STD_LOGIC;
		       size:  in STD_LOGIC;	
           ld_lsb:  in STD_LOGIC;
           ld_msb:  in STD_LOGIC;
	    ld_mul_msb:  in STD_LOGIC;
	             u:  in STD_LOGIC;
		          d:  in STD_LOGIC;
              din:  in STD_LOGIC_VECTOR(15 downto 0);
			 mul_msb:  in STD_LOGIC_VECTOR(15 downto 0); 	  
             dout: out STD_LOGIC_VECTOR(15 downto 0)
      );
end xr;

architecture rtl of xr is
signal reg: STD_LOGIC_VECTOR(15 downto 0);
signal op:  STD_LOGIC_VECTOR(4 downto 0);
begin
  op <= ld_mul_msb & u & d & ld_msb & ld_lsb;
  process(clk)
    begin
      if (clk'event and clk = '1') then
        if fwait = '1' then
          reg <= reg;
        else  
				 case op is
					when   "00001" => reg(7 downto 0) <= din(7 downto 0);              -- load lsb
								   		reg(15 downto 8) <= reg(15 downto 8);
					when   "00010" => reg(15 downto 8) <= din(7 downto 0);             -- load msb
								   		reg(7 downto 0) <= reg(7 downto 0);
					when   "00011" => reg <= din;                                      -- load msb & lsb						
					when   "00100" => reg <= reg - "0000000000000001";                 -- decrement
					when   "01000" => reg <= reg + "0000000000000001";                 -- increment
					when   "10000" => reg <= mul_msb;                                  -- load multiplication msb result
					when others    => reg <= reg;
				 end case;
				 if size = '1' then
				   reg(15 downto 8) <= (others => '0');                               -- with size = '1' (X = '1') the msb of index register is always zero
				 end if;	 
		  end if;
      end if;  
  end process;
  dout <= reg;
end rtl;


