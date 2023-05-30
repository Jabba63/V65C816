library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- opcode decimal instructions and prefetch prediction logic
entity pre_dec is
  port(    op:  in STD_LOGIC_VECTOR(7 downto 0);
        fetch:  in STD_LOGIC; 
           ei: out STD_LOGIC;
          dec: out STD_LOGIC 
      );      
end pre_dec;

architecture comb of pre_dec is
constant   NOP_OP: STD_LOGIC_VECTOR(7 downto 0) := "11101010"; -- 0xEA NOP
constant   CLC_OP: STD_LOGIC_VECTOR(7 downto 0) := "00011000"; -- 0x18 CLC 0->C 
constant   SEC_OP: STD_LOGIC_VECTOR(7 downto 0) := "00111000"; -- 0x38 SEC 1->C
constant   CLI_OP: STD_LOGIC_VECTOR(7 downto 0) := "01011000"; -- 0x58 CLI 0->I
constant   SEI_OP: STD_LOGIC_VECTOR(7 downto 0) := "01111000"; -- 0x78 SEI 1->I
constant   CLV_OP: STD_LOGIC_VECTOR(7 downto 0) := "10111000"; -- 0xB8 CLV 0->V
constant   CLD_OP: STD_LOGIC_VECTOR(7 downto 0) := "11011000"; -- 0xD8 CLD 0->D
constant   SED_OP: STD_LOGIC_VECTOR(7 downto 0) := "11111000"; -- 0xF8 SED 1->D
constant   TAX_OP: STD_LOGIC_VECTOR(7 downto 0) := "10101010"; -- 0xAA TAX A->X
constant   TAY_OP: STD_LOGIC_VECTOR(7 downto 0) := "10101000"; -- 0xA8 TAY A->Y
constant   TXA_OP: STD_LOGIC_VECTOR(7 downto 0) := "10001010"; -- 0x8A TXA X->A
constant   TYA_OP: STD_LOGIC_VECTOR(7 downto 0) := "10011000"; -- 0x98 TYA Y->A
constant   TXY_OP: STD_LOGIC_VECTOR(7 downto 0) := "10011011"; -- 0x9B TXY X->Y
constant   TYX_OP: STD_LOGIC_VECTOR(7 downto 0) := "10111011"; -- 0xBB TYX Y->X
constant   TXS_OP: STD_LOGIC_VECTOR(7 downto 0) := "10011010"; -- 0x9A TXS X->S
constant   TSX_OP: STD_LOGIC_VECTOR(7 downto 0) := "10111010"; -- 0xBA TSX S->X
constant   TCD_OP: STD_LOGIC_VECTOR(7 downto 0) := "01011011"; -- 0x5B TCD C->D
constant   TDC_OP: STD_LOGIC_VECTOR(7 downto 0) := "01111011"; -- 0x7B TDC D->C
constant   TCS_OP: STD_LOGIC_VECTOR(7 downto 0) := "00011011"; -- 0x1B TCS C->S
constant   TSC_OP: STD_LOGIC_VECTOR(7 downto 0) := "00111011"; -- 0x3B TSC S->C
constant   INX_OP: STD_LOGIC_VECTOR(7 downto 0) := "11101000"; -- 0xE8 INX X +1
constant   DEX_OP: STD_LOGIC_VECTOR(7 downto 0) := "11001010"; -- 0xCA DEX X -1
constant   INY_OP: STD_LOGIC_VECTOR(7 downto 0) := "11001000"; -- 0xC8 INY Y +1
constant   DEY_OP: STD_LOGIC_VECTOR(7 downto 0) := "10001000"; -- 0x88 DEY Y -1
constant   ASL_OP: STD_LOGIC_VECTOR(7 downto 0) := "00001010"; -- 0x0A ASL A  
constant   LSR_OP: STD_LOGIC_VECTOR(7 downto 0) := "01001010"; -- 0x4A LSR A  
constant   ROL_OP: STD_LOGIC_VECTOR(7 downto 0) := "00101010"; -- 0x2A ROL A  
constant   ROR_OP: STD_LOGIC_VECTOR(7 downto 0) := "01101010"; -- 0x6A ROR A  
constant   XCE_OP: STD_LOGIC_VECTOR(7 downto 0) := "11111011"; -- 0xFB XCE E<->C
constant   XBA_OP: STD_LOGIC_VECTOR(7 downto 0) := "11101011"; -- 0xEB XBA (swap A/B)
constant   WDM_OP: STD_LOGIC_VECTOR(7 downto 0) := "01000010"; -- 0x42 WDM
constant  ADC1_OP: STD_LOGIC_VECTOR(7 downto 0) := "01100001"; -- 0x61 ADC ($xx,X)
constant  ADC2_OP: STD_LOGIC_VECTOR(7 downto 0) := "01110001"; -- 0x71 ADC ($xx),Y
constant  ADC3_OP: STD_LOGIC_VECTOR(7 downto 0) := "01100101"; -- 0x65 ADC $xx
constant  ADC4_OP: STD_LOGIC_VECTOR(7 downto 0) := "01110101"; -- 0x75 ADC $xx,X
constant  ADC5_OP: STD_LOGIC_VECTOR(7 downto 0) := "01101001"; -- 0x69 ADC #xx
constant  ADC6_OP: STD_LOGIC_VECTOR(7 downto 0) := "01111001"; -- 0x79 ADC $xxxx,Y
constant  ADC7_OP: STD_LOGIC_VECTOR(7 downto 0) := "01111101"; -- 0x7D ADC $xxxx,X
constant  SBC1_OP: STD_LOGIC_VECTOR(7 downto 0) := "11100001"; -- 0xE1 SBC ($xx,X)
constant  SBC2_OP: STD_LOGIC_VECTOR(7 downto 0) := "11110001"; -- 0xF1 SBC ($xx),Y
constant  SBC3_OP: STD_LOGIC_VECTOR(7 downto 0) := "11100101"; -- 0xE5 SBC $xx
constant  SBC4_OP: STD_LOGIC_VECTOR(7 downto 0) := "11110101"; -- 0xF5 SBC $xx,X
constant  SBC5_OP: STD_LOGIC_VECTOR(7 downto 0) := "11101001"; -- 0xE9 SBC #xx
constant  SBC6_OP: STD_LOGIC_VECTOR(7 downto 0) := "11111001"; -- 0xF9 SBC $xxxx,Y
constant  SBC7_OP: STD_LOGIC_VECTOR(7 downto 0) := "11111101"; -- 0xFD SBC $xxxx,X

