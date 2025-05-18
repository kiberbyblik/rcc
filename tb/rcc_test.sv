`ifndef RCC_TEST
`define RCC_TEST

class rcc_test;
  rcc_env env;
  clk_transaction        clk_i_transaction;
  clk_transaction        clk_33_25_transaction;
  clk_transaction        clk_25_transaction;
  clk_transaction        clk_21_5_transaction;
  rst_transaction        rst_transaction;
  
  function new(rcc_env env);
    this.env = env;
  endfunction

  task clk_i_transaction_put(real t_period);
    clk_i_transaction  = new();
    clk_i_transaction.period = t_period;
    env.clk_i_agent.to_driver.put(clk_i_transaction);
  endtask

  task clk_33_25_transaction_put(real t_period);
    clk_33_25_transaction  = new();
    clk_33_25_transaction.period = t_period;
    env.clk_33_25_agent.to_driver.put(clk_33_25_transaction);
  endtask

  task clk_25_transaction_put(real t_period);
    clk_25_transaction  = new();
    clk_25_transaction.period = t_period;
    env.clk_25_agent.to_driver.put(clk_25_transaction);
  endtask

  task clk_21_5_transaction_put(real t_period);
    clk_21_5_transaction  = new();
    clk_21_5_transaction.period = t_period;
    env.clk_21_5_agent.to_driver.put(clk_21_5_transaction);
  endtask

 task rst_transaction_put(int t_duration);
    rst_transaction  = new();
    rst_transaction.duration = t_duration;
    env.hw_rstn_agent.to_driver.put(rst_transaction);
  endtask

  task run(); 
    $display("run test");
    fork
      begin
        env.run();
      end
      begin
        base_test();  
        #100ns;
        $finish;
      end
      join_none
  endtask

task base_test();
  fork
    begin
      env.vif.strap_pin = 1'b0;
      env.vif.clk_sel_in.pll_clk_sel = 1'b1;
      clk_i_transaction_put($urandom_range(36, 20));
      clk_33_25_transaction_put(`CLOCK_PERIOD_33_25_MHZ);
      clk_25_transaction_put(`CLOCK_PERIOD_25_MHZ);
      clk_21_5_transaction_put(`CLOCK_PERIOD_21_5_MHZ);
      @(posedge env.vif.clk_i_if.clk);
      rst_transaction_put(50);  
    end
  join_none
endtask

endclass

`endif 