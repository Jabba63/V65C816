library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 16 bit two-way multiplexer
entity addrmux is
  port(  sel:  in STD_LOGIC_VECTOR(2 downto 0);
           a:  in STD_LOGIC_VECTOR(23 downto 0);
           b:  in STD_LOGIC_VECTOR(23 downto 0);
			dbr:  in STD_LOGIC_VECTOR(7 downto 0);  
           s:  in STD_LOGIC_VECTOR(15 downto 0);
			 xr:  in STD_LOGIC_VECTOR(15 downto 0);
			 yr:  in STD_LOGIC_VECTOR(15 downto 0); 
           y: out STD_LOGIC_VECTOR(23 downto 0)
      );
end addrmux;

architecture comb of addrmux is
constant ADPC: STD_LOGIC_VECTOR(2 downto 0) := "000";  -- select PC
constant ADMP: STD_LOGIC_VECTOR(2 downto 0) := "001";  -- select MP
constant ADSP: STD_LOGIC_VECTOR(2 downto 0) := "010";  -- select SP
constant ADDI: STD_LOGIC_VECTOR(2 downto 0) := "011";  -- select Direct
constant ADXR: STD_LOGIC_VECTOR(2 downto 0) := "100";  -- select X register
constant ADYR: STD_LOGIC_VECTOR(2 downto 0) := "101";  -- select Y register
constant ADNP: STD_LOGIC_VECTOR(2 downto 0) := "000";  -- no operation (PC)
begin
  process(sel,a,b,s,xr,yr,dbr)
  begin
    case sel is
      when ADPC   => y <= a;                             -- program counter
      when ADMP   => y <= b;                             -- memory data pointer
      when ADSP   => y <= "00000000" & s;                -- stack address space
      when ADDI   => y <= "00000000" & b(15 downto 0);   -- direct address space
		when ADXR   => y <= dbr & xr;                      -- DBR\X register
		when ADYR   => y <= dbr & yr;                      -- DBR\Y register
      when others => y <= a;
    end case;
  end process;    
end comb;


