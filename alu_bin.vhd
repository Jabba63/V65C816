library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 8/16 bit binary alu
-- Written by Valerio Venturi
entity alu_bin is
  port( alu_byp:  in STD_LOGIC;                      -- ALU bypass (no operation)  
            bcd:  in STD_LOGIC;                      -- BCD mode 
           size:  in STD_LOGIC;                      -- operations size: 1 = 8 bit, 0 = 16 bit
            cin:  in STD_LOGIC;                      -- carry/borrow in
            vin:  in STD_LOGIC;                      -- overflow in
            op1:  in STD_LOGIC_VECTOR(15 downto 0);  -- 16 bit operand #1
            op2:  in STD_LOGIC_VECTOR(15 downto 0);  -- 16 bit operand #2
             fc:  in STD_LOGIC_VECTOR(4 downto 0);   -- function code
             cf: out STD_LOGIC;                      -- carry/borrow out 
             zf: out STD_LOGIC;                      -- zero flag out
             nf: out STD_LOGIC;                      -- negative flag out
             vf: out STD_LOGIC;                      -- overflow flag out
          pc_cf: out STD_LOGIC;                      -- carry/borrow out for PC operation 
           dout: out STD_LOGIC_VECTOR(15 downto 0)   -- 16 bit result out
      );  
end alu_bin;

architecture comb of alu_bin is
-- ALU function codes
constant NOP_A: STD_LOGIC_VECTOR(4 downto 0) := "00000";    -- no operation
constant SUM_A: STD_LOGIC_VECTOR(4 downto 0) := "00001";    -- sum with carry
constant SUB_A: STD_LOGIC_VECTOR(4 downto 0) := "00010";    -- subtract with borrow
constant AND_A: STD_LOGIC_VECTOR(4 downto 0) := "00011";    -- and
constant  OR_A: STD_LOGIC_VECTOR(4 downto 0) := "00100";    -- or
constant XOR_A: STD_LOGIC_VECTOR(4 downto 0) := "00101";    -- xor
constant INC_A: STD_LOGIC_VECTOR(4 downto 0) := "00110";    -- increment by 1
constant DEC_A: STD_LOGIC_VECTOR(4 downto 0) := "00111";    -- decrement by 1
constant SHL_A: STD_LOGIC_VECTOR(4 downto 0) := "01000";    -- shift left
constant SHR_A: STD_LOGIC_VECTOR(4 downto 0) := "01001";    -- shift right
constant ROL_A: STD_LOGIC_VECTOR(4 downto 0) := "01010";    -- rotation left
constant ROR_A: STD_LOGIC_VECTOR(4 downto 0) := "01011";    -- rotation right
constant SWC_A: STD_LOGIC_VECTOR(4 downto 0) := "01100";    -- sum without carry (used for indexing and branches)
constant SWC_N: STD_LOGIC_VECTOR(4 downto 0) := "01100";    -- subtract without borrow (used only by branches with negative offset)
constant BIT_A: STD_LOGIC_VECTOR(4 downto 0) := "01101";    -- bit test (used by BIT opcode)
constant DAA_A: STD_LOGIC_VECTOR(4 downto 0) := "01110";    -- decimal adjustement for BCD sum
constant DAS_A: STD_LOGIC_VECTOR(4 downto 0) := "01111";    -- decimal adjustement for BCD subtract
constant CMP_A: STD_LOGIC_VECTOR(4 downto 0) := "10000";    -- compare
constant TSB_A: STD_LOGIC_VECTOR(4 downto 0) := "10001";    -- test and set bit
constant TRB_A: STD_LOGIC_VECTOR(4 downto 0) := "10010";    -- test and reset bit
constant EXT_A: STD_LOGIC_VECTOR(4 downto 0) := "10011";    -- extend sign
constant NEG_A: STD_LOGIC_VECTOR(4 downto 0) := "10100";    -- negate

signal       c: STD_LOGIC;
signal    pc_c: STD_LOGIC;
signal     v_8: STD_LOGIC;
signal    v_16: STD_LOGIC;
signal   v_flg: STD_LOGIC;
signal  add_op: STD_LOGIC;
signal   bcd_c: STD_LOGIC;
signal   bcd_v: STD_LOGIC;
signal  n_size: STD_LOGIC;
signal bcd_sum: STD_LOGIC_VECTOR(15 downto 0);
signal  n8_op2: STD_LOGIC_VECTOR(7 downto 0);
signal n16_op2: STD_LOGIC_VECTOR(15 downto 0);
signal      y8: STD_LOGIC_VECTOR(8 downto 0);
signal     y16: STD_LOGIC_VECTOR(16 downto 0);
signal       y: STD_LOGIC_VECTOR(15 downto 0);
signal   i_op1: STD_LOGIC_VECTOR(7 downto 0);
signal   i_op2: STD_LOGIC_VECTOR(7 downto 0);