signal eoi: STD_LOGIC;
begin
  process(op)
  begin
    case op is
      when NOP_OP  => eoi <= '1';
                      dec <= '0';
      when CLC_OP  => eoi <= '1';
                      dec <= '0';
      when SEC_OP  => eoi <= '1';
                      dec <= '0';
      when CLI_OP  => eoi <= '1';
                      dec <= '0';
      when SEI_OP  => eoi <= '1';
                      dec <= '0';
      when CLV_OP  => eoi <= '1';
                      dec <= '0';
      when CLD_OP  => eoi <= '1';
                      dec <= '0';
      when SED_OP  => eoi <= '1';
                      dec <= '0';
      when TAX_OP  => eoi <= '1';
                      dec <= '0';
      when TAY_OP  => eoi <= '1';
                      dec <= '0';
      when TCD_OP  => eoi <= '1';
                      dec <= '0';
      when TDC_OP  => eoi <= '1';
                      dec <= '0';
      when TXA_OP  => eoi <= '1';
                      dec <= '0';
      when TYA_OP  => eoi <= '1';
                      dec <= '0';
      when TXY_OP  => eoi <= '1';
                      dec <= '0';
      when TYX_OP  => eoi <= '1';
                      dec <= '0';
      when TXS_OP  => eoi <= '1';
                      dec <= '0';
      when TSX_OP  => eoi <= '1';
                      dec <= '0';
      when TCS_OP  => eoi <= '1';
                      dec <= '0';
      when TSC_OP  => eoi <= '1';
                      dec <= '0';
      when INX_OP  => eoi <= '1';
                      dec <= '0';
      when DEX_OP  => eoi <= '1';
                      dec <= '0';
      when INY_OP  => eoi <= '1';
                      dec <= '0';
      when DEY_OP  => eoi <= '1';
                      dec <= '0';
      when ASL_OP  => eoi <= '1';
                      dec <= '0';
      when LSR_OP  => eoi <= '1';
                      dec <= '0';
      when ROL_OP  => eoi <= '1';
                      dec <= '0';
      when ROR_OP  => eoi <= '1';
                      dec <= '0';
      when XCE_OP  => eoi <= '1';
                      dec <= '0';
      when XBA_OP  => eoi <= '1';
                      dec <= '0';
      when WDM_OP  => eoi <= '1';
                      dec <= '0';
      -- ADC/SBC
      when ADC1_OP => eoi <= '0';
                      dec <= '1';               
      when ADC2_OP => eoi <= '0';
                      dec <= '1';               
--      when ADC3_OP => eoi <= '0';
--                      dec <= '1';               
      when ADC4_OP => eoi <= '0';
                      dec <= '1';               
      when ADC5_OP => eoi <= '0';
                      dec <= '1';               
      when ADC6_OP => eoi <= '0';
                      dec <= '1';               
      when ADC7_OP => eoi <= '0';
                      dec <= '1';               
      when SBC1_OP => eoi <= '0';
                      dec <= '1';               
      when SBC2_OP => eoi <= '0';
                      dec <= '1';               
      when SBC3_OP => eoi <= '0';
                      dec <= '1';               
      when SBC4_OP => eoi <= '0';
                      dec <= '1';               
      when SBC5_OP => eoi <= '0';
                      dec <= '1';               
      when SBC6_OP => eoi <= '0';
                      dec <= '1';               
      when SBC7_OP => eoi <= '0';
                      dec <= '1';               
      when others  => eoi <= '0';
                      dec <= '0';
    end case;
  end process; 
  ei <= eoi when fetch = '1' else '0';
end comb;




