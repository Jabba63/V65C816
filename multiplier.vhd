library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 16X16->32 bit multiplier signed/unsigned
entity multiplier is
  port(       clk:   in STD_LOGIC;
              clr:   in STD_LOGIC;
             init:   in STD_LOGIC; 
          start_u:   in STD_LOGIC;
		    start_s:   in STD_LOGIC;	
           mpcand:   in STD_LOGIC_VECTOR(15 downto 0);
		 	  mplier:   in STD_LOGIC_VECTOR(15 downto 0);
			    busy:  out STD_LOGIC;
          res_lsb:  out STD_LOGIC_VECTOR(15 downto 0);
          res_msb:  out STD_LOGIC_VECTOR(15 downto 0);
			   z_flg:  out STD_LOGIC;
				n_flg:  out STD_LOGIC
      );
end multiplier;

architecture rtl of multiplier is
type state_type is (s0, s1, s2, s3, s4);
signal state: state_type;
signal s:          STD_LOGIC;
signal a:          STD_LOGIC_VECTOR(31 downto 0);
signal b:          STD_LOGIC_VECTOR(15 downto 0);
signal accum:      STD_LOGIC_VECTOR(31 downto 0);
signal sign_a:     STD_LOGIC;
signal sign_b:     STD_LOGIC;
signal mpy:        STD_LOGIC_VECTOR(1 downto 0);

begin
  mpy <= start_s & start_u;
  process(clk,clr)
  begin
	if (clr = '1') THEN
	   state <= s0;
   elsif rising_edge(clk) then
    case state is
      -- wait for init
      when s0 =>      
        if clr = '1' or init = '1' then
	        s <= '0';
           a <= "0000000000000000" & mpcand;
			  b <= mplier;
			  accum <= (others => '0');
           state <= s0;
		  else 
			  a <= a;
			  b <= b;
	        accum <= accum;	  
			  sign_a <= sign_a;                                               
			  sign_b <= sign_a;
			  case mpy is
				  when "01" =>   s <= '1';                                     -- start multiply unsigned
									  state <= s1;
				  when "10" =>   s <= '1';                                     -- start multiply signed
									  state <= s2;
				  when others => s <= '0'; 
				                 state <= s0; 							
			  end case;
	     end if;		 
	 
	   -- multiply unsigned
	   when s1 => 
			  sign_a <= sign_a;
			  sign_b <= sign_b;
 			  if b = 0 then                                                   -- if finished
		        accum <= accum;	 
		        s <= '0';
		        state <= s0;
			  else
				  if b(0) = '1' then                                           -- if bit #0 = 1 sum the (left) shifted multiplicand to the accumulator
					  accum <= accum + a;
				  else
			        accum <= accum;	  
				  end if;
			     s <= '1';	  
				  a <= a(30 downto 0) & '0';                                   -- shift left moltiplicand
				  b <= '0' & b(15 downto 1);                                   -- shift right multiplier
				  state <= s1;
			  end if;
			  
	   -- multiply signed
		when s2 =>
			  sign_a <= a(15);                                                -- save sign of factors
			  sign_b <= b(15);
           a <= "00000000000000000" & mpcand(14 downto 0);                 -- reload factors without sign bits
			  b <= '0' & mplier(14 downto 0);
           state <= s3;			  
			  
		when s3 =>
			  sign_a <= sign_a;
			  sign_b <= sign_b;
 			  if b = 0 then                                                   -- if finished
		        accum <= accum;	 
				  if (sign_a = '1' and sign_b = '0') or (sign_a = '0' and sign_b = '1') then  -- if two's complement is needed
		           s <= '1';
		           state <= s4;
				  else
		           s <= '0';
		           state <= s0;
				  end if;
			  else
				  if b(0) = '1' then                                           -- if bit #0 = 1 sum the (left) shifted multiplicand to the accumulator
					  accum <= accum + a;
				  else
			        accum <= accum;	  
				  end if;
			     s <= '1';	  
				  a <= a(30 downto 0) & '0';                                   -- shift left moltiplicand
				  b <= '0' & b(15 downto 1);                                   -- shift right multiplier
				  state <= s3;
			  end if;
		
		when s4 =>
	        accum <= 0 - accum;	                                          -- two's complement
  	        s <= '0';
	        state <= s0;

      -- illegal state covering
      when others =>
				  a <= a;
				  b <= b;
			     sign_a <= sign_a;
			     sign_b <= sign_b;
		        accum <= accum;	  
		        s <= '0';
              state <= s0;
				  
	   end case;  
	 end if;	
  end process;
  res_lsb <= accum(15 downto 0);
  res_msb <= accum(31 downto 16);
  z_flg <= '1' when accum = "00000000000000000000000000000000" else '0';
  n_flg <= accum(31);
  busy <= s;
end rtl;


