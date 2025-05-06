`ifndef INC_RCC_STUB
`define INC_RCC_STUB
// pragma protect
// pragma protect begin
module rcc_stub
#(
    //< Parameters
    parameter MUX_DELAY = 2,
    parameter SYNC_DELAY   = 2
)
(
    input                          clk_i,
    input                          hw_rstn_i,

    output                         clk_sdram_o
);

forever begin
    #10;
    clk_sdram_o <= ~clk_sdram_o;
end  

endmodule

`endif