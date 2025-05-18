//
// Author : Ivan M. Kosarev
//
// Released: 16.10.2023
//
// Changed: 17.11.2023
//
// Approved: 17.11.2023
//

`timescale 1ps/100fs
module PLL600V3_m18 (
	CLKCORE, CLKDDROUT, CLKCONTR,CLKDDRIN, DT1, AT1, LKDET, TM1, TM2, SG1, CLKFBKB, BMCLK1X,
	PD, ENB, VCOD0, VCOD1, DIV0, DIV1, DIV2, DIV3, DIV4, SYNCEN, CHP0, CHP1, CHP2, CHP3, CHP4, SLOW_MEM);

output	CLKCORE,CLKDDROUT,CLKCONTR,CLKDDRIN, DT1, AT1, LKDET;
input	TM1, TM2, SG1, CLKFBKB, BMCLK1X, PD, ENB, VCOD0, VCOD1,
	DIV0, DIV1, DIV2, DIV3, DIV4, SYNCEN, CHP0, CHP1, CHP2, CHP3, CHP4, SLOW_MEM;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////// PLL DOES NOT TAKE INTO ACCOUNT PROGRAMMABLE INPUT: VCOD, DIV, CHP /////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
CONNECTION OF CONTROL REGISTER TO PLL CONTROL INPUTS

SYNCEN        - pllconf[15]
SG            - pllconf[14]
TM[2:1]       - pllconf[13:12]
CHP[4:0]      - pllconf[11:7]
VCOD[1:0]     - pllconf[6:5]
DIV[4:0]      - pllconf[4:0]
*/

buf	g1 (SG1_, SG1),		g2 (SYNCEN_, SYNCEN),	g3 (TM1_, TM1),
    g22 (VCOD0_, VCOD0), g21 (VCOD1_, VCOD1),
	g4 (DIV0_, DIV0),	g5 (CHP0_, CHP0),	g6 (TM2_, TM2),
	g7 (DIV1_, DIV1),	g8 (CHP1_, CHP1),
	g10 (DIV2_, DIV2),	g11 (CHP2_, CHP2),	g12 (BMCLK1X_, BMCLK1X), g33 (BMCLK2X_, BMCLK2X),g34 (CLKFBKB_, CLKFBKB),
	g35 (SLOW_MEM_, SLOW_MEM),
	g13 (DIV3_, DIV3),	g14 (CHP3_, CHP3),
	g16 (DIV4_, DIV4),	g17 (CHP4_, CHP4);

or	g319 (power_down, PD, ENB);


reg ph_comp;
reg clkop;
reg clkop_sh;
reg clkop2x;
reg clkop05x; 
reg clkop025x; 
reg trytolock;
reg enlock1;
real tr;	
real delay;
real period;
// start mod PLL600V3_m18 by ikosarev 03.11.2023
reg [31:0] period_0_reg;
reg [31:0] period_1_reg;
reg period_reg_ch;
// end mod PLL600V3_m18 by ikosarev 03.11.2023
real period_out; 
real period_out_old; 
real periodd2;
real periodd4;
real inctime;
real offset_co;
real phase_dif;
// start mod PLL600V3_m18 by ikosarev 03.11.2023
reg [31:0] phase_dif_0_reg;
reg [31:0] phase_dif_1_reg;
reg phase_dif_reg_ch;
// end mod PLL600V3_m18 by ikosarev 03.11.2023
real offset;
real frequency;	   
integer n;
integer q;
reg offset_op;	
reg [1:0] cnt;
wire [12:0] PRCODE;
reg [12:0] cur_PRCODE;
// start mod PLL600V3_m18 by ikosarev 16.10.2023
//reg clockext05x;
wire clockext05x;
reg clockext05x_p;
reg clockext05x_n;
// end mod PLL600V3_m18 by ikosarev 16.10.2023
reg clockext025x;
// start mod PLL600V3_m18 by ikosarev 16.10.2023
reg clockext0125x;
// end mod PLL600V3_m18 by ikosarev 16.10.2023
reg unlock, unlock_strb;
integer cond;
wire _CLKDDRIN, _CLKCORE, _CLKDDROUT, _CLKCONTR;

assign PRCODE = {DIV4_, DIV3_, DIV2_, DIV1_, DIV0_,
     SYNCEN_,VCOD0_,VCOD1_,
     CHP4_, CHP3_, CHP2_, CHP1_, CHP0_};


//In other to compensate absence of delay in feedback of PLL in preliminary version of topology
//reg CLKFBKB__;
//always @ (CLKFBKB_)
//   begin
//     CLKFBKB__ <= /*#(6700 + 1500)*/ CLKFBKB_;
//   end

initial
begin	
delay=4600;
period=41600;
// start mod PLL600V3_m18 by ikosarev 03.11.2023
period_0_reg[31:0] = 41600;
period_1_reg[31:0] = 41600;
// end mod PLL600V3_m18 by ikosarev 03.11.2023
period_out=20800;
period_out_old=20800;
unlock = 1; 		
unlock_strb=0;
cond=0;
phase_dif=0;
// start mod PLL600V3_m18 by ikosarev 03.11.2023
phase_dif_0_reg[31:0] = 0;
phase_dif_1_reg[31:0] = 0;
// end mod PLL600V3_m18 by ikosarev 03.11.2023
@ (posedge BMCLK1X_);
clkop05x=0 ; 
clkop025x=0 ; 
repeat (20) @ (posedge BMCLK1X_);
unlock = 0;
end

//mesurements of period
always @(posedge BMCLK1X_)
begin
	tr=$realtime;
	@ (posedge BMCLK1X_);
    period = ($realtime-tr);
end

// start mod PLL600V3_m18 by ikosarev 03.11.2023
//latch period value
always @(posedge BMCLK1X_)
begin    
    period_0_reg[31:0] <= period;
    period_1_reg[31:0] <= period_0_reg[31:0];
end

//latch period value missmatch
always @(*)
begin
    period_reg_ch = (period_0_reg[31:0] != period_1_reg[31:0]);
end
// end mod PLL600V3_m18 by ikosarev 03.11.2023

//calculation of offset
always @(posedge CLKCONTR)
begin
    inctime = $realtime;
    @ (posedge CLKFBKB)
    phase_dif = ($realtime-inctime);  
//	$display("\n\t%m: phase_diff = %d; time=%t; inctime=%t;",phase_dif,$time,inctime); 	
end

// start mod PLL600V3_m18 by ikosarev 03.11.2023
//latch phase difference value
always @(posedge BMCLK1X_)
begin
    phase_dif_0_reg[31:0] <= phase_dif;
    phase_dif_1_reg[31:0] <= phase_dif_0_reg[31:0];
end

//latch phase difference value missmatch
always @(*)
begin
    phase_dif_reg_ch = (phase_dif_0_reg[31:0] != phase_dif_1_reg[31:0]);
end
// end mod PLL600V3_m18 by ikosarev 03.11.2023

// start mod PLL600V3_m18 by ikosarev 03.11.2023
//frequency calculation
always @ (DIV4_ or DIV3_ or DIV2_ or DIV1_ or DIV0_ or SYNCEN_ or SLOW_MEM_ or /*period*/ period_reg_ch or /*phase_dif*/ phase_dif_reg_ch)
// end mod PLL600V3_m18 by ikosarev 03.11.2023
   begin  
	 //Fout=Fin*(2<<DIV)/4
	 //Fvco=Fin*(2<<DIV)/4*(2<<VCOD)
	 @ (posedge BMCLK1X_);
	 begin				 
	   unlock<=1'b1;	   
	   repeat (20) @ (posedge BMCLK1X_);
	   case ({SYNCEN_,SLOW_MEM_})
	   2'b00: period_out=period/2/(2+{DIV4_,DIV3_,DIV2_,DIV1_,DIV0_});
	   2'b01: period_out=period/4/(2+{DIV4_,DIV3_,DIV2_,DIV1_,DIV0_});
	   2'b10: period_out=period/2;
	   2'b11: period_out=period/4;		   
	   endcase
	   frequency =1000000/period_out;
	   $display("\n\t%m: Frequency has been changed at time %t. New frequency = %6.3fMHz(T=%6.3f ns). ct_delay=%6.2f ns",$realtime,frequency/2,2*period_out/1000, phase_dif/1000); 
//	   $display("\n\t%m: period= %6.3f; period_out=%6.3f", period, period_out);
	   if(period >= 2*period_out) cond = 1; 
	   else cond=0;
       if(cond == 1) offset=3*period/2.0-period_out-phase_dif;
	   else 
  	   begin
	     n=2*period_out/period;
	     offset=(0.5+n)*period-period_out-phase_dif;
	   end
	   if (offset < 0 ) offset = 0;
	   @ (posedge BMCLK1X_);
	   unlock<= #offset 1'b0; 	    
	 end
   end					  

always  @ (negedge unlock )
begin
  //repeat (10) @ (negedge clkop05x);
  unlock_strb<=1'b1;   
  @ (negedge clkop05x);
  begin	  
    @ (negedge BMCLK1X_);
    begin
 //    unlock_strb<= #(2*period - delay) 1'b0; 
 	   unlock_strb<= #(offset) 1'b0;
	end
  end  
end

//assign unlock_strb=unlock_del^unlock;

always @ (clkop05x or negedge unlock_strb)
begin			
//  clkop <= 1'b1;	
  if(unlock)
  begin	 	
	clkop05x <= #(period_out_old) ~clkop05x; 	  
	clkop <= #(period_out_old/2) 1'b0; 
	clkop <= #(period_out_old) 1'b1; 
  end	
  else
  begin	  
	if(unlock_strb)
	begin	   
	  clkop025x <= 1'b0;	
      clkop05x <= 1'b0;	  
	  clkop <= 1'b0;
	end
	else 
    begin	 
        clkop05x <= #(period_out) ~clkop05x; 
		clkop <= #(period_out/2) 1'b0;   
		clkop <= #(period_out) 1'b1;   		
    	period_out_old <= period_out;
    end
  end   
end			  

always @ (posedge clkop05x)
   clkop025x = ~clkop025x;

// start mod PLL600V3_m18 by ikosarev 16.10.2023
initial
 //clockext05x = 0;
 clockext05x_p = 0;

always @ (posedge BMCLK1X_)
   //clockext05x = ~clockext05x;
   clockext05x_p = ~clockext05x_p;
 
initial 
 clockext05x_n = 0;

always @ (negedge BMCLK1X_)
   clockext05x_n = ~clockext05x_n;

assign clockext05x = TM2_ & clockext05x_n | ~TM2_ & clockext05x_p;
// end mod PLL600V3_m18 by ikosarev 16.10.2023

initial	
begin   
 clockext025x = 0;   
end

always @ (posedge clockext05x)
begin
	clockext025x = ~clockext025x;
end

// start mod PLL600V3_m18 by ikosarev 16.10.2023
// reg clockext0125x;
// end mod PLL600V3_m18 by ikosarev 16.10.2023

initial
begin   
 clockext0125x = 0;
end

always @ (posedge clockext025x)
begin
	clockext0125x = ~clockext0125x;
end

initial
clkop_sh = 0;

always @ (negedge _CLKDDROUT)
   clkop_sh = _CLKCONTR;

//OUTPUT MUX
assign _CLKCORE   = ~TM1_ & ((TM2_ & clockext05x)  | (~TM2_ & (clkop | power_down)));
assign _CLKDDROUT = ~TM1_ & (TM2_ & ((~SLOW_MEM_&clockext05x)|(SLOW_MEM_&clockext025x))  |  ~TM2_ & ((~SLOW_MEM_&clkop)|(SLOW_MEM_&clkop05x)) | power_down);
assign _CLKCONTR  = ~TM1_ & (TM2_ & ((~SLOW_MEM_&clockext025x)|(SLOW_MEM_&clockext0125x))  |  ~TM2_ & ((~SLOW_MEM_&clkop05x)|(SLOW_MEM_&clkop025x)) | power_down);
assign _CLKDDRIN  = ~TM1_ & (TM2_ & clkop_sh  |  ~TM2_ & (clkop_sh | power_down));	

wire _PHDB = (TM1_ & 1'bx) | (~TM1_ & (TM2_ | ph_comp));

buf	g520 (CLKDDRIN, _CLKDDRIN),
	g420 (CLKCONTR, _CLKCONTR),
    g427 (CLKDDROUT, _CLKDDROUT),
    g428 (CLKCORE, _CLKCORE),
    g421 (PHDUPB, _PHDB),	g422 (PHDDNB, _PHDB),
	g423 (MONREF, 1'bx),	 g424 (MONBCK, 1'bx);
and	g425 (DT1, 1'bx, TM1_),	 g426 (AT1, 1'bx, TM1_);
not g429 (LKDET,unlock);

specify
	if (TM2)  (BMCLK1X +=> CLKCORE) = (0.3552, 0.3819);
	(TM1 => CLKCORE) = (1.050, 1.050);
	(TM2 => CLKCORE) = (0.750, 0.750);
	( PD => CLKCORE) = (1.200, 1.200);
	(ENB => CLKCORE) = (1.200, 1.200);

	if (TM2)  (BMCLK1X +=> CLKDDRIN) = (0.3552, 0.3819);
	(TM1 => CLKDDRIN) = (1.050, 1.050);
	(TM2 => CLKDDRIN) = (0.750, 0.750);
	( PD => CLKDDRIN) = (1.200, 1.200);
	(ENB => CLKDDRIN) = (1.200, 1.200);


	if (TM2)  (BMCLK1X +=> CLKDDROUT) = (0.3552, 0.3819);
	(TM1 => CLKDDROUT) = (1.050, 1.050);
	(TM2 => CLKDDROUT) = (0.750, 0.750);
	( PD => CLKDDROUT) = (1.200, 1.200);
	(ENB => CLKDDROUT) = (1.200, 1.200);

	if (TM2)  (BMCLK1X +=> CLKCONTR) = (0.3552, 0.3819);
	(TM1 => CLKCONTR) = (1.050, 1.050);
	(TM2 => CLKCONTR) = (0.750, 0.750);
	( PD => CLKCONTR) = (1.200, 1.200);
	(ENB => CLKCONTR) = (1.200, 1.200);


endspecify

endmodule  //PLL600V3_m18
