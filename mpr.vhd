library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 16 bit memory pointer address register 
entity mpr is
  port(   clk:  in STD_LOGIC;
        fwait:  in STD_LOGIC;
       dbr_ld:  in STD_LOGIC;
		      c:  in STD_LOGIC;
           fc:  in STD_LOGIC_VECTOR(4 downto 0);
        din_l:  in STD_LOGIC_VECTOR(7 downto 0);  
        din_h:  in STD_LOGIC_VECTOR(7 downto 0);  
          dbr:  in STD_LOGIC_VECTOR(7 downto 0);  
           dr:  in STD_LOGIC_VECTOR(15 downto 0);  
			  op:  in STD_LOGIC_VECTOR(15 downto 0);
			  xr:  in STD_LOGIC_VECTOR(15 downto 0);
			  yr:  in STD_LOGIC_VECTOR(15 downto 0);
			  sr:  in STD_LOGIC_VECTOR(15 downto 0);
            v:  in STD_LOGIC_VECTOR(7 downto 0);
         dout: out STD_LOGIC_VECTOR(23 downto 0)
      );
end mpr;

architecture rtl of mpr is
constant NOP_M: STD_LOGIC_VECTOR(4 downto 0) := "00000"; -- no operation
constant LSB_M: STD_LOGIC_VECTOR(4 downto 0) := "00001"; -- load lsb
constant MSB_M: STD_LOGIC_VECTOR(4 downto 0) := "00010"; -- load msb
constant INC_M: STD_LOGIC_VECTOR(4 downto 0) := "00011"; -- increment 
constant DEC_M: STD_LOGIC_VECTOR(4 downto 0) := "00100"; -- decrement
constant VEC_M: STD_LOGIC_VECTOR(4 downto 0) := "00101"; -- load vector
constant ZPL_M: STD_LOGIC_VECTOR(4 downto 0) := "00110"; -- load ZEROPAGE
constant ALL_M: STD_LOGIC_VECTOR(4 downto 0) := "00111"; -- load all 16 bit register
constant ICC_M: STD_LOGIC_VECTOR(4 downto 0) := "01000"; -- increment MSB with carry
constant DOX_M: STD_LOGIC_VECTOR(4 downto 0) := "01001"; -- add D + offset + X
constant DOY_M: STD_LOGIC_VECTOR(4 downto 0) := "01010"; -- add D + offset + Y
constant AOS_M: STD_LOGIC_VECTOR(4 downto 0) := "01011"; -- add S + offset
constant ABX_M: STD_LOGIC_VECTOR(4 downto 0) := "01100"; -- add opr+X
constant ABY_M: STD_LOGIC_VECTOR(4 downto 0) := "01101"; -- add opr+Y
constant ADX_M: STD_LOGIC_VECTOR(4 downto 0) := "01110"; -- add X
constant ADY_M: STD_LOGIC_VECTOR(4 downto 0) := "01111"; -- add Y
constant MHB_M: STD_LOGIC_VECTOR(4 downto 0) := "10000"; -- load high byte 
constant AOY_M: STD_LOGIC_VECTOR(4 downto 0) := "10001"; -- add opr+Y and concatenates SBR

signal reg: STD_LOGIC_VECTOR(23 downto 0);
begin
  process(clk)
  begin
    if (clk'event and clk = '1') then
      if fwait = '1' then
        reg <= reg;
      else  
		  if dbr_ld = '1' then           -- on every opcode fetch the high byte of MPR is loaded with DBR value                                                                                                     
           reg(23 downto 16) <= dbr;
        end if;		  
        case fc is
          when LSB_M  => reg(7 downto 0)  <= din_l; reg(23 downto 8) <= reg(23 downto 8);                                            -- load LSB (bit 7..0)
          when MSB_M  => reg(15 downto 8) <= din_h; reg(7 downto 0) <= reg(7 downto 0); reg(23 downto 16) <= reg(23 downto 16);      -- load MSB (bit 15..8)
          when ALL_M  => reg(15 downto 8) <= din_h; reg(7 downto 0) <= din_l; reg(23 downto 16) <= reg(23 downto 16);                -- load LSB/MSB (bit 15..0)
          when INC_M  => reg <= reg +1;                                                                                              -- increment 24 bit
          when DEC_M  => reg <= reg -1;                                                                                              -- decrement 24 bit
          when VEC_M  => reg <= "0000000011111111" & v;                                                                              -- 0x00FFXX load vector
          when ZPL_M  => reg(15 downto 0) <= dr + ("00000000" & din_l);                                                              -- 0x00XXXX zeropage operation (D + 0x0000XX)
          when ICC_M  => reg(15 downto 8) <= reg(15 downto 8) + c;                                                                   -- increment MSB for indexed addressing mode
			 when DOX_M  => reg(15 downto 0) <= dr + ("00000000" & din_l) + xr;                                                         -- D+offset+X
			 when DOY_M  => reg(15 downto 0) <= dr + ("00000000" & din_l) + yr;                                                         -- D+offset+Y
			 when AOS_M  => reg(15 downto 0) <= sr + ("00000000" & din_h); reg(23 downto 16) <= "00000000";                             -- S+offset
			 when ABX_M  => reg(15 downto 0) <= din_h & op(7 downto 0) + xr;                                                            -- +O+X
			 when ABY_M  => reg(15 downto 0) <= din_h & op(7 downto 0) + yr;                                                            -- +O+Y
			 when ADX_M  => reg <= reg + ("00000000" & xr);                                                                             -- +X (24 bit SUM)
			 when ADY_M  => reg <= reg + ("00000000" & yr);                                                                             -- +Y (24 bit SUM)
          when MHB_M  => reg(23 downto 16) <= din_h; reg(15 downto 0) <= op;                                                         -- load high byte (bit 23..16)
			 when AOY_M  => reg <= (dbr & op) + ("00000000" & yr);                                                                      -- O+Y (24 bit SUM)
          when others => reg <= reg;
        end case;
      end if;  
    end if;  
  end process;
  dout <= reg;
end rtl;


