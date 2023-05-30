----------------------------------------------------------------------
-- 8/16 bit microprocessor (65C816) VHDL project                    -- 
-- Full RTL synchronous pipelined architecture                      --
-- Project by Valerio Venturi (Italy)                               -- 
-- Start date: 5/04/2020                                            --
-- Last revision: 5/04/2023                                         --
----------------------------------------------------------------------



library IEEE;
use IEEE.std_logic_1164.all;                             -- defines std_logic types
use IEEE.STD_LOGIC_unsigned.all;
use IEEE.STD_LOGIC_arith.all;

-- global architecture 
entity v65c816 is
  port(     clk0:    in STD_LOGIC;                       -- PHASE0 clock input
             res:    in STD_LOGIC;                       -- reset input
             irq:    in STD_LOGIC;                       -- interrupt request input
             nmi:    in STD_LOGIC;                       -- not maskable interrupt input
             rdy:    in STD_LOGIC;                       -- wait state request input (read/write)
         rdy_out:   out STD_LOGIC;                       -- CPU in wait state (WAI instruction)
			stp_out:   out STD_LOGIC;                       -- CPU in stop state (STP instruction)
              rw:   out STD_LOGIC;                       -- read/write out
             vpa:   out STD_LOGIC;                       -- vpa
				 vda:   out STD_LOGIC;                       -- vda
				  ml:   out STD_LOGIC;                       -- ml 
              vp:   out STD_LOGIC;                       -- vector pull
             ope:   out STD_LOGIC;                       -- microcode end 
				   e:   out STD_LOGIC;                       -- emulation (1)/native mode (0) 
				   m:   out STD_LOGIC;                       -- M status	
				   x:   out STD_LOGIC;                       -- X status	
			 op_exp:   out STD_LOGIC; 		                  -- two byte instruction running
            addr:   out STD_LOGIC_VECTOR(23 downto 0);   -- 16 bit address bus out
         data_in:    in STD_LOGIC_VECTOR(7 downto 0);    -- 8 bit input data bus
        data_out:   out STD_LOGIC_VECTOR(7 downto 0)     -- 8 bit output data bus
--         DEBUG		  
--		     a_reg:   out STD_LOGIC_VECTOR(15 downto 0);   -- 16 bit A register
--		     x_reg:   out STD_LOGIC_VECTOR(15 downto 0);   -- 16 bit X register
--		     y_reg:   out STD_LOGIC_VECTOR(15 downto 0);   -- 16 bit Y register
--		     s_reg:   out STD_LOGIC_VECTOR(15 downto 0);   -- 16 bit S register
--			 op_reg:   out STD_LOGIC_VECTOR(15 downto 0);   -- 16 bit Operand register	  
--		     p_reg:   out STD_LOGIC_VECTOR(7 downto 0);    --  8 bit P register
--		     k_reg:   out STD_LOGIC_VECTOR(7 downto 0);    --  8 bit K register
--		     b_reg:   out STD_LOGIC_VECTOR(7 downto 0);    --  8 bit B register
--		     o_reg:   out STD_LOGIC_VECTOR(7 downto 0);    --  8 bit Opcode register
--			  mcode:   out STD_LOGIC_VECTOR(3 downto 0)     --  4 bit microcode sequence register
      );   
end v65c816;

