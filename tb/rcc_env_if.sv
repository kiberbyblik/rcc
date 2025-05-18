`ifndef RCC_ENV_IF
`define RCC_ENV_IF

import rcc_pkg::*;

interface rcc_env_if();
  
  // Clock and Reset interfaces
  logic strap_pin;
  logic clk_sdram_o     ;
  logic clk_apb_o       ;
  logic clk_axi_o       ;
  logic rstn_o          ;
  logic vga_rstn_o      ;
  logic eth_rstn_o      ;
  logic core_scr1_rstn_o;
  logic core_cva6_rstn_o;
  logic dma_rstn_o      ;
  logic gpt_rstn_o      ;
  logic gpio_rstn_o     ;
  logic uart_0_rstn_o   ;
  logic uart_1_rstn_o   ;
  logic uart_l0_rstn_o  ;
  logic uart_l1_rstn_o  ;
  logic spi_l0_rstn_o   ;
  logic spi_l1_rstn_o   ;
  logic ps_2_0_rstn_o   ;
  logic ps_2_1_rstn_o   ;
  logic i2s_rstn_o      ;
  logic i2c_rstn_o      ;
  logic clk_axi_vga_o;
  logic clk_apb_vga_o;
  logic clk_eth_o;
  logic clk_core_scr1_o;
  logic clk_core_cva6_o;
  logic clk_axi_dma_o;
  logic clk_apb_dma_o;
  logic clk_spi_1_o;
  logic clk_gpt_o;
  logic clk_gpio_o;
  logic clk_uart_0_o;
  logic clk_uart_1_o;
  logic clk_uart_l0_o;
  logic clk_uart_l1_o;
  logic clk_spi_l0_o;
  logic clk_spi_l1_o;
  logic clk_ps_2_0_o;
  logic clk_ps_2_1_o;
  logic clk_i2s_o;
  logic clk_i2c_o;

  clk_sel_in_s clk_sel_in;

  clk_agent_if         clk_i_if       ();
  rst_agent_if         hw_rstn_if     ();
  clk_agent_if         clk_33p25_if_i ();
  clk_agent_if         clk_25_if_i    ();
  clk_agent_if         clk_21p5_if_i  ();

endinterface

`endif // !RCC_ENV_IF