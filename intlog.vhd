library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- interrupt request logic
entity intlog is
  port(    clk:  in STD_LOGIC;
          iack:  in STD_LOGIC;                    -- interrupt acknowledge by microcode 
             r:  in STD_LOGIC;                    -- RESET request
             n:  in STD_LOGIC;                    -- NMI request
             i:  in STD_LOGIC;                    -- IRQ request
           brk:  in STD_LOGIC;                    -- BRK opcode
			  cop:  in STD_LOGIC;                    -- COP opcode
			    e:  in STD_LOGIC;                    -- native\emulation mode
			gmask:  in STD_LOGIC;                    -- global interrupt mask valid for IRQ and NMI (used by two byte instruction)	 
         imask:  in STD_LOGIC;                    -- interrupt mask (valid only for IRQ)
         ioffs:  in STD_LOGIC_VECTOR(7 downto 0); -- interrupt servicing offset
          ireq: out STD_LOGIC;                    -- global interrupt requestb (IRQ/NMI)
         voffs: out STD_LOGIC_VECTOR(7 downto 0)  -- interrupt vector offset 
        );
end intlog;

architecture rtl of intlog is
signal irq_sync:   STD_LOGIC_VECTOR(1 downto 0);
signal nmi_sync:   STD_LOGIC_VECTOR(1 downto 0);
signal res_sync:   STD_LOGIC_VECTOR(1 downto 0);
signal irq_req:    STD_LOGIC;
signal i_nmi_req:  STD_LOGIC;
signal nmi_req:    STD_LOGIC;
signal res_req:    STD_LOGIC;
signal nmi_clr:    STD_LOGIC;
signal res_clr:    STD_LOGIC;

begin
  process(clk)                                                           -- IRQ/NMI synchronization
  begin
    if(clk'event and clk = '1')then
      res_sync <= res_sync(res_sync'left-1 downto res_sync'right) & r;   -- RES sampling
      nmi_sync <= nmi_sync(nmi_sync'left-1 downto nmi_sync'right) & n;   -- NMI sampling
      irq_sync <= irq_sync(irq_sync'left-1 downto irq_sync'right) & i;   -- IRQ sampling
      if res_clr = '1' then                                              -- RES ack
        res_req <= '0';
      else
        if res_sync = "11" then                                          -- level detection for RES
          res_req <= '1';
        else
          res_req <= res_req;
        end if;
      end if;                    
      if nmi_clr = '1' then                                              -- NMI ack
         i_nmi_req <= '0';
      else
        if nmi_sync = "01" then                                          -- edge detection for NMI
           i_nmi_req <= '1';
        else
           i_nmi_req <= i_nmi_req;
        end if;
      end if;                    
    end if;  
  end process;
  nmi_req <= '1' when gmask = '0' and i_nmi_req = '1' else '0';
  
  
  process(gmask, imask, irq_sync)
  begin
    if gmask = '0' and imask = '0' then
      if irq_sync = "11" then
        irq_req <= '1';
      else   
        irq_req <= '0';
      end if;  
    else
      irq_req <= '0';
    end if;
  end process;
  
  -- priority encoder and vector offset generation (vector bits 7..0)
  process(e, res_req, nmi_req, irq_req, brk, cop)
  begin                                                                  
	  if e = '0' then                                                     -- native mode
        if res_req = '1' then
	        voffs <= x"FC";                                               -- RESET 0x00FFFC 
		  else
           if nmi_req = '1' then
	           voffs <= x"EA";                                            -- NMI   0x00FFEA
		     else
	           if irq_req = '1' then   
		           voffs <= x"EE";                                         -- IRQ   0x00FFEE 
			     else  
		           if brk = '1' then
			           voffs <= x"E6";                                      -- BRK   0x00FFE6
				     else
			           if cop = '1' then                                     
			              voffs <= x"E4";                                   -- COP   0x00FFE4 
						  else
					        voffs <= "XXXXXXXX";
						  end if;
				     end if;
			     end if;
		     end if;
	     end if;
     else 		                                                          -- emulation mode
        if res_req = '1' then
	        voffs <= x"FC";                                               -- RESET 0x00FFFC
		  else
           if nmi_req = '1' then                                         -- NMI   0x00FFFA
	           voffs <= x"FA";
		     else
	           if irq_req = '1' then                                      -- IRQ   0x00FFFE
		           voffs <= x"FE";
			     else  
		           if brk = '1' then                                       -- BRK   0x00FFFE 
			           voffs <= x"FE";
				     else
			           if cop = '1' then                                    -- COP   0x00FFF4
			              voffs <= x"F4";
						  else
					        voffs <= "XXXXXXXX";
						  end if;
				     end if;
			     end if;
		     end if;
	     end if;
	  end if;
						  
  end process;				

  process(iack,ioffs)                                                    -- interrupt acknowledge and flags clear
  begin
    if iack = '1' then
      case ioffs is
        when x"FC"  => res_clr <= '1';                                   -- RESET acknowledge
                       nmi_clr <= '1';                                   -- also NMI acknowledge
        when x"EA"  => nmi_clr <= '1';                                   -- NMI acknowledge (native mode)
                       res_clr <= '0';
        when x"FA"  => nmi_clr <= '1';                                   -- NMI acknowledge (emulation mode)
                       res_clr <= '0';
        when others => res_clr <= '0';             
                       nmi_clr <= '0';
      end case;
    else  
      res_clr <= '0';
      nmi_clr <= '0';
    end if;  
  end process;
  
  ireq <= res_req or nmi_req or irq_req;
end rtl;


