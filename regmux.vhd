library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- 8 bit seven-way multiplexer
entity regmux is
  port(  sel:  in STD_LOGIC_VECTOR(4 downto 0);
           a:  in STD_LOGIC_VECTOR(7 downto 0);
           b:  in STD_LOGIC_VECTOR(15 downto 0);
           c:  in STD_LOGIC_VECTOR(15 downto 0);
           d:  in STD_LOGIC_VECTOR(15 downto 0);
           e:  in STD_LOGIC_VECTOR(15 downto 0);
           g:  in STD_LOGIC_VECTOR(7 downto 0);
           h:  in STD_LOGIC_VECTOR(7 downto 0);
           i:  in STD_LOGIC_VECTOR(7 downto 0);
           j:  in STD_LOGIC_VECTOR(15 downto 0);
           k:  in STD_LOGIC_VECTOR(15 downto 0);
			  l:  in STD_LOGIC_VECTOR(7 downto 0);
			  m:  in STD_LOGIC_VECTOR(7 downto 0);
           y: out STD_LOGIC_VECTOR(15 downto 0)
      );
end regmux;

architecture comb of regmux is
constant EXT_O: STD_LOGIC_VECTOR(4 downto 0) := "00000";  -- external data bus
constant ARD_O: STD_LOGIC_VECTOR(4 downto 0) := "00001";  -- register C msb & lsb select
constant ARM_O: STD_LOGIC_VECTOR(4 downto 0) := "00010";  -- register C msb select (also returns C swapped)
constant XRD_O: STD_LOGIC_VECTOR(4 downto 0) := "00011";  -- register X msb & lsb select
constant XRM_O: STD_LOGIC_VECTOR(4 downto 0) := "00100";  -- register X msb select
constant YRD_O: STD_LOGIC_VECTOR(4 downto 0) := "00101";  -- register Y msb & lsb select
constant YRM_O: STD_LOGIC_VECTOR(4 downto 0) := "00110";  -- register Y msb select
constant SRD_O: STD_LOGIC_VECTOR(4 downto 0) := "00111";  -- register S lsb select
constant PRD_O: STD_LOGIC_VECTOR(4 downto 0) := "01000";  -- register P select
constant PLR_O: STD_LOGIC_VECTOR(4 downto 0) := "01001";  -- register PCL select
constant PHR_O: STD_LOGIC_VECTOR(4 downto 0) := "01010";  -- register PCH select
constant ORD_O: STD_LOGIC_VECTOR(4 downto 0) := "01011";  -- register O msb & lsb select 
constant Z00_O: STD_LOGIC_VECTOR(4 downto 0) := "01100";  -- select (all zero output)
constant DRD_O: STD_LOGIC_VECTOR(4 downto 0) := "01101";  -- register D msb & lsb select
constant DRM_O: STD_LOGIC_VECTOR(4 downto 0) := "01110";  -- register D msb select
constant KRD_O: STD_LOGIC_VECTOR(4 downto 0) := "01111";  -- register K PBR
constant BRD_O: STD_LOGIC_VECTOR(4 downto 0) := "10000";  -- register B PBR
constant EXM_O: STD_LOGIC_VECTOR(4 downto 0) := "10001";  -- external data bus on MSB, O on lsb
constant OMD_O: STD_LOGIC_VECTOR(4 downto 0) := "10010";  -- register O msb select 
constant PCR_O: STD_LOGIC_VECTOR(4 downto 0) := "10011";  -- register PC (16 bit) select

begin
  process(sel,a,b,c,d,e,g,h,i,j,k,l,m)
  begin 
    case sel is
      when EXT_O  => y(7 downto 0) <= a;
		               y(15 downto 8) <= (others => '0');
      when EXM_O  => y(15 downto 8) <= a;
		               y(7 downto 0) <= j(7 downto 0);
      when ARD_O  => y <= b;
		when ARM_O  => y(7 downto 0) <= b(15 downto 8);
		               y(15 downto 8) <= b(7 downto 0); 
      when XRD_O  => y <= c;
		when XRM_O  => y(7 downto 0) <= c(15 downto 8);
		               y(15 downto 8) <= (others => '0'); 
      when YRD_O  => y <= d;
		when YRM_O  => y(7 downto 0) <= d(15 downto 8);
		               y(15 downto 8) <= (others => '0'); 
      when SRD_O  => y <= e;
      when PRD_O  => y(7 downto 0) <= g;
		               y(15 downto 8) <= (others => '0');
      when PLR_O  => y(7 downto 0) <= h;
		               y(15 downto 8) <= (others => '0');
      when PHR_O  => y(7 downto 0) <= i;
		               y(15 downto 8) <= (others => '0');
      when ORD_O  => y <= j;
      when Z00_O  => y <= (others => '0');
      when DRD_O  => y <= k;
		when DRM_O  => y(7 downto 0) <= k(15 downto 8);
		               y(15 downto 8) <= (others => '0'); 
      when KRD_O  => y(7 downto 0) <= l;
		               y(15 downto 8) <= (others => '0');
      when BRD_O  => y(7 downto 0) <= m;
		               y(15 downto 8) <= (others => '0');
      when OMD_O  => y(7 downto 0) <= j(15 downto 8);
		               y(15 downto 8) <= (others => '0');
		when PCR_O  => y(7 downto 0) <= h; 					
		               y(15 downto 8) <= i;
      when others => y(7 downto 0) <= a;
		               y(15 downto 8) <= (others => '0');
    end case;
  end process;  
end comb;


