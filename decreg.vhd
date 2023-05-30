library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- register operation decode
entity decreg is
  port(   r:  in STD_LOGIC_VECTOR(5 downto 0);
          y: out STD_LOGIC_VECTOR(29 downto 0)
      );
end decreg;

architecture comb of decreg is
constant NOP_R: STD_LOGIC_VECTOR(5 downto 0) := "000000";  -- no operation
constant ALL_R: STD_LOGIC_VECTOR(5 downto 0) := "000001";  -- register A load lsb
constant ALM_R: STD_LOGIC_VECTOR(5 downto 0) := "000010";  -- register A load msb
constant A16_R: STD_LOGIC_VECTOR(5 downto 0) := "000011";  -- register A load msb & lsb
constant XLL_R: STD_LOGIC_VECTOR(5 downto 0) := "000100";  -- register X load lsb
constant XLM_R: STD_LOGIC_VECTOR(5 downto 0) := "000101";  -- register X load msb 
constant X16_R: STD_LOGIC_VECTOR(5 downto 0) := "000110";  -- register X load msb & lsb 
constant YLL_R: STD_LOGIC_VECTOR(5 downto 0) := "000111";  -- register Y load lsb
constant YLM_R: STD_LOGIC_VECTOR(5 downto 0) := "001000";  -- register Y load msb
constant Y16_R: STD_LOGIC_VECTOR(5 downto 0) := "001001";  -- register Y load msb & lsb
constant DLL_R: STD_LOGIC_VECTOR(5 downto 0) := "001010";  -- register D load lsb
constant DLM_R: STD_LOGIC_VECTOR(5 downto 0) := "001011";  -- register D load msb
constant D16_R: STD_LOGIC_VECTOR(5 downto 0) := "001100";  -- register D load msb & lsb
constant OLD_R: STD_LOGIC_VECTOR(5 downto 0) := "001101";  -- register O load lsb
constant OMD_R: STD_LOGIC_VECTOR(5 downto 0) := "001110";  -- register O load msb
constant SLD_R: STD_LOGIC_VECTOR(5 downto 0) := "001111";  -- register S load lsb
constant SLM_R: STD_LOGIC_VECTOR(5 downto 0) := "010000";  -- register S load msb
constant S16_R: STD_LOGIC_VECTOR(5 downto 0) := "010001";  -- register S load msb & lsb
constant SUP_R: STD_LOGIC_VECTOR(5 downto 0) := "010010";  -- register S increment by 1
constant SDW_R: STD_LOGIC_VECTOR(5 downto 0) := "010011";  -- register S decrement by 1
constant SAU_R: STD_LOGIC_VECTOR(5 downto 0) := "010100";  -- register A (lsb) load/register S increment by 1
constant SXU_R: STD_LOGIC_VECTOR(5 downto 0) := "010101";  -- register X (lsb) load/register S increment by 1
constant SXM_R: STD_LOGIC_VECTOR(5 downto 0) := "010110";  -- register X (msb) load/register S increment by 1
constant SYU_R: STD_LOGIC_VECTOR(5 downto 0) := "010111";  -- register Y (lsb) load/register S increment by 1
constant SYM_R: STD_LOGIC_VECTOR(5 downto 0) := "011000";  -- register Y (msb) load/register S increment by 1
constant KLD_R: STD_LOGIC_VECTOR(5 downto 0) := "011001";  -- register K (PBR) load
constant BLD_R: STD_LOGIC_VECTOR(5 downto 0) := "011010";  -- register B (DBR) load
constant KCL_R: STD_LOGIC_VECTOR(5 downto 0) := "011011";  -- register K (PBR) clear and register S decrement by 1
constant BCL_R: STD_LOGIC_VECTOR(5 downto 0) := "011100";  -- register B (DBR) clear
constant SKC_R: STD_LOGIC_VECTOR(5 downto 0) := "011101";  -- register B (DBR) clear and register S decrement by 1
constant DEA_R: STD_LOGIC_VECTOR(5 downto 0) := "011110";  -- register A decrement (MVN/MVP)
constant O16_R: STD_LOGIC_VECTOR(5 downto 0) := "011111";  -- register O load msb & lsb
constant OSU_R: STD_LOGIC_VECTOR(5 downto 0) := "100000";  -- register O load lsb/register S increment by 1
constant MVN_R: STD_LOGIC_VECTOR(5 downto 0) := "100001";  -- register XY increment by 1, A decremented by 1
constant MVP_R: STD_LOGIC_VECTOR(5 downto 0) := "100010";  -- register XY decrement by 1, A decremented by 1
constant MUL_R: STD_LOGIC_VECTOR(5 downto 0) := "100011";  -- register A/B load multiplication lsb result, register X load multiplication msb result
constant MUI_R: STD_LOGIC_VECTOR(5 downto 0) := "100100";  -- multiplication init
constant MUS_R: STD_LOGIC_VECTOR(5 downto 0) := "100101";  -- multiplication (unsigned) start
constant MSS_R: STD_LOGIC_VECTOR(5 downto 0) := "100110";  -- multiplication (signed) start
constant WAI_R: STD_LOGIC_VECTOR(5 downto 0) := "100111";  -- WAI set flipflop
constant STP_R: STD_LOGIC_VECTOR(5 downto 0) := "101000";  -- STP set flipflop
constant BLS_R: STD_LOGIC_VECTOR(5 downto 0) := "101001";  -- register B (DBR) load/register S incremented by 1
constant DLS_R: STD_LOGIC_VECTOR(5 downto 0) := "101010";  -- register D load msb & lsb/register S incremented by 1

