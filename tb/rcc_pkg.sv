`ifndef RCC_PKG
`define RCC_PKG

`include "rcc_defines.sv"

package rcc_pkg;

  typedef struct packed {
    logic pll_clk_sel;
    logic [1:0] sdram_clk_sel ;
    logic apb_clk_sel;
    logic [1:0] axi_apb_clk_sel;
  } clk_sel_in_s;

endpackage

`endif //!RCC_PKG
