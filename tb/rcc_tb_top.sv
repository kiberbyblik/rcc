`ifndef RCC_TB_TOP
`define RCC_TB_TOP

`include "rcc_defines.sv"
`include "rcc_env_if.sv"
`include "rcc_env.sv"
`include "rcc_test.sv"
`include "rcc_stub.sv"

module rcc_tb_top;

  rcc_env_if env_if();

  rcc_env    env;

  rcc_test   test;
  `ifndef STUB
    apb_rcc_wrapper
    #(
      .MUX_DELAY   (`MUX_DELAY),
      .SYNC_DELAY  (`SYNC_DELAY)
    )
    apb_rcc_wrapper
    (
      .clk_i                 (env_if.clk_i_if.clk), 
      .hw_rstn_i             (env_if.hw_rstn_if.rst_n),
      .clk_strap_pin_i       (env_if.strap_pin),
      .clk_33p25_i           (env_if.clk_33p25_if_i.clk),
      .clk_25_i              (env_if.clk_25_if_i.clk),
      .clk_21p5_i            (env_if.clk_21p5_if_i.clk),

      .clk_sdram_o           (env_if.clk_sdram_o),
      .clk_apb_o             (env_if.clk_apb_o),
      .clk_axi_o             (env_if.clk_axi_o),
      .rstn_o                (env_if.rstn_o),
      .vga_rstn_o            (env_if.vga_rstn_o),
      .eth_rstn_o            (env_if.eth_rstn_o),
      .core_scr1_rstn_o      (env_if.core_scr1_rstn_o),
      .core_cva6_rstn_o      (env_if.core_cva6_rstn_o),
      .dma_rstn_o            (env_if.dma_rstn_o),
      .gpt_rstn_o            (env_if.gpt_rstn_o),
      .gpio_rstn_o           (env_if.gpio_rstn_o),
      .uart_0_rstn_o         (env_if.uart_0_rstn_o),
      .uart_1_rstn_o         (env_if.uart_1_rstn_o),
      .uart_l0_rstn_o        (env_if.uart_l0_rstn_o),
      .uart_l1_rstn_o        (env_if.uart_l1_rstn_o),
      .spi_l0_rstn_o         (env_if.spi_l0_rstn_o),
      .spi_l1_rstn_o         (env_if.spi_l1_rstn_o),
      .ps_2_0_rstn_o         (env_if.ps_2_0_rstn_o),
      .ps_2_1_rstn_o         (env_if.ps_2_1_rstn_o),
      .i2s_rstn_o            (env_if.i2s_rstn_o),
      .i2c_rstn_o            (env_if.i2c_rstn_o),
      .clk_axi_vga_o          (env_if.clk_axi_vga_o),
      .clk_apb_vga_o          (env_if.clk_apb_vga_o),
      .clk_eth_o              (env_if.clk_eth_o),    
      .clk_core_scr1_o        (env_if.clk_core_scr1_o), 
      .clk_core_cva6_o        (env_if.clk_core_cva6_o), 
      .clk_axi_dma_o          (env_if.clk_axi_dma_o),   
      .clk_apb_dma_o          (env_if.clk_apb_dma_o),
      .clk_spi_1_o            (env_if.clk_spi_1_o),     
      .clk_gpt_o              (env_if.clk_gpt_o),     
      .clk_gpio_o             (env_if.clk_gpio_o),    
      .clk_uart_0_o           (env_if.clk_uart_0_o),  
      .clk_uart_1_o           (env_if.clk_uart_1_o),  
      .clk_uart_l0_o          (env_if.clk_uart_l0_o), 
      .clk_uart_l1_o          (env_if.clk_uart_l1_o), 
      .clk_spi_l0_o           (env_if.clk_spi_l0_o),   
      .clk_spi_l1_o           (env_if.clk_spi_l1_o),   
      .clk_ps_2_0_o           (env_if.clk_ps_2_0_o),    
      .clk_ps_2_1_o           (env_if.clk_ps_2_1_o),   
      .clk_i2s_o              (env_if.clk_i2s_o),      
      .clk_i2c_o              (env_if.clk_i2c_o),  

      .clk_sel('{
         pll_clk_sel_reg:     '{value: env_if.clk_sel_in.pll_clk_sel},  
         sdram_clk_sel_reg:   '{value: env_if.clk_sel_in.sdram_clk_sel},
         apb_clk_sel_reg:     '{value: env_if.clk_sel_in.apb_clk_sel},
         axi_apb_clk_sel_reg: '{value: env_if.clk_sel_in.axi_apb_clk_sel}
       })       
      // .soft_rst               (env_if.soft_rst),
      // .clk_gating             (env_if.clk_gating),    

    );   
  `else 
    rcc_stub 
    #(
        .MUX_DELAY   (`MUX_DELAY),
        .SYNC_DELAY  (`SYNC_DELAY)
    )
    rcc_stub
    (
        .clk_i                 (env_if.clk_i_if.clk), 
        .hw_rstn_i             (env_if.hw_rstn_if.rst_n),
        .clk_sdram_o           (env_if.clk_sdram_if_o.clk)
    );
  `endif

  initial begin
    // Set time format
    $timeformat(-12, 0, " ps", 10);

    // Creating environment
    env = new(env_if);

    // Creating test
    test = new(env);

    // Calling run of test
    test.run();
  end

endmodule : rcc_tb_top

`endif // !RCC_TB_TOP