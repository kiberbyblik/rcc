`ifndef RCC_TEST
`define RCC_TEST

class rcc_test;
  rcc_env env;
  
  function new(rcc_env env);
    this.env = env;
  endfunction

  task run(); 
    $display("run test");
  endtask

endclass

`endif 