library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 8 bit processor status register P
-- NV1BDIZC    
-- 76543210
-- ||||||||
-- ||||||||--- C/E = carry/borrow flag (emulation bit: 1 = emulation mode, 0 = native mode)
-- |||||||---- Z = zero flag
-- ||||||----- I = interrupt mask
-- |||||------ D = decimal/binary alu mode
-- ||||------- B/X = index reg. select (1 = 8 bit, 0 = 16 bit) (B Break: 0 on stack after interrupt if E emulation mode = 1)
-- |||-------- M = memory/acc. select (1 = 8 bit, 0 = 16 bit) (always 1 if E = 1) 
-- ||--------- V = overflow flag
-- |---------- N = negative flag
entity pr is
  port(      clk:  in STD_LOGIC;                        -- clock
             clr:  in STD_LOGIC;                        -- clear
           fwait:  in STD_LOGIC; 
               n:  in STD_LOGIC;                        -- N input
               v:  in STD_LOGIC;                        -- V input
               z:  in STD_LOGIC;                        -- Z input
               c:  in STD_LOGIC;                        -- C input
		     mpy_z:  in STD_LOGIC;                        -- Z input from multiplier			
		     mpy_n:  in STD_LOGIC;                        -- N input from multiplier			
             swi:  in STD_LOGIC;                        -- software interrupt (BRK/COP opcode flag)
          acr_in:  in STD_LOGIC;                        -- auxiliary carry in   
              fc:  in STD_LOGIC_VECTOR(4 downto 0);     -- function code 
             din:  in STD_LOGIC_VECTOR(7 downto 0);     -- input
            dout: out STD_LOGIC_VECTOR(7 downto 0);     -- output
         acr_out: out STD_LOGIC;                        -- auxiliary carry out   
			     em: out STD_LOGIC;                        -- emulation (1)/native mode (0)
			 two_op: out STD_LOGIC                         -- two byte instruction	  
      );        
end pr;

architecture rtl of pr is
constant NOP_P: STD_LOGIC_VECTOR(4 downto 0) := "00000"; -- PR no operation
constant PLD_P: STD_LOGIC_VECTOR(4 downto 0) := "00001"; -- PR load
constant FLD_P: STD_LOGIC_VECTOR(4 downto 0) := "00010"; -- NZ load
constant FLC_P: STD_LOGIC_VECTOR(4 downto 0) := "00011"; -- NZC load
constant FLV_P: STD_LOGIC_VECTOR(4 downto 0) := "00100"; -- NVZC load
constant SEC_P: STD_LOGIC_VECTOR(4 downto 0) := "00101"; -- 1 => C 
constant CLC_P: STD_LOGIC_VECTOR(4 downto 0) := "00110"; -- 0 => C 
constant SEI_P: STD_LOGIC_VECTOR(4 downto 0) := "00111"; -- 1 => I 
constant CLI_P: STD_LOGIC_VECTOR(4 downto 0) := "01000"; -- 0 => I 
constant SED_P: STD_LOGIC_VECTOR(4 downto 0) := "01001"; -- 1 => D 
constant CLD_P: STD_LOGIC_VECTOR(4 downto 0) := "01010"; -- 0 => D 
constant CLV_P: STD_LOGIC_VECTOR(4 downto 0) := "01011"; -- 0 => V 
constant AUC_P: STD_LOGIC_VECTOR(4 downto 0) := "01100"; -- auc => ACR 
constant HAC_P: STD_LOGIC_VECTOR(4 downto 0) := "01101"; -- hold ACR 
constant SID_P: STD_LOGIC_VECTOR(4 downto 0) := "01110"; -- 1 => I/D 
constant LDZ_P: STD_LOGIC_VECTOR(4 downto 0) := "01111"; -- Z load
constant XCE_P: STD_LOGIC_VECTOR(4 downto 0) := "10000"; -- E => C; C => E
constant SEP_P: STD_LOGIC_VECTOR(4 downto 0) := "10001"; -- P = P OR din
constant REP_P: STD_LOGIC_VECTOR(4 downto 0) := "10010"; -- P = P AND not din
constant WDM_P: STD_LOGIC_VECTOR(4 downto 0) := "10011"; -- 1 => op_exp;
constant WDC_P: STD_LOGIC_VECTOR(4 downto 0) := "10100"; -- 0 => op_exp;
constant FLW_P: STD_LOGIC_VECTOR(4 downto 0) := "10101"; -- NZ load, 0 -> op_exp
constant MUF_P: STD_LOGIC_VECTOR(4 downto 0) := "10110"; -- Z load from unsigned multplier
constant MSF_P: STD_LOGIC_VECTOR(4 downto 0) := "10111"; -- NZ load from unsigned multplier

signal    reg: STD_LOGIC_VECTOR(7 downto 0);
signal    acr: STD_LOGIC;                                                      -- carry/borrow used for effective address calculation 
signal     eb: STD_LOGIC;                                                      -- emulation/native bit
signal op_exp: STD_LOGIC;                                                      -- two opcode bit
signal  swint: STD_LOGIC;                                                      -- bit 4 saved on stack when BRK/COP

