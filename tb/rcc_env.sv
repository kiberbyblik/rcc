`ifndef RCC_ENV
`define RCC_ENV

`include "clk_agent.sv"
`include "rst_agent.sv"
// `include "icon_scoreboard.sv"

class rcc_env;

  // Agents instances
  clk_agent               clk_i_agent;
  clk_agent               clk_33_25_agent;
  clk_agent               clk_25_agent;
  clk_agent               clk_21_5_agent;
  rst_agent               hw_rstn_agent;

  // Virtual interface
  virtual rcc_env_if vif;

  // Constructor
  function new(virtual rcc_env_if vif);
    
    this.vif = vif;

    // Creating agents
    this.clk_i_agent             = new(vif.clk_i_if);
    this.hw_rstn_agent           = new(vif.hw_rstn_if);
    this.clk_33_25_agent         = new(vif.clk_33p25_if_i);
    this.clk_25_agent            = new(vif.clk_25_if_i);
    this.clk_21_5_agent          = new(vif.clk_21p5_if_i);

    // Creating scoreboard
    // this.scrb                = new();
  endfunction

  // Test phases
  task pre_main();

  endtask
  
  task main();
    fork
      clk_i_agent.run();
      hw_rstn_agent.run();
      clk_33_25_agent.run();
      clk_25_agent.run();
      clk_21_5_agent.run();
    join_none
  endtask

  // Run task
  task run;
    pre_main();
    main();
  endtask

endclass

`endif //!RCC_ENV