component AddSubBCD is
	port( 
		    A: in std_logic_vector(15 downto 0); 
		    B: in std_logic_vector(15 downto 0); 
		   CI: in std_logic;
		  ADD: in std_logic;
		  BCD: in std_logic; 
		  w16: in std_logic; 
		    S: out std_logic_vector(15 downto 0);
		   CO: out std_logic;
		   VO: out std_logic
    );
end component;

						
begin
n_size <= not size;
u1:AddSubBCD port map(A=>op1,
                      B=>op2,
					       CI=>cin,
						    ADD=>add_op,
						    BCD=>'1',
                      W16=>n_size,
                      S=>bcd_sum,
						    CO=>bcd_c,
						    vO=>bcd_v
					      ); 	
    
  i_op1 <= op1(7 downto 0);
  i_op2 <= op2(7 downto 0);
  n8_op2 <= (not i_op2);  
  n16_op2 <= (not op2);  
  process(size,bcd,alu_byp,fc,i_op1,i_op2,n8_op2,n16_op2,op1,op2,bcd_sum,cin,y16(7))
  begin
    if size = '1' then 
	    -- 8 bit
		 if alu_byp = '1' then
			y8(y8'left) <= '0';
			y8(y8'left-1 downto y8'right) <= i_op1;
         add_op <= '0';
		 else   
			case fc is
			  when SUM_A  =>  
                add_op <= '1';
			       if bcd = '0' then
			                 y8 <= ('0' & i_op1) + ('0' & i_op2) + ("00000000" & cin);       -- ADC with carry in
					 else
					           y8 <= '0' & bcd_sum(7 downto 0);
                end if;					 
			  when SUB_A  => 
                add_op <= '0';
			       if bcd = '0' then
			                 y8 <= ('0' & i_op1) + ('0' & n8_op2) + ("00000000" & cin);      -- SBC with borrow in
				    else
					           y8 <= '0' & bcd_sum(7 downto 0);
                end if;					 
			  when BIT_A  => y8 <= ('0' & i_op1) and ('0' & i_op2);                          -- BIT test
			                 add_op <= '0';
			  when AND_A  => y8 <= ('0' & i_op1) and ('0' & i_op2);                          -- AND
			                 add_op <= '0';
			  when OR_A   => y8 <= ('0' & i_op1)  or ('0' & i_op2);                          -- OR
			                 add_op <= '0';
			  when XOR_A  => y8 <= ('0' & i_op1) xor ('0' & i_op2);                          -- XOR
			                 add_op <= '0';
			  when INC_A  => y8 <= i_op1 + "000000001";                                      -- INC
			                 add_op <= '0';
			  when DEC_A  => y8 <= i_op1 - "000000001";                                      -- DEC
			                 add_op <= '0';
			  when SHL_A  => y8(8 downto 1) <= i_op1; y8(0) <= '0';                          -- ASL
			                 add_op <= '0';
			  when SHR_A  => y8 <= "00" & i_op1(i_op1'left downto i_op1'right+1);            -- LSR
			                 add_op <= '0';
			  when ROL_A  => y8(8 downto 1) <= i_op1; y8(0) <= cin;                          -- ROL
			                 add_op <= '0';
			  when ROR_A  => y8 <= '0' & cin & i_op1(i_op1'left downto i_op1'right+1);       -- ROR
			                 add_op <= '0';
			  when SWC_A  => y8 <= ('0' & i_op1) + ('0' & i_op2);                            -- ADD without carry in
			                 add_op <= '0';
			  when DAA_A  => y8 <= '0' & bcd_sum(7 downto 0);                                -- ADD without carry in (used for DAA decimal adjustement)
			                 add_op <= '0';
			  when DAS_A  => y8 <= '0' & bcd_sum(7 downto 0);                                -- SUB without borrow in (used for DAS decimal adjustement)
			                 add_op <= '1';      
			  when CMP_A  => y8 <= ('1' & i_op1) - ('0' & i_op2);                            -- SBC without borrow in (used for compare)
			                 add_op <= '0';
			  when TSB_A  => y8 <= ('0' & i_op1) or ('0' & i_op2);                           -- TSB
			                 add_op <= '0';
			  when TRB_A  => y8 <= ('0' & not i_op1) and ('0' & i_op2);                      -- TRB
			                 add_op <= '0';
			  when NEG_A  => y8 <= "000000000" - ('0' & i_op1);                              -- NEG
			                 add_op <= '0';
			  when EXT_A  => y8(y8'left) <= '0'; y8(y8'left-1 downto y8'right) <= i_op1;     -- NOP
			                 add_op <= '0';
			  when others => y8(y8'left) <= '0'; y8(y8'left-1 downto y8'right) <= i_op1;     -- NOP
			                 add_op <= '0';
			end case;
		 end if;  
		 y16 <= (others => '0'); 
	 else
	    -- 16 bit
		 if alu_byp = '1' then
			y16(y16'left) <= '0';
			y16(y16'left-1 downto y16'right) <= op1;
         add_op <= '0';
		 else   
			case fc is
			  when SUM_A  =>  
                add_op <= '1';
			       if bcd = '0' then
			                 y16 <= ('0' & op1) + ('0' & op2) + ("0000000000000000" & cin);       -- ADC with carry in
					 else
					           y16 <= '0' & bcd_sum;
                end if;					 
			  when SUB_A  => 
                add_op <= '0';
			       if bcd = '0' then
			                 y16 <= ('0' & op1) + ('0' & n16_op2) + ("0000000000000000" & cin);   -- SBC with borrow in
				    else
					           y16 <= '0' & bcd_sum;
                end if;					 
			  when BIT_A  => y16 <= ('0' & op1) and ('0' & op2);                                  -- BIT test
			                 add_op <= '0';
			  when AND_A  => y16 <= ('0' & op1) and ('0' & op2);                                  -- AND
			                 add_op <= '0';
			  when OR_A   => y16 <= ('0' & op1)  or ('0' & op2);                                  -- OR
			                 add_op <= '0';
			  when XOR_A  => y16 <= ('0' & op1) xor ('0' & op2);                                  -- XOR
			                 add_op <= '0';
			  when INC_A  => y16 <= op1 + "00000000000000001";                                    -- INC
			                 add_op <= '0';
			  when DEC_A  => y16 <= op1 - "00000000000000001";                                    -- DEC
			                 add_op <= '0';
			  when SHL_A  => y16(16 downto 1) <= op1; y16(0) <= '0';                              -- ASL
			                 add_op <= '0';
			  when SHR_A  => y16 <= "00" & op1(op1'left downto op1'right+1);                      -- LSR
			                 add_op <= '0';
			  when ROL_A  => y16(16 downto 1) <= op1; y16(0) <= cin;                              -- ROL
			                 add_op <= '0';
			  when ROR_A  => y16 <= '0' & cin & op1(op1'left downto op1'right+1);                 -- ROR
			                 add_op <= '0';
			  when SWC_A  => y16 <= ('0' & op1) + ('0' & op2);                                    -- ADD without carry in
			                 add_op <= '0';
			  when DAA_A  => y16 <= '0' & bcd_sum;                                                -- ADD without carry in (used for DAA decimal adjustement)
			                 add_op <= '0';      
			  when DAS_A  => y16 <= '0' & bcd_sum;                                                -- SUB without borrow in (used for DAS decimal adjustement)
			                 add_op <= '1';      
			  when CMP_A  => y16 <= ('1' & op1) - ('0' & op2);                                    -- SBC without borrow in (used for compare)
			                 add_op <= '0';
			  when TSB_A  => y16 <= ('0' & op1) or ('0' & op2);                                   -- TSB
			                 add_op <= '0';
			  when TRB_A  => y16 <= ('0' & not op1) and ('0' & op2);                              -- TRB
			                 add_op <= '0';
			  when EXT_A  => if op1(7) = '1' then                                                 -- if negative
			                    y16(16 downto 8) <= "111111111";                                  -- extend sign to msb
									  y16(7 downto 0) <= op1(7 downto 0);
				              else
					              y16(16 downto 8) <= "000000000";
									  y16(7 downto 0) <= op1(7 downto 0);
                          end if;					 
			                 add_op <= '0';
			  when NEG_A  => y16 <= "00000000000000000" - ('0' & op1);                            -- NEG
			                 add_op <= '0';
			  when others => y16(y16'left) <= '0'; y16(y16'left-1 downto y16'right) <= op1;       -- NOP
			                 add_op <= '0';
			end case;
		 end if;   
		 y8 <= (others => '0'); 
	 end if;
  end process;

  

  -- flag "C" carry/borrow logic
  process(size,bcd,bcd_c,fc,op1,y8,y16,cin)
  begin
    if size = '1' then
		 case fc is
			when SUM_A  => 
			            if bcd = '0' then
			               c    <= y8(y8'left);
						   else
					         c    <= bcd_c;
						   end if; 		
								pc_c <= '0';
			when SUB_A  =>
			            if bcd = '0' then
			               c    <= y8(y8'left);
						   else
					         c    <= bcd_c;
						   end if; 		
								pc_c <= '0';
			when SWC_A  => pc_c <= y8(y8'left);
								c    <= cin;
			when SHL_A  => c    <= y8(y8'left);
								pc_c <= '0';
			when SHR_A  => c    <= op1(op1'right);
								pc_c <= '0';
			when ROL_A  => c    <= y8(y8'left);
								pc_c <= '0';
			when ROR_A  => c    <= op1(op1'right);
								pc_c <= '0';
			when DAA_A  => c    <= y8(y8'left);
								pc_c <= '0';
			when DAS_A  => c    <= cin;
								pc_c <= '0';
			when BIT_A  => c    <= cin;
								pc_c <= '0';
			when CMP_A  => c    <= y8(y8'left);
								pc_c <= '0';
			when others => c    <= cin;
								pc_c <= '0';
		 end case;
	 else
		 case fc is
			when SUM_A  => 
			            if bcd = '0' then
			               c    <= y16(y16'left);
						   else
					         c    <= bcd_c;
					      end if;		
								pc_c <= '0';
			when SUB_A  => 
			            if bcd = '0' then
			               c    <= y16(y16'left);
						   else
					         c    <= bcd_c;
					      end if;		
								pc_c <= '0';
			when SWC_A  => pc_c <= y16(8);
								c    <= cin;
			when SHL_A  => c    <= y16(y16'left);
								pc_c <= '0';
			when SHR_A  => c    <= op1(op1'right);
								pc_c <= '0';
			when ROL_A  => c    <= y16(y16'left);
								pc_c <= '0';
			when ROR_A  => c    <= op1(op1'right);
								pc_c <= '0';
			when DAA_A  => c    <= y16(y16'left);
								pc_c <= '0';
			when DAS_A  => c    <= cin;
								pc_c <= '0';
			when BIT_A  => c    <= cin;
								pc_c <= '0';
			when CMP_A  => c    <= y16(y16'left);
								pc_c <= '0';
			when others => c    <= cin;
								pc_c <= '0';
		 end case;
	 end if;
  end process;  

  -- flag "V" overflow logic
  v_8  <= not (((op1(7) nor op2(7)) and y8(6)) nor ((op1(7) nand op2(7)) nor y8(6)));
  v_16 <= not (((op1(15) nor op2(15)) and y16(14)) nor ((op1(15) nand op2(15)) nor y16(14)));
  v_flg <= v_8 when size = '1' else v_16;
  process(size,fc,bcd,i_op2,op2,v_flg,bcd_v,vin)
  begin
    case fc is
      when SUM_A  => 
							if bcd = '0' then
											vf <= v_flg;
							else
											vf <= bcd_v;
							end if;					
      when SUB_A  =>
							if bcd = '0' then
											vf <= v_flg;
							else
											vf <= bcd_v;
							end if;					
      when BIT_A  =>  
                     if size = '1' then		
		                           vf <= op2(6);
							else
			                        vf <= op2(14);
							end if;				
      when others =>             vf <= vin;
    end case;
  end process;  

  -- flag "N" negative result logic
  process(size,fc,i_op2,y8,y16)
  begin
    if size = '1' then
		 case fc is
			when BIT_A  => nf <= i_op2(i_op2'left);
			when others => nf <= y8(y8'left-1);
		 end case;
	 else
		 case fc is
			when BIT_A  => nf <= i_op2(i_op2'left);
			when others => nf <= y16(y16'left-1);
		 end case;
	 end if;
  end process;  

  -- flag "Z" zero result logic (always set with zero results)
  process(size,y8,y16) 
  begin
    if size = '1' then
	    if y8(y8'left-1 downto y8'right) = "00000000" then
          zf <= '1';
		 else
          zf <= '0';
	    end if;		 
    else
	    if y16(y16'left-1 downto y16'right) = "0000000000000000" then
          zf <= '1';
		 else
          zf <= '0';
	    end if;		 
    end if;	 
  end process;

  y <= op1(15 downto 8) & y8(y8'left-1 downto y8'right) when size = '1' else y16(y16'left-1 downto y16'right);    


  cf <= c;  
  pc_cf <= pc_c;
  dout <= y;
end comb;