begin
  process(clk)
    begin
      if (clk'event and clk = '1') then
        if fwait = '1' then
          reg <= reg;
        else
          if clr = '1' then
            reg <= "00110100";                                                 -- on reset M,X,I = '1'
            acr <= '0';
				eb <= '1';                                                         -- on reset set emulation mode
				op_exp <= '0';
          else
            case fc is
              when PLD_P  => reg    <= din;                                    -- load NVMXDIZC 
                             acr    <= '0';   
									  eb     <= eb;
									  op_exp <= op_exp;
              when FLD_P  => reg    <= n & reg(6 downto 2) & z & reg(0);       -- load NZ
                             acr    <= '0';   
									  eb     <= eb;
									  op_exp <= op_exp;
              when FLC_P  => reg    <= n & reg(6 downto 2) & z & c;            -- load NZC
                             acr    <= '0';   
									  eb     <= eb;
									  op_exp <= op_exp;
              when FLV_P  => reg <= n & v & reg(5 downto 2) & z & c;           -- load NVZC
                             acr <= '0';   
              when SEC_P  => reg    <= reg or  "00000001";                     -- 1 => C
                             acr    <= acr;   
									  eb     <= eb;
									  op_exp <= op_exp;
              when CLC_P  => reg    <= reg and "11111110";                     -- 0 => C
                             acr    <= acr;   
									  eb     <= eb;
									  op_exp <= op_exp;
              when CLI_P  => reg    <= reg and "11111011";                     -- 0 => I
                             acr    <= acr;   
									  eb     <= eb;
									  op_exp <= op_exp;
              when SED_P  => reg    <= reg or  "00001000";                     -- 1 => D
                             acr    <= acr;   
									  eb     <= eb;
									  op_exp <= op_exp;
              when CLD_P  => reg    <= reg and "11110111";                     -- 0 => D
                             acr    <= acr;   
									  eb     <= eb;
									  op_exp <= op_exp;
				  when LDZ_P  => reg(1) <= z;                                      -- z => Z
                             reg(7 downto 2) <= reg(7 downto 2);
			                    reg(0) <= reg(0);						  
									  eb     <= eb;
									  op_exp <= op_exp;
              when SEI_P  => reg(7 downto 3) <= reg(7 downto 3); 
                             reg(2) <= '1';                                    -- 1 => I
                             reg(1 downto 0) <= reg(1 downto 0);           
                             acr    <= acr;   
									  eb     <= eb;
									  op_exp <= op_exp;
              when SID_P  => reg(7 downto 4) <= reg(7 downto 4);               -- set I and clear D decimal flag (used by interrupt sequence)
                             reg(3) <= '0';                                    -- 0 -> D                                 
                             reg(2) <= '1';                                    -- 1 => I
                             reg(1 downto 0) <= reg(1 downto 0);           
                             acr    <= acr;   
									  eb     <= eb;
									  op_exp <= op_exp;
              when CLV_P  => reg    <= reg and "10111111";                     -- 0 => V
                             acr    <= acr;   
									  eb     <= eb;
									  op_exp <= op_exp;
              when AUC_P  => acr    <= acr_in;                                 -- store auxiliary carry (ACR)
                             reg    <= reg;               
									  eb     <= eb;
									  op_exp <= op_exp;
              when HAC_P  => acr    <= acr;                                    -- holds auxiliary carry (ACR)
                             reg    <= reg;               
									  eb     <= eb;
									  op_exp <= op_exp;
              when XCE_P  => eb     <= reg(0);                                 -- exchange C <=> E (switch emulation/native mode)
                             reg(0) <= eb;               
                             reg(7 downto 1) <= reg(7 downto 1);               
                             acr    <= '0';
									  op_exp <= op_exp;
				  when SEP_P  => reg    <= reg or din;                             -- SEP
                             acr    <= '0';
									  eb     <= eb;
									  op_exp <= op_exp;
				  when REP_P  => reg    <= reg and (not din);                      -- REP
                             acr    <= '0';
									  eb     <= eb;
									  op_exp <= op_exp;
				  when WDM_P  => op_exp <= '1';                                    -- set two byte opcode
                             reg    <= reg;               
                             acr    <= '0';
									  eb     <= eb;
				  when WDC_P  => op_exp <= '0';                                    -- clear two byte opcode
                             reg    <= reg;               
                             acr    <= '0';
									  eb     <= eb;
              when FLW_P  => reg    <= n & reg(6 downto 2) & z & reg(0);       -- load NZ, 0 => op_exp
                             acr    <= '0';   
									  eb     <= eb;
									  op_exp <= '0';
              when MUF_P  => reg    <= "00" & reg(5 downto 2) & mpy_z & '0';    -- load Z from multiplier, C/VN=0
                             acr    <= '0';   
									  eb     <= eb;
									  op_exp <= op_exp;
              when MSF_P  => reg    <= mpy_n & '0' & reg(5 downto 2) & mpy_z & '0';  -- load NZ from multiplier, CV=0
                             acr    <= '0';   
									  eb     <= eb;
									  op_exp <= op_exp;
              when others => reg    <= reg;                             
                             acr    <= '0';
									  eb     <= eb;
									  op_exp <= op_exp;
            end case;
				if eb = '1' then                                                   -- in emulation mode M/X are always set to '1'
				   reg(5 downto 4) <= "11";
				end if;	
          end if;    
        end if;
      end if;  
  end process;
  
  process(fc,reg(4),eb,swi)
  begin
    if fc = SID_P then
	    if eb = '0' then
		    swint <= reg(4);
		 else
	       swint <= swi;                                                        -- when emulation mode is set the bit 4 reflects BRK opcode (pushed on stack)
	    end if;
	 else
       swint <= reg(4);	 
    end if;		 
  end process;
  
  dout(7 downto 5) <= reg(7 downto 5);
  dout(4) <= swint;                                                            -- save BRK/COP B="1" on stack if emulation mode
  dout(3 downto 0) <= reg(3 downto 0);
  acr_out <= acr;
  em <= eb;
  two_op <= op_exp;
end rtl;


