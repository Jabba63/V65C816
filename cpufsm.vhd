library IEEE;
use IEEE.std_logic_1164.all;  -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- CPU FSM main state machine
entity cpufsm is
  port(      clk:  in STD_LOGIC;
             clr:  in STD_LOGIC;
           fwait:  in STD_LOGIC;
            ireq:  in STD_LOGIC;
             aim:  in STD_LOGIC;
          bcarry:  in STD_LOGIC;  
          icarry:  in STD_LOGIC;  
              p1:  in STD_LOGIC_VECTOR(2 downto 0); 
            e_ei:  in STD_LOGIC; 
           mc_ei:  in STD_LOGIC; 
          addsub:  in STD_LOGIC;   
        dec_mode:  in STD_LOGIC;   
           fetch: out STD_LOGIC;
         op_sync: out STD_LOGIC;  
             pci: out STD_LOGIC;
              pq: out STD_LOGIC_VECTOR(2 downto 0);
              fb: out STD_LOGIC;
              od: out STD_LOGIC;
          mc_nop: out STD_LOGIC
      );     
end cpufsm;

architecture rtl of cpufsm is
type states is (s0,s1,s2,s3,s4,s5,s6);
attribute ENUM_ENCODING:STRING;
attribute ENUM_ENCODING of states: type is "000000001 000000010 000000100 000001000 000010000 000100000 001000000";  -- one hot encoding for all states
signal present,nxt:states;  
begin
  process(clk)
  begin
    if (clk'event and clk = '1') then 
      if fwait = '1' then
        present <= present;
      else 
        present <= nxt;  
      end if;    
    end if;
  end process;    

  process(present,ireq,bcarry,icarry,p1,e_ei,mc_ei,aim,clr,addsub,dec_mode)
  begin
    case present is
      -- reset
      when s0 => 
      fetch <= '0';
      op_sync <= '0';
      pci <= '0';
      pq <= "000";
      fb <= '1';                              -- force BRK                              
      od <= '1';                              -- clear microcode sequencer
      mc_nop <= '0';
      if clr = '1' then
        nxt <= s0;
      else  
        nxt <= s2;
      end if;  

      -- fetch opcode
      when s1 =>
      pq <= "000";
      if ireq = '1' then                      -- if interrupt request
        od <= '0';
		  fetch <= '0';
        fb <= '0';                            
        pci <= '0';                           -- PC doesn't increment
        op_sync <= '0';
        mc_nop <= '1';                        -- stop microcode execution
        nxt <= s6;                            -- goto s6
      else  
        od <= '1';                            -- clear microcode sequencer
        fetch <= '1';                         -- fetch opcode
		  fb <= '0';
        pci <= '1';                           -- PC increment
        if addsub = '1'then                   -- if ADD/SUB opcode may require an extra cycle for DAA/DAS adjustement
          op_sync <= '0';
          mc_nop <= '0';
          nxt <= s5;                          -- goto s5
        else                       
          if e_ei = '1' then                  -- if end of instruction is reached on fetch 
            mc_nop <= '1';
            if clr = '1' then                 -- if reset
              op_sync <= '0';
              nxt <= s0;                      -- goto reset 
            else
              op_sync <= '1';                 -- remain in this state to fetch a new opcode
              nxt <= s1;
            end if;
          else    
            mc_nop <= '0';
            op_sync <= '0';                   -- goto s2
            nxt <= s2;
          end if;  
        end if;
      end if;    

      -- wait until end of instruction
      when s2 =>
      fetch <= '0';
      pq <= p1;
      fb <= '0';
      od <= '0';
      mc_nop <= '0';
      pci <= '0';
      if aim = '1' then                     -- opcode with indexed mode
        op_sync <= '0';
        nxt <= s3;
      else
        if mc_ei = '1' then                 -- if end of instruction is reached 
          if clr = '1' then
            op_sync <= '0';
            nxt <= s0;
          else
            op_sync <= '1';
            nxt <= s1;
          end if;  
        else
            op_sync <= '0';
            nxt <= s2;
        end if;
      end if;      
 
      when s3 =>                            -- opcode with absolute indexed mode
      fetch <= '0';
      pq <= p1;
      fb <= '0';
      od <= '0';
      pci <= '0';
      if mc_ei = '1' then                   -- if end of instruction is reached 
        if icarry = '0' then
          mc_nop <= '1';
          if clr = '1' then
            op_sync <= '0';
            nxt <= s0;
          else  
            op_sync <= '1';
            nxt <= s1;
          end if;
        else
          op_sync <= '0';
          mc_nop <= '0';
          nxt <= s4;
        end if; 
      else
        op_sync <= '0';
        mc_nop <= '0';
        nxt <= s3;   
      end if;  

      when s4 =>                            -- opcode with absolute indexed mode: add carry to msb PC
      fetch <= '0';
      pq <= p1;
      fb <= '0';
      od <= '0';
      pci <= '0';
      if clr = '1' then
        mc_nop <= '0';
        op_sync <= '0';
        nxt <= s0;
      else  
        mc_nop <= '1';
        op_sync <= '1';
        nxt <= s1;
      end if;

      -- ADD/SUB decimal adjustement extra cycle
      when s5 =>
      fetch <= '0';
      pq <= p1;
      fb <= '0';
      od <= '0';
      pci <= '0';
      if mc_ei = '1' then
        if dec_mode = '0' then
          mc_nop <= '1';
        else
          mc_nop <= '0';
        end if;  
        if clr = '1' then
          op_sync <= '0';
          nxt <= s0;
        else  
          op_sync <= '1';
          nxt <= s1;
        end if;
      else
        mc_nop <= '0';
        op_sync <= '0';
        nxt <= s5;
      end if;   

      when s6 =>
      pq <= "000";
      od <= '1';                            -- clear microcode sequencer
      fetch <= '0';
      fb <= '1';                            -- force load BRK to opcode register 
      pci <= '0';                           -- PC doesn't increment
      op_sync <= '1';
      mc_nop <= '0';
      nxt <= s2;                            -- goto s2

      -- illegal state covering
      when others =>
      fetch <= '0';
      op_sync <= '0';
      pci <= '0';
      pq <= "000";
      fb <= '0';
      od <= '1';
      mc_nop <= '0';
      nxt <= s0;
      
    end case;    
  end process;
end rtl;


