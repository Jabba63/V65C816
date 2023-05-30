library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 8/16 bit three-way multiplexer
-- this multiplexer select the operand source for ALU operand #2 (op2) input
entity dmux is
  port(  sel:  in STD_LOGIC_VECTOR(2 downto 0);
           a:  in STD_LOGIC_VECTOR(15 downto 0);
           b:  in STD_LOGIC_VECTOR(7 downto 0);
           y: out STD_LOGIC_VECTOR(15 downto 0)
      );
end dmux;

architecture comb of dmux is
constant NOP_D: STD_LOGIC_VECTOR(2 downto 0) := "000";
constant ORD_D: STD_LOGIC_VECTOR(2 downto 0) := "001";           -- selects 16 bit operand register 
constant EXT_D: STD_LOGIC_VECTOR(2 downto 0) := "010";           -- selects 8 bit external data bus
constant EXM_D: STD_LOGIC_VECTOR(2 downto 0) := "011";           -- selects msb 8 bit external data bus and lsb operand register  
constant BCD_D: STD_LOGIC_VECTOR(2 downto 0) := "100";           -- not used

begin
  process(sel,a,b)
  begin 
    case sel is
      when ORD_D    => y <= a;                                   -- selects 16 bit operand register
      when EXT_D    => y <= "00000000" & b;                      -- selects 8 bit external data bus
      when EXM_D    => y <= b & a(7 downto 0);                   -- selects msb 8 bit external data bus and lsb operand register
      when others   => y <= "0000000000000000";
    end case;
  end process;  
end comb;


