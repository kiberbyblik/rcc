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

  rcc_stub 
  #(
      .MUX_DELAY   (`MUX_DELAY),
      .SYNC_DELAY  (`SYNC_DELAY)
  )
  rcc
  (
      .clk_i                 (env_if.clk_i_if.clk), 
      .hw_rstn_i             (env_if.hw_rstn_if.rst_n),
      .clk_sdram_o           (env_if.clk_sdram_if_o.clk)
  );

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