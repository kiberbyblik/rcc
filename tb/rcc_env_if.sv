`ifndef RCC_ENV_IF
`define RCC_ENV_IF

interface rcc_env_if();
  
  // Clock and Reset interfaces
  clk_agent_if         clk_i_if      ();
  clk_agent_if         clk_sdram_if_o ();
  rst_agent_if         hw_rstn_if      ();

endinterface

`endif // !RCC_ENV_IF