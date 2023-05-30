library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 8 bit three-way multiplexer
entity data_mux is
  port(    s:  in STD_LOGIC_VECTOR(3 downto 0);
           a:  in STD_LOGIC_VECTOR(7 downto 0);
           b:  in STD_LOGIC_VECTOR(7 downto 0);
           c:  in STD_LOGIC_VECTOR(7 downto 0);
           d:  in STD_LOGIC_VECTOR(7 downto 0);
           y: out STD_LOGIC_VECTOR(7 downto 0)
      );
end data_mux;

architecture comb of data_mux is

begin
  process(s,a,b,c,d)
  begin
    case s is
      when "1110"  => y <= a;
      when "1101"  => y <= b;
      when "1011"  => y <= c;
      when "0111"  => y <= d;
      when others  => y <= a;
    end case;
  end process;    
end comb;