architecture struct of v65c816 is
  signal          i_res: STD_LOGIC;                      -- internal global reset RES
  signal          i_irq: STD_LOGIC;                      -- internal interrupt request IRQ
  signal          i_nmi: STD_LOGIC;                      -- internal interrupt request NMI
  signal          i_rdy: STD_LOGIC;                      -- internal wait request RDY
  signal          e_rdy: STD_LOGIC;                      -- external invertedf RDY
  signal           i_vp: STD_LOGIC;                      -- internal VP (vector pull)
  signal            int: STD_LOGIC;                      -- internal global interrupt (instruction boundary synchronized)
  signal             we: STD_LOGIC;                      -- write enable (combinatorial from PLA)
  signal           we_r: STD_LOGIC;                      -- write enable (registered)
  signal            ien: STD_LOGIC;                      -- interrupt IRQ enable
  signal            emu: STD_LOGIC;                      -- emulation mode
  signal    two_byte_op: STD_LOGIC;                      -- two byte instruction

  -- microcode signals (register control)
  signal          regop: STD_LOGIC_VECTOR(5 downto 0);   -- register operation microcode
  signal           rsel: STD_LOGIC_VECTOR(4 downto 0);   -- register select microcode
  signal        a_l_lsb: STD_LOGIC;                      -- A load lsb
  signal        a_l_msb: STD_LOGIC;                      -- A load msb
  signal          a_dec: STD_LOGIC;                      -- A decrement (MVN/MVP)
  signal        x_l_lsb: STD_LOGIC;                      -- X load lsb
  signal        x_l_msb: STD_LOGIC;                      -- X load msb
  signal            x_d: STD_LOGIC;                      -- X decrement
  signal            x_u: STD_LOGIC;                      -- X increment
  signal            y_d: STD_LOGIC;                      -- Y decrement
  signal            y_u: STD_LOGIC;                      -- Y increment
  signal        y_l_lsb: STD_LOGIC;                      -- Y load lsb
  signal        y_l_msb: STD_LOGIC;                      -- Y load msb
  signal        d_l_lsb: STD_LOGIC;                      -- D load lsb
  signal        d_l_msb: STD_LOGIC;                      -- D load msb
  signal            p_l: STD_LOGIC;                      -- P load
  signal            k_l: STD_LOGIC;                      -- program bank register PBR K load
  signal            b_l: STD_LOGIC;                      -- data bank register DBR B load
  signal           k_cl: STD_LOGIC;                      -- program bank register PBR K clear
  signal           b_cl: STD_LOGIC;                      -- data bank register DBR B clear
  signal            o_l: STD_LOGIC;                      -- OPE load msb & lsb
  signal        o_l_lsb: STD_LOGIC;                      -- OPE load lsb
  signal        o_l_msb: STD_LOGIC;                      -- OPE load msb
  signal          sp_ll: STD_LOGIC;                      -- SP load lsb
  signal          sp_lh: STD_LOGIC;                      -- SP load msb
  signal           sp_u: STD_LOGIC;                      -- SP increment
  signal           sp_d: STD_LOGIC;                      -- SP decrement
  signal       dmux_sel: STD_LOGIC_VECTOR(2 downto 0);   -- ALU operand #2 data multiplexer
  signal       kr_clear: STD_LOGIC;                      -- K clear
  signal       br_clear: STD_LOGIC;                      -- B clear
  signal         sp_emu: STD_LOGIC;                      -- '1' when S must be set in emulation mode
  
  -- microcode signals (ALU control)
  signal          aluop: STD_LOGIC_VECTOR(4 downto 0);    -- ALU operation code    
  
  -- microcode signals CPU control logic
  signal        mc_addr: STD_LOGIC_VECTOR(12 downto 0);  -- microcode PLA address
  signal        opfetch: STD_LOGIC;                      -- opcode fetch 
  signal         i_sync: STD_LOGIC;                      -- internal SYNC not latched
  signal         m_sync: STD_LOGIC;                      -- internal SYNC latched
  signal          opdec: STD_LOGIC;                      -- opcode decode
  signal           pcmp: STD_LOGIC_VECTOR(2 downto 0);   -- PC/MP out control effective
  signal        pcmp_mc: STD_LOGIC_VECTOR(2 downto 0);   -- PC/MP out control microcode
  signal          pcinc: STD_LOGIC;                      -- PC increment
  signal          e_eop: STD_LOGIC;                      -- early microcode sequence end (for some opcodes)
  signal         mc_eop: STD_LOGIC;                      -- microcode sequence end
  signal            eop: STD_LOGIC;                      -- microcode sequence end (effective)
  signal          we_mc: STD_LOGIC;                      -- microcode write enable
  signal        we_mc_l: STD_LOGIC;                      -- microcode write enable to latch
  signal           fbrk: STD_LOGIC;                      -- force BRK opcode (used by hardware interrupts) 
  signal          opbrk: STD_LOGIC;                      -- BRK opcode (used for distinguish between hardware/software interrupts) 
  signal          opcop: STD_LOGIC;                      -- COP opcode
  signal         sw_int: STD_LOGIC;                      -- software interrupt request
  signal   branch_taken: STD_LOGIC;                      -- branch condition resolved
  signal            pcc: STD_LOGIC;                      -- PC carry
  signal           clri: STD_LOGIC;                      -- clear interrupt request pending microcode
  signal         mc_vda: STD_LOGIC;                      -- microcode VDA
  signal         mc_vpa: STD_LOGIC;                      -- microcode VPA
  signal          mc_ml: STD_LOGIC;                      -- microcode ML
  signal     adc_sbc_mc: STD_LOGIC;                      -- ADC/SBC opcode (used for decimal adjustment)
  signal          ai_op: STD_LOGIC;                      -- opcode with absolute indexed addressing mode
  signal        daa_req: STD_LOGIC;                      -- DAA required
  signal           mcad: STD_LOGIC_VECTOR(11 downto 0);  -- microcode address
  signal         mcscan: STD_LOGIC_VECTOR(3 downto 0);   -- microcode pointer control
  signal           p_op: STD_LOGIC_VECTOR(4 downto 0);   -- microcode control bits register P
  signal         pcr_fc: STD_LOGIC_VECTOR(3 downto 0);   -- microcode control PC 
  signal         mpr_fc: STD_LOGIC_VECTOR(4 downto 0);   -- microcode control MP 
  signal          mcbit: STD_LOGIC_VECTOR(44 downto 0);  -- microcode control bits
  signal         regbit: STD_LOGIC_VECTOR(29 downto 0);  -- microcode control bits on registers
  signal         ivoffs: STD_LOGIC_VECTOR(7 downto 0);   -- interrupt vector offset encoding
  signal            mcn: STD_LOGIC;                      -- microcode does NOPs
  signal     add_sub_op: STD_LOGIC;                      -- ADC/SBC opcode
  signal          m_bit: STD_LOGIC;                      -- M bit of status register   
  signal          x_bit: STD_LOGIC;                      -- X bit of status register   
  signal     index_size: STD_LOGIC;                      -- index register size: 1 = 8 bit, 0 = 16 bit
  signal        m_size8: STD_LOGIC;                      -- memory operation size: 1 = 8 bit
  signal       m_size16: STD_LOGIC;                      -- memory operation size: 1 = 16 bit
  signal       s_size16: STD_LOGIC;                      -- memory operation size: 1 = 16 bit for special cases 
  signal         m_size: STD_LOGIC;                      -- memory operation size: 1 = 8 bit, 0 = 16 bit
  signal       acc_size: STD_LOGIC;                      -- accumulator C size: 1 = 8 bit, 0 = 16 bit
  signal        mov_end: STD_LOGIC;                      -- MVN/MVP end transfer
  signal         ld_acc: STD_LOGIC;                      -- load accumulator C register (16 bit) 
  signal          ld_xy: STD_LOGIC;                      -- load X/Y registers (16 bit)
  
  -- ALU signals 
  signal          c_flg: STD_LOGIC;                      -- ALU carry flag
  signal          z_flg: STD_LOGIC;                      -- ALU zero flag  
  signal          v_flg: STD_LOGIC;                      -- ALU overflow flag  
  signal          n_flg: STD_LOGIC;                      -- ALU negative flag  
  signal   pc_c_alu_flg: STD_LOGIC;                      -- ALU PC carry flag  
  signal        acr_reg: STD_LOGIC;                      -- ALU auxiliary carry (registered)

  -- multiplier signals
  signal       mul_init: STD_LOGIC;                      -- multiplier initialize
  signal    mul_start_u: STD_LOGIC;                      -- multiplier unsigned start
  signal    mul_start_s: STD_LOGIC;                      -- multiplier signed start 
  signal       mul_busy: STD_LOGIC;                      -- multiplier busy
  signal      mul_r_lsb: STD_LOGIC_VECTOR(15 downto 0);  -- multiplier lsb result
  signal      mul_r_msb: STD_LOGIC_VECTOR(15 downto 0);  -- multiplier msb result
  signal      mul_l_res: STD_LOGIC;                      -- load multiplier lsb result on register A/B and multiplier msb result on register X
  signal      mul_z_flg: STD_LOGIC;                      -- multiplier Z flag
  signal      mul_n_flg: STD_LOGIC;                      -- multiplier N flag
  
  -- WAI/STP signals
  signal         wai_ff: STD_LOGIC;                      -- WAI instruction flipflop
  signal         stp_ff: STD_LOGIC;                      -- STP instruction flipflop
  signal        wai_set: STD_LOGIC;                      -- WAI flipflop set
  signal        stp_set: STD_LOGIC;                      -- STP flipflop set
  
  -- bus
  signal           dbin: STD_LOGIC_VECTOR(7 downto 0);   -- input data bus D0..D7 
  signal          dbout: STD_LOGIC_VECTOR(7 downto 0);   -- output data bus D0..D7
  signal          a_bus: STD_LOGIC_VECTOR(15 downto 0);  -- accumulator register A/B/C bus
  signal          x_bus: STD_LOGIC_VECTOR(15 downto 0);  -- index register X bus
  signal          y_bus: STD_LOGIC_VECTOR(15 downto 0);  -- index register Y bus
  signal          k_bus: STD_LOGIC_VECTOR(7 downto 0);   -- program bank PBR K bus
  signal          b_bus: STD_LOGIC_VECTOR(7 downto 0);   -- program data DBR B bus
  signal          d_bus: STD_LOGIC_VECTOR(15 downto 0);  -- zero page/direct register D bus
  signal         sp_bus: STD_LOGIC_VECTOR(15 downto 0);  -- stack pointer register S bus
  signal          p_bus: STD_LOGIC_VECTOR(7 downto 0);   -- status register P bus
  signal         op_bus: STD_LOGIC_VECTOR(7 downto 0);   -- opcode register bus
  signal          o_bus: STD_LOGIC_VECTOR(15 downto 0);  -- operand register bus
  signal       oper_bus: STD_LOGIC_VECTOR(15 downto 0);  -- operand bus (ALU operand #2 bus)
  signal          r_bus: STD_LOGIC_VECTOR(15 downto 0);  -- general register bus (ALU operand #2 bus)
  signal        alu_bus: STD_LOGIC_VECTOR(15 downto 0);  -- ALU output bus
  signal         pc_bus: STD_LOGIC_VECTOR(15 downto 0);  -- program counter register PC bus
  signal         mp_bus: STD_LOGIC_VECTOR(23 downto 0);  -- memory data pointer register bus
  signal         ad_bus: STD_LOGIC_VECTOR(15 downto 0);  -- address bus
  signal     i_addr_bus: STD_LOGIC_VECTOR(23 downto 0);  -- internal 24 bit address bus  
  
  -- 16 bit program counter register (PC)
  component pcr
    port(       clk:  in STD_LOGIC;                        -- clock
                  i:  in STD_LOGIC;                        -- increment 
              fwait:  in STD_LOGIC;                        -- wait
			    brk_op:  in STD_LOGIC;                        -- forced BRK (by interrupt request) 
		   branch_flg:  in STD_LOGIC;                        -- branch flag   
			     mov_f:  in STD_LOGIC;                        -- MVN/MVP end transfer
                 fc:  in STD_LOGIC_VECTOR(3 downto 0);     -- function code
               din1:  in STD_LOGIC_VECTOR(7 downto 0);     -- input
               din2:  in STD_LOGIC_VECTOR(15 downto 0);    -- input
               dout: out STD_LOGIC_VECTOR(15 downto 0)     -- output
        );
  end component;        

  -- 8 bit PBR program bank register K 
  component kr
    port(    clk:  in STD_LOGIC;                       -- clock       
             clr:  in STD_LOGIC;                       -- reset	 
           fwait:  in STD_LOGIC; 
              ld:  in STD_LOGIC;                       -- load
             din:  in STD_LOGIC_VECTOR(7 downto 0);    -- input 
            dout: out STD_LOGIC_VECTOR(7 downto 0)     -- output
        );        
  end component;

  -- 8 bit DBR program bank register B 
  component br
    port(    clk:  in STD_LOGIC;                       -- clock       
             clr:  in STD_LOGIC;                       -- reset	 
           fwait:  in STD_LOGIC; 
              ld:  in STD_LOGIC;                       -- load
             din:  in STD_LOGIC_VECTOR(7 downto 0);    -- input 
            dout: out STD_LOGIC_VECTOR(7 downto 0)     -- output
        );        
  end component;
  
  -- 16 bit memory pointer register (MP)
  component mpr
    port(   clk:  in STD_LOGIC;                       -- clock
          fwait:  in STD_LOGIC;                       -- wait
         dbr_ld:  in STD_LOGIC;                       -- load DBR
		        c:  in STD_LOGIC;                       -- carry 
             fc:  in STD_LOGIC_VECTOR(4 downto 0);    -- function code
          din_l:  in STD_LOGIC_VECTOR(7 downto 0);    -- input LSB
          din_h:  in STD_LOGIC_VECTOR(7 downto 0);    -- input MSB
            dbr:  in STD_LOGIC_VECTOR(7 downto 0);  
             dr:  in STD_LOGIC_VECTOR(15 downto 0);  
	  		    op:  in STD_LOGIC_VECTOR(15 downto 0);
			    xr:  in STD_LOGIC_VECTOR(15 downto 0);
			    yr:  in STD_LOGIC_VECTOR(15 downto 0);
			    sr:  in STD_LOGIC_VECTOR(15 downto 0);
              v:  in STD_LOGIC_VECTOR(7 downto 0);    -- vector offset input
           dout: out STD_LOGIC_VECTOR(23 downto 0)    -- output
        );
  end component;        

  -- 8 bit opcode register opr (pipeline opcode prefetch register)
  component opr
    port(   clk:  in STD_LOGIC;                        -- clock
            clr:  in STD_LOGIC;                        -- force BRK opcode
          fwait:  in STD_LOGIC;                        -- wait
             ld:  in STD_LOGIC;                        -- load
            din:  in STD_LOGIC_VECTOR(7 downto 0);     -- input 
          brk_f: out STD_LOGIC;                        -- BRK opcode         
          cop_f: out STD_LOGIC;                        -- COP opcode
           dout: out STD_LOGIC_VECTOR(7 downto 0)      -- output
        );        
  end component;

  -- 16 bit operand hold register oper
  component oper
    port(    clk:  in STD_LOGIC;                       -- clock
	          clr:  in STD_LOGIC;                       -- clear
           fwait:  in STD_LOGIC;                       -- wait
              ld:  in STD_LOGIC;
          ld_lsb:  in STD_LOGIC;                       -- load lsb
          ld_msb:  in STD_LOGIC;                       -- load msb
             din:  in STD_LOGIC_VECTOR(15 downto 0);   -- input 
            dout: out STD_LOGIC_VECTOR(15 downto 0)    -- output
        );        
  end component;

  -- 16 bit accumulator register A
  component ar
    port(       clk:  in STD_LOGIC;                    -- clock                      
              fwait:  in STD_LOGIC; 
  		         size:  in STD_LOGIC;	                   -- accumulator register size: 1 = 8 bit, 0 = 16 bit
             ld_lsb:  in STD_LOGIC;                    -- load lsb
             ld_msb:  in STD_LOGIC;                    -- load msb 
  	      ld_mul_lsb:  in STD_LOGIC;                    -- load multiplication lsb result
 		            d:  in STD_LOGIC;                    -- decrement
		    end_count: out STD_LOGIC;                    -- '1' when a is 0xFF or 0xFFFF 
                din:  in STD_LOGIC_VECTOR(15 downto 0); -- input
			   mul_lsb:  in STD_LOGIC_VECTOR(15 downto 0); -- input multiplication lsb result	  
               dout: out STD_LOGIC_VECTOR(15 downto 0)  -- output
        );        
  end component;

  -- 16 bit index register X 
  component xr
    port(       clk:  in STD_LOGIC;                       -- clock                         
              fwait:  in STD_LOGIC; 
  		         size:  in STD_LOGIC;	                      -- index register size: 1 = 8 bit, 0 = 16 bit
             ld_lsb:  in STD_LOGIC;                       -- load lsb
             ld_msb:  in STD_LOGIC;                       -- load msb
	      ld_mul_msb:  in STD_LOGIC;
		            u:  in STD_LOGIC;                       -- increment
		            d:  in STD_LOGIC;                       -- decrement
                din:  in STD_LOGIC_VECTOR(15 downto 0);   -- input 
		      mul_msb:  in STD_LOGIC_VECTOR(15 downto 0);   -- input multiplication msb result	  
               dout: out STD_LOGIC_VECTOR(15 downto 0)    -- output
        );        
  end component;

  -- 16 bit index register Y 
  component yr
    port(    clk:  in STD_LOGIC;                       -- clock
           fwait:  in STD_LOGIC; 
  		      size:  in STD_LOGIC;	                      -- index register size: 1 = 8 bit, 0 = 16 bit
          ld_lsb:  in STD_LOGIC;                       -- load lsb
          ld_msb:  in STD_LOGIC;                       -- load msb
		         u:  in STD_LOGIC;                       -- increment
		         d:  in STD_LOGIC;                       -- decrement
             din:  in STD_LOGIC_VECTOR(15 downto 0);   -- input 
            dout: out STD_LOGIC_VECTOR(15 downto 0)    -- output
        );        
  end component;

  -- 16 bit zero page/direct register D 
  component dr
    port(     clk:  in STD_LOGIC;                      -- clock
              clr:  in STD_LOGIC;                      -- reset
            fwait:  in STD_LOGIC; 
           ld_lsb:  in STD_LOGIC;                      -- load lsb
           ld_msb:  in STD_LOGIC;                      -- load msb
              din:  in STD_LOGIC_VECTOR(15 downto 0);  -- input 
             dout: out STD_LOGIC_VECTOR(15 downto 0)   -- output
        );        
  end component;

  -- 16 bit stack pointer SP 
  component spr
    port(   clk:  in STD_LOGIC;                        -- clock
          fwait:  in STD_LOGIC;                        -- wait
 		       em:   in STD_LOGIC;                       -- emulation mode (1)/native mode (0)
            clr:  in STD_LOGIC;                        -- load init value
           ld_l:  in STD_LOGIC;                        -- load lsb
           ld_h:  in STD_LOGIC;                        -- load msb
              u:  in STD_LOGIC;                        -- increment
              d:  in STD_LOGIC;                        -- decrement
            din:  in STD_LOGIC_VECTOR(15 downto 0);    -- input
           dout: out STD_LOGIC_VECTOR(15 downto 0)     -- output
      );
  end component;

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
  -- The P register also contains an additional carry/borrow flag (ACR) used for effective address calculation but
  -- it is not visible at program level
  component pr
    port(      clk:  in STD_LOGIC;                        -- clock
               clr:  in STD_LOGIC;                        -- clear
             fwait:  in STD_LOGIC;                        -- wait
                 n:  in STD_LOGIC;                        -- N input
                 v:  in STD_LOGIC;                        -- V input
                 z:  in STD_LOGIC;                        -- Z input
                 c:  in STD_LOGIC;                        -- C input
		       mpy_z:  in STD_LOGIC;                        -- Z input from multiplier			
		       mpy_n:  in STD_LOGIC;                        -- N input from multiplier			
               swi:  in STD_LOGIC;                        -- software interrupt (BRK/COP opcode)
            acr_in:  in STD_LOGIC;                        -- auxiliary carry in   
                fc:  in STD_LOGIC_VECTOR(4 downto 0);     -- function code 
               din:  in STD_LOGIC_VECTOR(7 downto 0);     -- input
              dout: out STD_LOGIC_VECTOR(7 downto 0);     -- output
           acr_out: out STD_LOGIC;                        -- auxiliary carry out   
			       em: out STD_LOGIC;                        -- emulation (1)/native mode (0)
		      two_op: out STD_LOGIC                         -- two byte instruction	  			 
        );        
  end component;

  -- 16 bit (binary/bcd) two-way through pass ALU   
  component alu_bin
    port( alu_byp:  in STD_LOGIC;                      -- ALU bypass (no operation)    
              bcd:  in STD_LOGIC;                      -- BCD mode 
 		  	    size:  in STD_LOGIC;  	                   -- ALU size operation: 1 = 8 bit, 0 = 16 bit
              cin:  in STD_LOGIC;                      -- carry/borrow in
              vin:  in STD_LOGIC;                      -- overflow in
              op1:  in STD_LOGIC_VECTOR(15 downto 0);  -- 16 bit operand #1
              op2:  in STD_LOGIC_VECTOR(15 downto 0);  -- 16 bit operand #2
               fc:  in STD_LOGIC_VECTOR(4 downto 0);   -- function code
               cf: out STD_LOGIC;                      -- carry/borrow (byte) out 
               zf: out STD_LOGIC;                      -- zero flag out
               nf: out STD_LOGIC;                      -- negative flag out
               vf: out STD_LOGIC;                      -- overflow flag out
            pc_cf: out STD_LOGIC;                      -- carry/borrow out for PC operation 
             dout: out STD_LOGIC_VECTOR(15 downto 0)   -- 16 bit result out
        );  
  end component;           

  -- PC/MP address multiplexer
  component addrmux
    port(  sel:  in STD_LOGIC_VECTOR(2 downto 0);
             a:  in STD_LOGIC_VECTOR(23 downto 0);
             b:  in STD_LOGIC_VECTOR(23 downto 0);
			  dbr:  in STD_LOGIC_VECTOR(7 downto 0);  
             s:  in STD_LOGIC_VECTOR(15 downto 0);
  			   xr:  in STD_LOGIC_VECTOR(15 downto 0);
			   yr:  in STD_LOGIC_VECTOR(15 downto 0); 
             y: out STD_LOGIC_VECTOR(23 downto 0)
        );
  end component;            

  -- register multiplexer
  component regmux
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
  end component;           

  -- data multiplexer (register "O" bypass)
  component dmux is
    port(  sel:  in STD_LOGIC_VECTOR(2 downto 0);
             a:  in STD_LOGIC_VECTOR(15 downto 0);
             b:  in STD_LOGIC_VECTOR(7 downto 0);
             y: out STD_LOGIC_VECTOR(15 downto 0)
        );
  end component dmux;

  -- microcode sequencer logic
  component mcseq
    port(    clk:  in STD_LOGIC; 
             clr:  in STD_LOGIC;
          mc_nop:  in STD_LOGIC;
           fwait:  in STD_LOGIC;
               q: out STD_LOGIC_VECTOR(3 downto 0)
        );
  end component;          

  -- micropla logic
  -- output fields format:
  -- a[12]    is two byte instruction bit
  -- a[11..4] is 8 bit opcode  
  -- a[3..0]  is 4 bit microinstruction counter
  component mcpla
    port(    em:  in STD_LOGIC;                           -- emulation mode (1)/native mode (0)
              m:  in STD_LOGIC;                           -- M memory/acc. 8 bit (1), M memory/acc. 16 bit (0)  
              x:  in STD_LOGIC;                           -- X index reg. 8 bit (1), X index reg. 16 bit (0)  
	           a:  in STD_LOGIC_VECTOR(12 downto 0);       -- two byte bit & 8 bit opcode & 4 bit microinstruction counter
              q: out STD_LOGIC_VECTOR(44 downto 0)        -- microcode output
        );
  end component;          

  -- register operation decoding logic
  component decreg
    port(    r:  in STD_LOGIC_VECTOR(5 downto 0);
             y: out STD_LOGIC_VECTOR(29 downto 0)
        );
  end component;                   

  -- cpu main state machine
  component cpufsm
    port(     clk:  in STD_LOGIC;
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
  end component;
  
  -- interrupt logic
  component intlog
  port(    clk:  in STD_LOGIC;
          iack:  in STD_LOGIC;                    -- interrupt acknowledge by microcode 
             r:  in STD_LOGIC;                    -- RESET request
             n:  in STD_LOGIC;                    -- NMI request
             i:  in STD_LOGIC;                    -- IRQ request
           brk:  in STD_LOGIC;                    -- BRK opcode
			  cop:  in STD_LOGIC;                    -- COP opcode
			    e:  in STD_LOGIC;                    -- native\emulation mode
 			gmask:  in STD_LOGIC;                    -- interrupt mask valid for IRQ and NMI (used by two byte instruction)	 
         imask:  in STD_LOGIC;                    -- interrupt mask (valid only for IRQ)
         ioffs:  in STD_LOGIC_VECTOR(7 downto 0); -- interrupt servicing offset
          ireq: out STD_LOGIC;                    -- global interrupt requestb (IRQ/NMI)
         voffs: out STD_LOGIC_VECTOR(7 downto 0)  -- interrupt vector offset 
        );
  end component;                            

  -- branch logic
  component branch
    port(    op:  in STD_LOGIC_VECTOR(3 downto 0);
              n:  in STD_LOGIC;                        
              v:  in STD_LOGIC;                        
              z:  in STD_LOGIC;                        
              c:  in STD_LOGIC;                        
           bres: out STD_LOGIC
        );      
  end component;                            
  
  -- opcode decimal instructions and prefetch prediction logic
  component pre_dec
    port(    op:  in STD_LOGIC_VECTOR(7 downto 0);
          fetch:  in STD_LOGIC; 
             ei: out STD_LOGIC;
            dec: out STD_LOGIC 
        );      
  end component;                            

  -- 16X16->32 bit multiplier signed/unsigned
  component multiplier
    port(     clk:   in STD_LOGIC;
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
  end component;  
  
  begin  
    u1:pcr      port map(clk=>clk0,
                         i=>pcinc,
                         fwait=>i_rdy,
								 brk_op=>opbrk,
								 branch_flg=>branch_taken,
								 mov_f=>mov_end,
                         fc=>pcr_fc,
                         din1=>alu_bus(7 downto 0),
                         din2=>o_bus,
                         dout=>pc_bus
                        );

    u2:kr       port map(clk=>clk0,
	                      clr=>kr_clear,
                         fwait=>i_rdy,
                         ld=>k_l,
                         din=>alu_bus(7 downto 0),
                         dout=>k_bus
                        );

    u3:br       port map(clk=>clk0,
	                      clr=>br_clear,
                         fwait=>i_rdy,
                         ld=>b_l,
                         din=>alu_bus(7 downto 0),
                         dout=>b_bus
                        );
								
    u4:mpr      port map(clk=>clk0,
                         fwait=>i_rdy,
                         dbr_ld=>opfetch,
                         c=>acr_reg,
                         fc=>mpr_fc,
                         din_l=>alu_bus(7 downto 0),
                         din_h=>dbin,
                         dbr=>b_bus,  
                         dr=>d_bus,  
			                op=>o_bus,
			                xr=>x_bus,
			                yr=>y_bus,
			                sr=>sp_bus,
                         v=>ivoffs,
                         dout=>mp_bus
                        );

    u5:ar       port map(clk=>clk0,
                         fwait=>i_rdy,
								 size=>acc_size,
                         ld_lsb=>a_l_lsb,
                         ld_msb=>a_l_msb,
								 ld_mul_lsb=>mul_l_res,
								 d=>a_dec,
								 end_count=>mov_end,
                         din=>alu_bus,
								 mul_lsb=>mul_r_lsb,
                         dout=>a_bus
                        );

    u6:xr       port map(clk=>clk0,
                         fwait=>i_rdy,
								 size=>index_size,
                         ld_lsb=>x_l_lsb,
                         ld_msb=>x_l_msb,
								 ld_mul_msb=>mul_l_res,
								 u=>x_u,
								 d=>x_d,
                         din=>alu_bus,
								 mul_msb=>mul_r_msb,
                         dout=>x_bus
                        );

    u7:yr       port map(clk=>clk0,
                         fwait=>i_rdy,
								 size=>index_size,
                         ld_lsb=>y_l_lsb,
                         ld_msb=>y_l_msb,
								 u=>y_u,
								 d=>y_d,
                         din=>alu_bus,
                         dout=>y_bus
                        );

    u8:dr       port map(clk=>clk0,
                         clr=>i_res,
                         fwait=>i_rdy,
                         ld_lsb=>d_l_lsb,
                         ld_msb=>d_l_msb,
                         din=>alu_bus,
                         dout=>d_bus
                        );

    u9:spr      port map(clk=>clk0,
                         clr=>i_res,
                         fwait=>i_rdy,
								 em=>sp_emu,
                         ld_l=>sp_ll,
                         ld_h=>sp_lh,
                         u=>sp_u,
                         d=>sp_d,
                         din=>alu_bus,
                         dout=>sp_bus
                        );

    u10:pr      port map(clk=>clk0,
                         clr=>i_res,
                         fwait=>i_rdy,
                         n=>n_flg,
                         v=>v_flg,
                         z=>z_flg,
                         c=>c_flg,
								 mpy_z=>mul_z_flg,
								 mpy_n=>mul_n_flg,
                         swi=>sw_int,
                         acr_in=>pc_c_alu_flg,
                         fc=>p_op,
                         din=>dbin,
                         dout=>p_bus,
                         acr_out=>acr_reg,
								 em=>emu,
								 two_op=>two_byte_op
                        ); 
                                             
    u11:opr     port map(clk=>clk0,
                         clr=>fbrk,
                         fwait=>i_rdy,
                         ld=>opfetch,
                         din=>dbin,
                         brk_f=>opbrk,
								 cop_f=>opcop,
                         dout=>op_bus
                        );

    u12:oper    port map(clk=>clk0,
	                      clr=>opfetch, 
                         fwait=>i_rdy,
								 ld=>o_l,
                         ld_lsb=>o_l_lsb,
                         ld_msb=>o_l_msb,
                         din=>alu_bus,
                         dout=>o_bus
                        );

    u13:alu_bin port map(alu_byp=>acr_reg,
	                      bcd=>p_bus(3),
								 size=>m_size,
                         cin=>p_bus(0),
                         vin=>p_bus(6),
                         op1=>r_bus,
                         op2=>oper_bus,
                         fc=>aluop,                         
                         cf=>c_flg,
                         zf=>z_flg,
                         nf=>n_flg,
                         vf=>v_flg,
                         pc_cf=>pc_c_alu_flg,
                         dout=>alu_bus
                        );                                                   

    u14:addrmux port map(sel=>pcmp,
                         a=>i_addr_bus,
                         b=>mp_bus,
								 dbr=>b_bus,
                         s=>sp_bus,
								 xr=>x_bus,
								 yr=>y_bus,
                         y=>addr
                        );
                        
    u15:regmux  port map(sel=>rsel,
                         a=>dbin,
                         b=>a_bus,
                         c=>x_bus,
                         d=>y_bus,
                         e=>sp_bus,
                         g=>p_bus,
                         h=>pc_bus(7 downto 0),
                         i=>pc_bus(15 downto 8),
                         j=>o_bus,
                         k=>d_bus,
								 l=>k_bus,
								 m=>b_bus,
                         y=>r_bus
                        );

    u16:dmux    port map(sel=>dmux_sel,
                         a=>o_bus,
                         b=>dbin,
                         y=>oper_bus
                        ); 

    u17:mcseq   port map(clk=>clk0,
                         clr=>opdec,
                         mc_nop=>mcn,
                         fwait=>i_rdy or mul_busy,
                         q=>mcscan
                        ); 
                        
    u18:mcpla   port map(em=>emu,
	                      m=>m_bit,
	                      x=>x_bit,
	                      a=>mc_addr,
                         q=>mcbit
                        ); 
                        
    u19:decreg  port map(r=>regop,
                         y=>regbit
                        ); 
                        
    u20:cpufsm  port map(clk=>clk0,
                         clr=>i_res,
                         fwait=>i_rdy,
                         ireq=>int,
                         aim=>ai_op,
                         bcarry=>pcc,
                         icarry=>acr_reg,
                         p1=>pcmp_mc,
                         e_ei=>e_eop,
                         mc_ei=>mc_eop,
                         addsub=>add_sub_op,
                         dec_mode=>p_bus(3),
                         fetch=>opfetch,
                         op_sync=>i_sync,
                         pci=>pcinc,
                         pq=>pcmp,
                         fb=>fbrk,
                         od=>opdec,
                         mc_nop=>mcn
                        ); 

    u21:intlog  port map(clk=>clk0,
                         iack=>clri,
                         r=>i_res,
                         n=>i_nmi,
                         i=>i_irq,
                         brk=>opbrk,
								 cop=>opcop,
								 e=>emu,
                         gmask=>two_byte_op,
                         imask=>ien,
                         ioffs=>mp_bus(7 downto 0),
                         ireq=>int,
                         voffs=>ivoffs
                        );       
                        
    u22:branch  port map(op=>op_bus(7 downto 4),
                         n=>p_bus(7),                                      
                         v=>p_bus(6),
                         z=>p_bus(1),
                         c=>p_bus(0),
                         bres=>branch_taken
                        ); 

    u23:pre_dec port map(op=>dbin,
                         fetch=>opfetch,
                         ei=>e_eop,
                         dec=>add_sub_op
                        );

    u24:multiplier port map(clk=>clk0,
	                         clr=>i_res,
                            init=>mul_init, 
                            start_u=>mul_start_u,
									 start_s=>mul_start_s,
                            mpcand=>a_bus,
		 	                   mplier=>x_bus,
			                   busy=>mul_busy,
                            res_lsb=>mul_r_lsb,
                            res_msb=>mul_r_msb,
									 z_flg=>mul_z_flg,
									 n_flg=>mul_n_flg
								   ); 
								
    -- asynchronous CPU link section 
	 mc_addr    <= two_byte_op & mcad;
	 e          <= emu;                                     -- emulation mode
    ien        <= p_bus(2);                                -- P(I) flag 
    i_res      <= not res;                                 -- internal reset
    i_nmi      <= not nmi;                                 -- internal NMI
    i_irq      <= not irq;                                 -- internal IRQ
    e_rdy      <= not rdy;                                 -- external RDY inverted
	 i_rdy      <= e_rdy or wai_ff or stp_ff;               -- internal RDY
    mcad       <= op_bus & mcscan;                         -- microcode address
    rsel       <= mcbit(4 downto 0);                       -- registers read microcode
    regop      <= mcbit(10 downto 5);                      -- registers operation microcode
    aluop      <= mcbit(15 downto 11);                     -- ALU microcode
    p_op       <= mcbit(20 downto 16);                     -- register P microcode 
    mpr_fc     <= mcbit(25 downto 21);                     -- MPR microcode
    pcr_fc     <= mcbit(29 downto 26);                     -- PCR microcode
    pcmp_mc    <= mcbit(32 downto 30);                     -- PCR/MPR multiplexer microcode
    clri       <= mcbit(33);                               -- clear interrupt request
    we_mc      <= mcbit(34);                               -- write enable (combinatorial) microcode
    we_mc_l    <= mcbit(35);                               -- write enable (latched) microcode
    mc_eop     <= mcbit(36);                               -- end of instruction reached                             
    mc_vda     <= mcbit(37);                               -- microcode VDA
	 mc_vpa     <= mcbit(38);                               -- microcode VPA
	 mc_ml      <= mcbit(39);                               -- microcode ML
    i_vp       <= mcbit(40);                               -- vector pull 
    ai_op      <= mcbit(41);                               -- opcode with addressing indexed microcode
    dmux_sel   <= mcbit(44 downto 42);                     -- data multiplexer microcode
    ope        <= eop;
	 i_addr_bus <= k_bus & pc_bus;
    eop <= '1' when mc_eop = '1' or e_eop = '1' else '0';
    vp <= not i_vp;
	 op_exp <= two_byte_op;
	 vda <= m_sync or mc_vda;
    vpa <= m_sync or mc_vpa;
	 ml <= mc_ml; 
	 sw_int <= opbrk or opcop;

	 -- ALU/memory size 
    m_size8  <= '1' when emu = '1' or m_bit = '1' else
	             '1' when op_bus = x"EB" or op_bus = x"AB" else                     -- when XBA and PLB opcodes the ALU size is always 8 bit
	             '1' when (op_bus = x"AA" or op_bus = x"A8") and x_bit = '1' else   -- when TAX and TAY opcodes and X is '1' the ALU size is 8 bit
	             '1' when (op_bus = x"8A" or op_bus = x"98") and m_bit = '1' else   -- when TXA and TXA opcodes and M is '1' the ALU size is 8 bit
	             '1' when op_bus = x"68" and m_bit = '1' else                       -- when PLA opcode and M is '1' the ALU size is 8 bit
	             '1' when (op_bus = x"FA" or op_bus = x"7A") and x_bit = '1' else   -- when PLX or PLY opcode and X = '1' the ALU size is 8 bit
					 '0';
	 m_size16 <= '0' when (op_bus = x"5B" or op_bus = x"7B") else                   -- when TCD or TDC opcodes the transfer size is always 16 bit
	             '0' when (op_bus = x"1B" or op_bus = x"3B") else                   -- when TCS or TSC opcodes the transfer size is always 16 bit
	             '0' when (op_bus = x"82" or op_bus = x"62") else                   -- when BRL or PER opcodes the transfer size is always 16 bit
	             '0' when op_bus = x"2B" else                                       -- when PLD opcode the transfer size is always 16 bit
					 '0' when (op_bus = x"AB" and two_byte_op = '1') and emu = '0' else -- when PLR opcode and native mode
					 '0' when ld_acc = '1' and m_bit = '0' else                         -- when load accumulator C register 
					 '0' when ld_xy = '1' and x_bit = '0' else                          -- when load X/Y registers (16 bit size)   
				    '1';
	 s_size16 <= '0' when op_bus = x"EB" else '1';                                  -- special case for XBA: accumulator size is 16 bit so it can reloads itself swapped in only one cycle                         				 
	 m_size <= m_size8 and m_size16;	                                               -- ALU size			 
	 acc_size <= m_size8 and m_size16 and s_size16;                                 -- accumulator register C size
    index_size <= emu or x_bit;                                                    -- index registers size 
	
	 -- S native/emulation mode (set by XCE opcode and E bit)
    sp_emu <= p_bus(0) when op_bus = x"FB" else emu;	
	 
    -- register operations
    a_l_lsb     <= regbit(0);                               -- A load lsb
    a_l_msb     <= regbit(1);                               -- A load msb
    a_dec       <= regbit(2);                               -- A decrement
    x_l_lsb     <= regbit(3);                               -- X load lsb
    x_l_msb     <= regbit(4);                               -- X load msb
	 x_d         <= regbit(5);                               -- X -= 1
	 x_u         <= regbit(6);                               -- X += 1
    y_l_lsb     <= regbit(7);                               -- Y load lsb
    y_l_msb     <= regbit(8);                               -- Y load msb
	 y_d         <= regbit(9);                               -- Y -= 1
	 y_u         <= regbit(10);                              -- Y += 1
    d_l_lsb     <= regbit(11);                              -- D load lsb
    d_l_msb     <= regbit(12);                              -- D load msb
    o_l         <= regbit(13);                              -- O load msb & lsb
    o_l_lsb     <= regbit(14);                              -- O load lsb
    o_l_msb     <= regbit(15);                              -- O load msb
    sp_ll       <= regbit(16);                              -- S load lsb
    sp_lh       <= regbit(17);                              -- S load msb
    sp_u        <= regbit(18);                              -- S += 1
    sp_d        <= regbit(19);                              -- S -= 1
    k_l         <= regbit(20);                              -- PBR K load
    b_l         <= regbit(21);                              -- DBR B load
    k_cl        <= regbit(22);                              -- PBR K clear
    b_cl        <= regbit(23);                              -- DBR B clear
	 mul_l_res   <= regbit(24);                              -- load multiplication result on A/B and X
	 mul_init    <= regbit(25);                              -- init multiplier
	 mul_start_u <= regbit(26);                              -- start multiplier unsigned 
	 mul_start_s <= regbit(27);                              -- start multiplier signed
	 wai_set     <= regbit(28);                              -- WAI enter wait
	 stp_set     <= regbit(29);                              -- STP enter wait
    we          <= we_mc or opfetch;                        -- write enable
    m_bit       <= p_bus(5) or emu;                         -- M bit
    x_bit       <= p_bus(4) or emu;                         -- X bit
    m           <= m_bit;
    x           <= x_bit;
	 kr_clear    <= i_res or k_cl;
	 br_clear    <= i_res or b_cl;
	 ld_acc      <= regbit(0) and regbit(1);
    ld_xy       <= (regbit(3) and regbit(4)) or (regbit(7) and regbit(8)); 	 
    -- VPA latched
    process(clk0)
    begin
      if (clk0'event and clk0 = '1') then
        if i_rdy = '0' then
          m_sync <= i_sync;
        else
          m_sync <= m_sync;   
        end if;  
      end if;
    end process;  

    -- PC carry logic
    process(o_bus,pc_c_alu_flg)
    begin
      if o_bus(7) = '0' then              -- check for positive/negative branch offset (bit 7)
        pcc <= pc_c_alu_flg;
      else
        pcc <= not pc_c_alu_flg;
      end if;            
    end process;              

    -- write enable registered
    process(clk0)
    begin
      if (clk0'event and clk0 = '1') then
        if i_res = '1' then
          we_r <= '1';
        else   
          if i_rdy = '0' then
            we_r <= we_mc_l;
          else
            we_r <= we_r;
          end if;    
        end if;  
      end if;      
    end process;              
 
    rw <= we and we_r;

	 -- WAI 
	 process(clk0)
	 begin
      if (clk0'event and clk0 = '1') then
	     if wai_ff = '0' then
          if wai_set then
             wai_ff <= '1';
          else
             wai_ff <= wai_ff;
          end if;    
		  else
          if i_res = '1' or i_nmi = '1' or i_irq = '1' then
		       wai_ff <= '0'; 
          else   
		       wai_ff <= wai_ff;  	 
          end if;  
        end if;      
		end if;  
    end process;          
    rdy_out <= not wai_ff;    

	 -- STP 
	 process(clk0)
	 begin
      if (clk0'event and clk0 = '1') then
	     if stp_ff = '0' then
          if stp_set then
             stp_ff <= '1';
          else
             stp_ff <= stp_ff;
          end if;    
		  else
          if i_res = '1' then
		       stp_ff <= '0'; 
          else   
		       stp_ff <= stp_ff;  	 
          end if;  
        end if;      
		end if;  
    end process;              
    stp_out <= not stp_ff;    
	 
	 
    -- data bus tristate (buffer ring gated) control logic
    --process(clk0,we,we_r,alu_bus)
    --begin
    --  if clock = '0' and (we = '0' or we_r = '0') then
    --    data <= alu_bus;
    --  else
    --    data <= "ZZZZZZZZ";
    --  end if;
    --end process;
	 
	 
    data_out <= alu_bus(7 downto 0);            
    dbin <= data_in or "00000000";
	 -- DEBUG
--  a_reg <= a_bus;
--  x_reg <= x_bus;
--  y_reg <= y_bus;
--	 s_reg <= sp_bus;
--	 op_reg <= o_bus;
--	 p_reg <= p_bus;
--	 k_reg <= k_bus;
--	 b_reg <= b_bus;
--	 o_reg <= op_bus;
--	 mcode <= mcscan;

end struct;    
  


