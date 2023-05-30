library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 8/16 bit stack pointer register "S"
entity spr is
  port(   clk:  in STD_LOGIC;
          clr:  in STD_LOGIC;
        fwait:  in STD_LOGIC; 
		     em:  in STD_LOGIC;
         ld_l:  in STD_LOGIC;
         ld_h:  in STD_LOGIC;
            u:  in STD_LOGIC; 
            d:  in STD_LOGIC; 
          din:  in STD_LOGIC_VECTOR(15 downto 0);
         dout: out STD_LOGIC_VECTOR(15 downto 0)
      );
end spr;

architecture rtl of spr is
constant SP_6502_VALUE:    STD_LOGIC_VECTOR(15 downto 0)  := "0000000111111111"; -- $01FF standard 6502 stack pointer
signal   x: STD_LOGIC_VECTOR(3 downto 0);
signal reg: STD_LOGIC_VECTOR(15 downto 0);

begin
  x(0) <= ld_l;
  x(1) <= ld_h;
  x(2) <= u;
  x(3) <= d;
  process(clk)
    begin
      if (clk'event and clk = '1') then
        if fwait = '1' then
          reg <= reg;
        else  
          if clr = '1' then
            reg <= SP_6502_VALUE;
          else
			   if em = '0' then                                                -- native mode (S full 16 bit) 
					case x is
					  when "0001"  => reg(7 downto 0)  <= din(7 downto 0);
											reg(15 downto 8) <= reg(15 downto 8); 
					  when "0010"  => reg(15 downto 8) <= din(7 downto 0);
											reg(7 downto 0)  <= reg(7 downto 0); 
					  when "0011"  => reg <= din; 						
					  when "0100"  => reg <= reg + 1;
					  when "1000"  => reg <= reg - 1;
					  when others  => reg <= reg;
					end case;
				else                                                            -- emulation mode (S is forced to 0x01XX)
					case x is
					  when "0001"  => reg(7 downto 0) <= din(7 downto 0);
					  when "0011"  => reg(7 downto 0) <= din(7 downto 0);
					  when "0100"  => reg(7 downto 0) <= reg(7 downto 0) + 1;
					  when "1000"  => reg(7 downto 0) <= reg(7 downto 0) - 1;
					  when others  => reg(7 downto 0) <= reg(7 downto 0);
					end case;
				   reg(15 downto 8) <= SP_6502_VALUE(15 downto 8);
				end if;
          end if;  
        end if;   
      end if;  
  end process;
  dout <= reg;
end rtl;