begin
  process(r)
  begin
    case r is
      when  NOP_R => y <= "000000000000000000000000000000";
      when  ALL_R => y <= "000000000000000000000000000001";
      when  ALM_R => y <= "000000000000000000000000000010";
      when  A16_R => y <= "000000000000000000000000000011";
      when  DEA_R => y <= "000000000000000000000000000100";
      when  XLL_R => y <= "000000000000000000000000001000";
      when  XLM_R => y <= "000000000000000000000000010000";
      when  X16_R => y <= "000000000000000000000000011000";
      when  YLL_R => y <= "000000000000000000000010000000";
      when  YLM_R => y <= "000000000000000000000100000000";
      when  Y16_R => y <= "000000000000000000000110000000";
      when  DLL_R => y <= "000000000000000000100000000000";
      when  DLM_R => y <= "000000000000000001000000000000";
      when  D16_R => y <= "000000000000000001100000000000";
      when  OLD_R => y <= "000000000000000100000000000000";
      when  OMD_R => y <= "000000000000001000000000000000";
      when  SLD_R => y <= "000000000000010000000000000000";
      when  SLM_R => y <= "000000000000100000000000000000";
      when  S16_R => y <= "000000000000110000000000000000";
      when  SUP_R => y <= "000000000001000000000000000000";
      when  SDW_R => y <= "000000000010000000000000000000";
      when  SAU_R => y <= "000000000001000000000000000001";
      when  SXU_R => y <= "000000000001000000000000001000";
      when  SXM_R => y <= "000000000001000000000000010000";
      when  SYU_R => y <= "000000000001000000000010000000";
      when  SYM_R => y <= "000000000001000000000100000000";
      when  KLD_R => y <= "000000000100000000000000000000";
      when  BLD_R => y <= "000000001000000000000000000000";
      when  KCL_R => y <= "000000010010000000000000000000";
      when  BCL_R => y <= "000000100000000000000000000000";
      when  SKC_R => y <= "000000100010000000000000000000";
      when  O16_R => y <= "000000000000000010000000000000";
      when  OSU_R => y <= "000000000001000100000000000000";
		when  MVN_R => y <= "000000000000000000010001000100";
		when  MVP_R => y <= "000000000000000000001000100100";
		when  MUL_R => y <= "000001000000000000000000000000";
		when  MUI_R => y <= "000010000000000000000000000000";
		when  MUS_R => y <= "000100000000000000000000000000";
		when  MSS_R => y <= "001000000000000000000000000000";
		when  WAI_R => y <= "010000000000000000000000000000";
		when  STP_R => y <= "100000000000000000000000000000";
      when  BLS_R => y <= "000000001001000000000000000000";
      when  DLS_R => y <= "000000000001000001100000000000";
      when others => y <= "000000000000000000000000000000";
    end case;
  end process;
end comb;


