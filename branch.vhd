library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- branch resolving logic
entity branch is
  port(   op:  in STD_LOGIC_VECTOR(3 downto 0);
           n:  in STD_LOGIC;
           v:  in STD_LOGIC;
           z:  in STD_LOGIC;
           c:  in STD_LOGIC;
        bres: out STD_LOGIC
      );        
end branch;

architecture comb of branch is
begin
  process(op,n,v,z,c)
  begin
    case op is
      when "1000" => bres <= '1';    -- BRA
      when "0001" => bres <= not n;  -- BPL
      when "0011" => bres <= n;      -- BMI
      when "0101" => bres <= not v;  -- BVC
      when "0111" => bres <= v;      -- BVS
      when "1111" => bres <= z;      -- BEQ
      when "1101" => bres <= not z;  -- BNE
      when "1001" => bres <= not c;  -- BCC
      when "1011" => bres <= c;      -- BCS
      when others => bres <= '0';
    end case;
  end process;
end comb;


