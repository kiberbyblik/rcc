module apb_rcc_wrapper #(
  parameter int MUX_DELAY  = 2, // number of triggers in glitch-free muxes in RCC
  parameter int SYNC_DELAY = 2  // number of triggers in data_syncronizers
) (
  input  logic hw_rstn_i,
  input  logic clk_i,
  input  logic clk_strap_pin_i,
  input  logic clk_33p25_i,
  input  logic clk_25_i,
  input  logic clk_21p5_i,

  output logic clk_apb_o,
  output logic clk_axi_o,
  output logic clk_sdram_o,     // clk_sdram
  output logic clk_axi_vga_o,   // clk_eth_vga + gating
  output logic clk_apb_vga_o,   // clk_apb     + gating
  output logic clk_eth_o,       // clk_eth_vga + gating
  output logic clk_core_scr1_o, // clk_axi + gating
  output logic clk_core_cva6_o, // clk_axi + gating
  output logic clk_axi_dma_o,   // clk_axi + gating
  output logic clk_apb_dma_o,   // clk_apb + gating
  //output logic clk_spi_0_o,   // spi loading
  output logic clk_spi_1_o,     // clk_axi + gating  
  output logic clk_gpt_o,       // clk_apb + gating
  output logic clk_gpio_o,      // clk_apb + gating
  output logic clk_uart_0_o,    // clk_apb + gating
  output logic clk_uart_1_o,    // clk_apb + gating
  output logic clk_uart_l0_o,   // clk_apb + gating
  output logic clk_uart_l1_o,   // clk_apb + gating
  output logic clk_spi_l0_o,    // clk_apb + gating 
  output logic clk_spi_l1_o,    // clk_apb + gating 
  output logic clk_ps_2_0_o,    // clk_apb + gating  
  output logic clk_ps_2_1_o,    // clk_apb + gating 
  output logic clk_i2s_o,       // clk_apb + gating 
  output logic clk_i2c_o,       // clk_apb + gating 

  output logic rstn_o,
  output logic vga_rstn_o,
  output logic eth_rstn_o,
  output logic core_scr1_rstn_o,
  output logic core_cva6_rstn_o,
  output logic dma_rstn_o,
  //output logic spi_0_rstn_o,  // spi loading
  output logic spi_1_rstn_o,
  output logic gpt_rstn_o,
  output logic gpio_rstn_o,
  output logic uart_0_rstn_o,
  output logic uart_1_rstn_o,
  output logic uart_l0_rstn_o,
  output logic uart_l1_rstn_o,
  output logic spi_l0_rstn_o,
  output logic spi_l1_rstn_o,
  output logic ps_2_0_rstn_o,
  output logic ps_2_1_rstn_o,
  output logic i2s_rstn_o,
  output logic i2c_rstn_o,

  // Signals from GPR
  input apb_gpr_pkg::apb_gpr__clk_sel_reg__out_t    clk_sel,
  input apb_gpr_pkg::apb_gpr__soft_rst_reg__out_t   soft_rst,
  input apb_gpr_pkg::apb_gpr__clk_gating_reg__out_t clk_gating
);

  logic default_clk;
  logic clk_ring_gen_25;
  logic clk_25;
  logic clk_pll_133;
  logic clk_pll_100;
  logic clk_pll_25;
  logic clk_pll_86;
  logic clk_pll_43;
  logic clk_sdram;
  logic clk_eth_vga;
  logic clk_apb;
  logic clk_axi;
  logic clk_apb_mux;

  logic gating_clk_axi_vga;
  logic gating_clk_apb_vga;
  logic gating_clk_eth;
  logic gating_clk_core_scr1;
  logic gating_clk_core_cva6;
  logic gating_clk_axi_dma;
  logic gating_clk_apb_dma;
  logic gating_clk_spi_1;
  logic gating_clk_gpt;
  logic gating_clk_gpio;
  logic gating_clk_uart_0;
  logic gating_clk_uart_1;
  logic gating_clk_uart_l0;
  logic gating_clk_uart_l1;
  logic gating_clk_spi_l0;
  logic gating_clk_spi_l1;
  logic gating_clk_ps_2_0;
  logic gating_clk_ps_2_1;
  logic gating_clk_i2s;
  logic gating_clk_i2c;

  logic rstn;

  // assign rcc.strap_pin = gpio.i[0];

  rst_sync #(
    .D             ( SYNC_DELAY  )
  ) rstn_o_sync (
    .clk_i         ( default_clk ),
    .rstn_i        ( hw_rstn_i   ),
    .rst_sync_o    ( rstn        ) // for example, to gpr
  );


  //===================================================================  default_clk
  `ifdef PROTOTYPE
      clk_wiz_0 i_clk_wiz_0 (
      // Clock out ports
      .clk_out1 (default_clk),
      // Status and control signals
      .resetn   (hw_rstn_i),
      .locked   (),
      // Clock in ports
      .clk_in1  (clk_i)
    );
  `else  // SYNTHESIS or simulation
    ring_gen25 ring_gen25MHz (
      .rst_n     ( hw_rstn_i       ), // Asynchronous rst
      .clk_out   ( clk_ring_gen_25 )  // Selected generated clock 
    );
  `endif // SYNTHESIS or simulation
  
  
  `ifdef PROTOTYPE
  // always_latch begin             // TODO Nikita -> gpr
    //   if (~hw_rstn_i) begin
    //     strap_pin_latched = strap_pin;
    //   end
    // end
    //assign default_clk = clk_i; //clk_strap_pin_i ? clk_ring_gen_25 : clk_i;
  `else // SYNTHESIS or simulation
    // LD1HSP strap_latch (            // TODO Nikita -> gpr
    //   .D     ( strap_pin             ),    
    //   .G     ( ~hw_rstn_i            ), // wout sync???
    //   .Q     ( strap_pin_latched     ),    
    //   .QN    (                       ) 
    // );
  
    /*MUX21HSP handplace_clock_mux (
      .Z     ( default_clk           ),
      .A     ( clk_i                 ),
      .B     ( clk_ring_gen_25       ),
      .S     ( clk_strap_pin_i       )
    );*/
    assign default_clk = clk_strap_pin_i ? clk_ring_gen_25 : clk_i;
  `endif // SYNTHESIS or simulation
  //===================================================================  default_clk : end


  //===================================================================  clk_pll

  `ifdef PROTOTYPE
    assign clk_eth_vga  = default_clk;
    assign clk_apb      = default_clk;
    assign clk_axi      = default_clk;
    assign clk_sdram    = default_clk;
  `else // SYNTHESIS or simulation
    // TODO with doc
    PLL600V3_m18 pll_133 (
      // input 
      .TM1       ( '0   ), 
      .TM2       ( '0   ), 
      .SG1       ( '0   ), 
      .CLKFBKB   ( clk_33p25_i ),  // ???
      .BMCLK1X   ( clk_33p25_i ),  // input signal pll
      .PD        ( '0   ), 
      .ENB       ( '0   ), 
      .VCOD0     ( 1'b0 ),
      .VCOD1     ( 1'b0 ),
      .DIV0      ( 1'b0 ),
      .DIV1      ( 1'b0 ),
      .DIV2      ( 1'b0 ),
      .DIV3      ( 1'b0 ),
      .DIV4      ( 1'b0 ),
      .SYNCEN    ( 1'b1 ),
      .CHP0      ( 1'b0 ), 
      .CHP1      ( 1'b0 ), 
      .CHP2      ( 1'b1 ), 
      .CHP3      ( 1'b1 ), 
      .CHP4      ( 1'b0 ), 
      .SLOW_MEM  ( 1'b1 ),
      // output
      .CLKCORE   (             ), // FOUT
      .CLKDDROUT (             ), // FOUT/2
      .CLKCONTR  ( clk_pll_133 ), // FOUT/4
      .CLKDDRIN  (             ), // (FOUT/4)+90
      .DT1       (             ), // don't use
      .AT1       (             ), // don't use
      .LKDET     (             )  //// sync phase is output
    );

    glitch_free_mux #(
      .DELAY     ( MUX_DELAY )
    ) mux_clk_25 (
      .rstn_i    ( rstn                          ),
      .clk_a_i   ( clk_ring_gen_25               ),
      .clk_b_i   ( clk_25_i                      ),
      .sel_i     ( clk_sel.pll_clk_sel_reg.value ),
      .clk_o     ( clk_25                        )
    );

    PLL600V3_m18 pll_100_25 (
      // input 
      .TM1       ( '0   ), 
      .TM2       ( '0   ), 
      .SG1       ( '0   ), 
      .CLKFBKB   ( clk_25 ),  // ???
      .BMCLK1X   ( clk_25 ),  // input signal pll
      .PD        ( '0   ), 
      .ENB       ( '0   ), 
      .VCOD0     ( 1'b0 ),
      .VCOD1     ( 1'b0 ),
      .DIV0      ( 1'b0 ),
      .DIV1      ( 1'b0 ),
      .DIV2      ( 1'b0 ),
      .DIV3      ( 1'b0 ),
      .DIV4      ( 1'b0 ),
      .SYNCEN    ( 1'b1 ),
      .CHP0      ( 1'b0 ), 
      .CHP1      ( 1'b0 ), 
      .CHP2      ( 1'b1 ), 
      .CHP3      ( 1'b1 ), 
      .CHP4      ( 1'b0 ), 
      .SLOW_MEM  ( 1'b1 ),
      // output
      .CLKCORE   ( clk_pll_25  ), // FOUT
      .CLKDDROUT ( clk_pll_100 ), // FOUT/2
      .CLKCONTR  (             ), // FOUT/4
      .CLKDDRIN  (             ), // (FOUT/4)+90
      .DT1       (             ), // don't use
      .AT1       (             ), // don't use
      .LKDET     (             )  //// sync phase is output
    );

    PLL600V3_m18 pll_86_43 (
      // input 
      .TM1       ( '0   ), 
      .TM2       ( '0   ), 
      .SG1       ( '0   ), 
      .CLKFBKB   ( clk_21p5_i ),  // ???
      .BMCLK1X   ( clk_21p5_i ),  // input signal pll
      .PD        ( '0   ), 
      .ENB       ( '0   ), 
      .VCOD0     ( 1'b0 ),
      .VCOD1     ( 1'b0 ),
      .DIV0      ( 1'b0 ),
      .DIV1      ( 1'b0 ),
      .DIV2      ( 1'b0 ),
      .DIV3      ( 1'b0 ),
      .DIV4      ( 1'b0 ),
      .SYNCEN    ( 1'b1 ),
      .CHP0      ( 1'b0 ), 
      .CHP1      ( 1'b0 ), 
      .CHP2      ( 1'b1 ), 
      .CHP3      ( 1'b1 ), 
      .CHP4      ( 1'b0 ), 
      .SLOW_MEM  ( 1'b1 ),
      // output
      .CLKCORE   (             ), // FOUT
      .CLKDDROUT ( clk_pll_43  ), // FOUT/2
      .CLKCONTR  ( clk_pll_86  ), // FOUT/4
      .CLKDDRIN  (             ), // (FOUT/4)+90
      .DT1       (             ), // don't use
      .AT1       (             ), // don't use
      .LKDET     (             )  //// sync phase is output
    );
  `endif // SYNTHESIS or simulation

  // TODO wrapper
  // PLL600V3_m18_wrapper pll_133 (
  //   .clk_i  ( clk_33p25_i ),
  //   .clk_o  (             ),
  //   .clk2_o (             ),
  //   .clk4_o ( clk_pll_133 )
  // );
  
  // PLL600V3_m18_wrapper pll_100_25 (
  //   .clk_i  ( clk_25      ),
  //   .clk_o  ( clk_pll_25  )
  //   .clk2_o ( clk_pll_100 ),
  //   .clk4_o (             )
  // );
  
  // PLL600V3_m18_wrapper pll_86_43 (
  //   .clk_i  ( clk_21p5_i  ),
  //   .clk_o  (             )
  //   .clk2_o ( clk_pll_43 ),
  //   .clk4_o ( clk_pll_86  )
  // );  
  //===================================================================  clk_pll : end


  //===================================================================  clk_sdram, clk_eth_vga, clk_apb, clk_axi

  `ifdef PROTOTYPE

  `else // SYNTHESIS or simulation
    glitch_free_mux_3 #(
      .DELAY     ( MUX_DELAY )
    ) mux_sdram_clk_sel (
      .rstn_i    ( rstn                            ),
      .clk_a_i   ( default_clk                     ),
      .clk_b_i   ( clk_pll_25                      ),
      .clk_c_i   ( clk_pll_133                     ),
      .sel_i     ( clk_sel.sdram_clk_sel_reg.value ),
      .clk_o     ( clk_sdram                       )
    );

    assign clk_eth_vga = clk_pll_100;


    glitch_free_mux #(
      .DELAY     ( MUX_DELAY )
    ) mux_pll_86_43_sel (
      .rstn_i    ( rstn                          ),
      .clk_a_i   ( clk_pll_43                    ),
      .clk_b_i   ( clk_pll_86                    ),
      .sel_i     ( clk_sel.apb_clk_sel_reg.value ),
      .clk_o     ( clk_apb_mux                   )
    );

    glitch_free_mux_3 #(
      .DELAY     ( MUX_DELAY )
    ) mux_apb_clk_sel (
      .rstn_i    ( rstn                              ),
      .clk_a_i   ( default_clk                       ),
      .clk_b_i   ( clk_pll_25                        ),
      .clk_c_i   ( clk_apb_mux                       ),
      .sel_i     ( clk_sel.axi_apb_clk_sel_reg.value ),
      .clk_o     ( clk_apb                           )
    );

    
    glitch_free_mux_3 #(
      .DELAY     ( MUX_DELAY )
    ) mux_axi_clk_sel (
      .rstn_i    ( rstn                              ),
      .clk_a_i   ( default_clk                       ),
      .clk_b_i   ( clk_pll_25                        ),
      .clk_c_i   ( clk_pll_86                        ),
      .sel_i     ( clk_sel.axi_apb_clk_sel_reg.value ),
      .clk_o     ( clk_axi                           )
    );
  `endif // SYNTHESIS or simulation
  //===================================================================  clk_sdram, clk_eth_vga, clk_apb, clk_axi : end


  //===================================================================  clk_gating
  
  `ifdef PROTOTYPE
    always_comb begin
        gating_clk_axi_vga   = clk_eth_vga & clk_gating.clk_gating_vga.value;
        gating_clk_apb_vga   = clk_apb     & clk_gating.clk_gating_vga.value;
        gating_clk_eth       = clk_eth_vga & clk_gating.clk_gating_ethernet.value;
        gating_clk_core_scr1 = clk_axi     & clk_gating.clk_gating_scr1.value;
        gating_clk_core_cva6 = clk_axi     & clk_gating.clk_gating_cva6.value;
        gating_clk_axi_dma   = clk_axi     & clk_gating.clk_gating_dma.value;
        gating_clk_apb_dma   = clk_apb     & clk_gating.clk_gating_dma.value;
        gating_clk_spi_1     = clk_axi; // & clk_gating.clk_gating_spi_1.value;   
        gating_clk_gpt       = clk_apb     & clk_gating.clk_gating_gpt.value;
        gating_clk_gpio      = clk_apb; // & clk_gating.clk_gating_gpio.value;
        gating_clk_uart_0    = clk_apb     & clk_gating.clk_gating_uart_0.value;
        gating_clk_uart_1    = clk_apb     & clk_gating.clk_gating_uart_1.value;
        gating_clk_uart_l0   = clk_apb     & clk_gating.clk_gating_uart_l0.value;
        gating_clk_uart_l1   = clk_apb     & clk_gating.clk_gating_uart_l1.value;
        gating_clk_spi_l0    = clk_apb     & clk_gating.clk_gating_spi_l0.value;
        gating_clk_spi_l1    = clk_apb     & clk_gating.clk_gating_spi_l1.value;
        gating_clk_ps_2_0    = clk_apb     & clk_gating.clk_gating_ps2_0.value;
        gating_clk_ps_2_1    = clk_apb     & clk_gating.clk_gating_ps2_1.value;
        gating_clk_i2s       = clk_apb     & clk_gating.clk_gating_i2s.value;
        gating_clk_i2c       = clk_apb     & clk_gating.clk_gating_i2c.value;
      end
      // CBUFL_HS_X4
      // CBUFL - latch based clock gating
      // HS    - high speed
      // X4    - load (4), can be none (1) and P (2)
      // G  - clk output 
      // CP - clk input
      // E  - clk enable, if 0 - clock disabled
      // TE - for test
  `else
      CBUFLHSX4 inst_axi_vga   ( .G( gating_clk_axi_vga   ),  .CP( clk_eth_vga ),  .E( clk_gating.clk_gating_vga.value      ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_apb_vga   ( .G( gating_clk_apb_vga   ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_vga.value      ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_eth       ( .G( gating_clk_eth       ),  .CP( clk_eth_vga ),  .E( clk_gating.clk_gating_ethernet.value ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_core_scr1 ( .G( gating_clk_core_scr1 ),  .CP( clk_axi     ),  .E( clk_gating.clk_gating_scr1.value     ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_core_cva6 ( .G( gating_clk_core_cva6 ),  .CP( clk_axi     ),  .E( clk_gating.clk_gating_cva6.value     ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_axi_dma   ( .G( gating_clk_axi_dma   ),  .CP( clk_axi     ),  .E( clk_gating.clk_gating_dma.value      ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_apb_dma   ( .G( gating_clk_apb_dma   ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_dma.value      ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_spi_1     ( .G( gating_clk_spi_1     ),  .CP( clk_axi     ),  .E( 1'b1                                 ),  .TE( 1'b0 ) ); // clk_gating.clk_gating_spi_1.value
      CBUFLHSX4 inst_gpt       ( .G( gating_clk_gpt       ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_gpt.value      ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_gpio      ( .G( gating_clk_gpio      ),  .CP( clk_apb     ),  .E( 1'b1                                 ),  .TE( 1'b0 ) ); // clk_gating.clk_gating_gpio.value
      CBUFLHSX4 inst_uart_0    ( .G( gating_clk_uart_0    ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_uart_0.value   ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_uart_1    ( .G( gating_clk_uart_1    ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_uart_1.value   ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_uart_l0   ( .G( gating_clk_uart_l0   ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_uart_l0.value  ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_uart_l1   ( .G( gating_clk_uart_l1   ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_uart_l1.value  ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_spi_l0    ( .G( gating_clk_spi_l0    ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_spi_l0.value   ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_spi_l1    ( .G( gating_clk_spi_l1    ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_spi_l1.value   ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_ps_2_0    ( .G( gating_clk_ps_2_0    ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_ps2_0.value    ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_ps_2_1    ( .G( gating_clk_ps_2_1    ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_ps2_1.value    ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_i2s       ( .G( gating_clk_i2s       ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_i2s.value      ),  .TE( 1'b0 ) );
      CBUFLHSX4 inst_i2c       ( .G( gating_clk_i2c       ),  .CP( clk_apb     ),  .E( clk_gating.clk_gating_i2c.value      ),  .TE( 1'b0 ) );
  `endif
  //===================================================================  clk_gating : end


  //===================================================================  clk_o
  assign clk_apb_o       = clk_apb;
  assign clk_axi_o       = clk_axi;
  assign clk_sdram_o     = clk_sdram;
  assign clk_axi_vga_o   = gating_clk_axi_vga;
  assign clk_apb_vga_o   = gating_clk_apb_vga;
  assign clk_eth_o       = gating_clk_eth;
  assign clk_core_scr1_o = gating_clk_core_scr1;
  assign clk_core_cva6_o = gating_clk_core_cva6;
  assign clk_axi_dma_o   = gating_clk_axi_dma;
  assign clk_apb_dma_o   = gating_clk_apb_dma;
  assign clk_spi_1_o     = gating_clk_spi_1;
  assign clk_gpt_o       = gating_clk_gpt;
  assign clk_gpio_o      = gating_clk_gpio;
  assign clk_uart_0_o    = gating_clk_uart_0;
  assign clk_uart_1_o    = gating_clk_uart_1;
  assign clk_uart_l0_o   = gating_clk_uart_l0;
  assign clk_uart_l1_o   = gating_clk_uart_l1;
  assign clk_spi_l0_o    = gating_clk_spi_l0;
  assign clk_spi_l1_o    = gating_clk_spi_l1;
  assign clk_ps_2_0_o    = gating_clk_ps_2_0;
  assign clk_ps_2_1_o    = gating_clk_ps_2_1;
  assign clk_i2s_o       = gating_clk_i2s;
  assign clk_i2c_o       = gating_clk_i2c;
  //===================================================================  clk_o : end


  //===================================================================  rstn_o
  assign rstn_o           = rstn;
  assign vga_rstn_o       = soft_rst.soft_rst_vga.value;
  assign eth_rstn_o       = soft_rst.soft_rst_ethernet.value;
  assign core_scr1_rstn_o = soft_rst.soft_rst_scr1.value;
  assign core_cva6_rstn_o = soft_rst.soft_rst_cva6.value;
  assign dma_rstn_o       = soft_rst.soft_rst_dma.value;
  assign spi_1_rstn_o     = rstn; // soft_rst.soft_rst_spi_1.value;
  assign gpt_rstn_o       = soft_rst.soft_rst_gpt.value;
  assign gpio_rstn_o      = rstn; // soft_rst.soft_rst_gpio.value;
  assign uart_0_rstn_o    = soft_rst.soft_rst_uart_0.value;
  assign uart_1_rstn_o    = soft_rst.soft_rst_uart_1.value;
  assign uart_l0_rstn_o   = soft_rst.soft_rst_uart_l0.value;
  assign uart_l1_rstn_o   = soft_rst.soft_rst_uart_l1.value;
  assign spi_l0_rstn_o    = soft_rst.soft_rst_spi_l0.value;
  assign spi_l1_rstn_o    = soft_rst.soft_rst_spi_l1.value;
  assign ps_2_0_rstn_o    = soft_rst.soft_rst_ps2_0.value;
  assign ps_2_1_rstn_o    = soft_rst.soft_rst_ps2_1.value;
  assign i2s_rstn_o       = soft_rst.soft_rst_i2s.value;
  assign i2c_rstn_o       = soft_rst.soft_rst_i2c.value;
  //===================================================================  rstn_o : end

  
  // Описание структур (для удобства):

  // Структура clk_sel:
  //  0. clk_sel.pll_clk_sel_reg.value[0];
  //  2:1. clk_sel.sdram_clk_sel_reg.value[1:0];
  //  3. clk_sel.apb_clk_sel_reg.value[0];
  //  5:4. clk_sel.axi_apb_clk_sel_reg.value[1:0];

  // Структура soft_rst:
  //  0.  soft_rst.soft_rst_dma.value[0];
  //  1.  soft_rst.soft_rst_scr1.value[0];
  //  2.  soft_rst.soft_rst_cva6.value[0];
  //  3.  soft_rst.soft_rst_gpt.value[0];
  //  4.  soft_rst.soft_rst_uart_0.value[0];
  //  5.  soft_rst.soft_rst_uart_1.value[0];
  //  6.  soft_rst.soft_rst_uart_l0.value[0];
  //  7.  soft_rst.soft_rst_uart_l1.value[0];
  //  8.  soft_rst.soft_rst_spi_l0.value[0];
  //  9.  soft_rst.soft_rst_spi_l1.value[0];
  //  10. soft_rst.soft_rst_ps2_0.value[0];
  //  11. soft_rst.soft_rst_ps2_1.value[0];
  //  12. soft_rst.soft_rst_i2c.value[0];
  //  13. soft_rst.soft_rst_i2s.value[0];
  //  14. soft_rst.soft_rst_ethernet.value[0];
  //  15. soft_rst.soft_rst_vga.value[0];

  // Структура clk_gating:
  //  0.  clk_gating.clk_gating_scr1.value[0];
  //  1.  clk_gating.clk_gating_dma.value[0];
  //  2.  clk_gating.clk_gating_cva6.value[0];
  //  3.  clk_gating.clk_gating_gpt.value[0];
  //  4.  clk_gating.clk_gating_uart_0.value[0];
  //  5.  clk_gating.clk_gating_uart_1.value[0];
  //  6.  clk_gating.clk_gating_uart_l0.value[0];
  //  7.  clk_gating.clk_gating_uart_l1.value[0];
  //  8.  clk_gating.clk_gating_spi_l0.value[0];
  //  9.  clk_gating.clk_gating_spi_l1.value[0];
  //  10. clk_gating.clk_gating_ps2_0.value[0];
  //  11. clk_gating.clk_gating_ps2_1.value[0];
  //  12. clk_gating.clk_gating_i2c.value[0];
  //  13. clk_gating.clk_gating_i2s.value[0];
  //  14. clk_gating.clk_gating_ethernet.value[0];
  //  15. clk_gating.clk_gating_vga.value[0];
  
endmodule

