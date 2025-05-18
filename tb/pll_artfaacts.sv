`ifndef INC_YMP_ELCT_PLL_INT_ENV_IF
`define INC_YMP_ELCT_PLL_INT_ENV_IF


interface automatic ymp_elct_pll_int_env_if#(parameter bit YMP_ONLY_PLL_INT=0, parameter string MY_ID="ymp_elct_pll_int_env_if");

  import ymp_elct_pll_int_utils_pkg::*;
  //---- Time unit and time precision
  timeunit 1ns;
  timeprecision 1ps;


  //---- Packages
  import ymp_elct_pll_int_typedefs_pkg::*;
  import uvm_pkg::*;


  //---- Typedefs
  typedef enum {
    MAX,
    MIN
  } min_max_e;


  //---- Parameters
  // localparam string MY_ID = "ymp_elct_pll_int_env_if";

  function void switch_assert (bit switch_if);
    if (switch_if) begin
      $asserton(0, ymp_elct_pll_int_env_if);
    end else begin
      $assertoff(0, ymp_elct_pll_int_env_if);
    end
  endfunction

  //---- Interfaces
  ymp_reset_if apb_mst_reset_if ();
  ymp_reset_if apb_slv_reset_if ();
  
  ymp_clk_if apb_clk_if     ();
  ymp_clk_if clk_ext_cml_if ();
  ymp_clk_if clk_ext_if     ();
  ymp_clk_if clk_ref_if     ();

  ymp_clk_if clk_out_if ();

  svt_apb_if apb_if ();
   
  ymp_gpio_if pll_lock_gpio_if (.clk(apb_clk_if.clk), .rst(apb_mst_reset_if.common_reset));
  ymp_gpio_if pll_gpio_if      (.clk(apb_clk_if.clk), .rst(apb_mst_reset_if.common_reset));
  ymp_gpio_if pll_irq_gpio_if  (.clk(apb_clk_if.clk), .rst(apb_mst_reset_if.common_reset));

  //---- Variables
  realtime freq_delta;
  clk_out_sel_e sel_clk;
  clk_out_sel_e sel_clk_latch;
  clk_out_sel_e sel_clk_last;


  realtime t_ref, tres_ref;
  realtime t_ext, tres_ext;
  realtime t_p,   tres_p;
  realtime t_out, tres_out;
  realtime tres_stable, tres_en_clk;
  realtime lower_bound, upper_bound;

  realtime last_out_clk;
  realtime clk_watchdog_threshold;
  realtime pll_macro_half_period;

  realtime clk_ext_freq_hz;
  realtime clk_cml_freq_hz;
  realtime clk_ref_freq_hz;
  realtime clk_apb_freq_hz;
  realtime clk_ext_last_posedge;
  realtime clk_cml_last_posedge;
  realtime clk_ref_last_posedge;
  realtime clk_apb_last_posedge;

  bit bypass_ref_pll_changed;
  bit clk_en_change;
  bit clk_delay_after_reset;
  bit first_pulse_after_enable = 0;
  bit first_pulse_after_reset  = 0;
  bit switch;
  bit clk_en;
  bit dis_check;

  event check_e;
  event clk_out_changed;

  `include "if/ymp_pll_int_env_if_service_impl.sv"
  
  // Measure clk apb frequency
  always @(posedge apb_if.pclk) begin
    clk_apb_freq_hz      = 1.0/($realtime-clk_apb_last_posedge)*1.0s;
    clk_apb_last_posedge = $realtime;
  end


  // Measure clk out half period
  always @(clk_out_if.clk) begin
    if(first_pulse_after_enable) begin
      t_out                    = $realtime();
      first_pulse_after_enable = 0;
    end else begin
      last_out_clk = $realtime;
    end
    tres_out = $realtime()-t_out;
    t_out    = $realtime();
    ->> check_e;
    ->> clk_out_changed;
  end


  // Measure clk ext half period
  always @(clk_ext_if.clk) begin
    tres_ext = $realtime()-t_ext;
    t_ext    = $realtime();
    if (sel_clk == CLK_OUT_SEL_EXT)
      ->> check_e;
    if (clk_ext_if.clk) begin
      clk_ext_freq_hz      = 1.0/($realtime-clk_ext_last_posedge)*1.0s;
      clk_ext_last_posedge = $realtime;
    end
  end


  // Measure clk cml half period
  always @(clk_ext_cml_if.clk) begin
    tres_p = $realtime()-t_p;
    t_p    = $realtime();
    if (sel_clk == CLK_OUT_SEL_EXT_CML)
      ->> check_e;
    if (clk_ext_cml_if.clk) begin
      clk_cml_freq_hz      = 1.0/($realtime-clk_cml_last_posedge)*1.0s;
      clk_cml_last_posedge = $realtime;
    end
  end


  // Measure clk ref half period
  always @(clk_ref_if.clk) begin
    tres_ref = $realtime()-t_ref;
    t_ref    = $realtime();
    if (sel_clk == CLK_OUT_SEL_REF)
      ->> check_e;
    if (clk_ref_if.clk) begin
      clk_ref_freq_hz      = 1.0/($realtime-clk_ref_last_posedge)*1.0s;
      clk_ref_last_posedge = $realtime;
    end
  end


  // Detect clk_en change
  always @(clk_en) begin
    if(apb_slv_reset_if.common_reset) begin
      clk_en_change = 1;

      if (clk_en) begin // posedge
        first_pulse_after_enable = 1;
      end
    end
  end


  // Detect clk_en change
  always @(sel_clk) begin
    if(apb_slv_reset_if.common_reset) begin
      sel_clk_last  = sel_clk_latch;
      sel_clk_latch = sel_clk;
      switch        = 1'b1;
    end
  end


  // Generate events for the pll hardmacro clk
  initial begin
    forever begin
      if (pll_macro_half_period == 0) begin
        wait(pll_macro_half_period != 0);
      end
      #pll_macro_half_period;
      if (sel_clk == CLK_OUT_SEL_PLL_MACRO) begin
        ->> check_e;
      end
    end
  end


  // Clk out timeout check
  initial begin
    forever begin
      wait (last_out_clk != 0);
      @(check_e);

      if (!clk_delay_after_reset) begin
        if (!switch) begin
          clk_watchdog_threshold = get_duration(sel_clk)+freq_delta;
        end else if (switch) begin
          clk_watchdog_threshold = find_min_max_half_period(MAX, '{sel_clk_last, sel_clk})*2*`CLK_OUT_FROZEN_DURING_SWITCH_NUM_CYCLES;
          if (are_there_both_glitchfree_mux_involved() && bypass_ref_pll_changed) begin
            clk_watchdog_threshold += `CLK_OUT_FROZEN_DURING_SWITCH_NUM_CYCLES*2*find_min_max_half_period(MAX, '{CLK_OUT_SEL_REF, CLK_OUT_SEL_PLL_MACRO});
          end
        end
      end else begin
        clk_watchdog_threshold = find_min_max_half_period(MAX, '{CLK_OUT_SEL_EXT,
                                                                 CLK_OUT_SEL_EXT_CML,
                                                                 CLK_OUT_SEL_REF,
                                                                 CLK_OUT_SEL_PLL_MACRO})*2*(3+`CLK_OUT_FROZEN_DURING_SWITCH_NUM_CYCLES*2)+freq_delta;
      end

      if ((($realtime-last_out_clk) > clk_watchdog_threshold) && clk_en && last_out_clk != 0) begin
        `uvm_error(MY_ID, $sformatf("Watchdog timeout! No clock toggle within %0t", clk_watchdog_threshold));
      end

      if ((($realtime-last_out_clk) > clk_watchdog_threshold) && !clk_en) begin
        tres_out     = 0;
        last_out_clk = 0;
      end
    end
  end


 // Clk delay after reset
  initial begin
    realtime clk_delay;

    forever begin
      wait(apb_slv_reset_if.common_reset === 1'b0);
      clk_delay_after_reset = 1'b1;
      clk_delay             = find_min_max_half_period(MAX, '{CLK_OUT_SEL_EXT,
                                                              CLK_OUT_SEL_EXT_CML,
                                                              CLK_OUT_SEL_REF,
                                                              CLK_OUT_SEL_PLL_MACRO})*2*`CLK_RST_DELAY;
      #clk_delay;
      clk_delay_after_reset = 1'b0;
      wait(apb_slv_reset_if.common_reset === 1'b1);
    end
  end


  initial begin
    process id_switch;
    process id_gate;

    wait_reset_assert();
    reset_logic();
    wait(!dis_check);
    wait_reset_deassert();
    forever begin
      fork 
        begin : reset_process
          wait_reset_assert();
        end : reset_process

        begin : main_loop
          fork
            begin : clk_disable_stable_check
              forever begin
                @(check_e);
                if (!clk_en_change && !clk_en) begin
                  if (tres_out != 0) begin
                    `uvm_error(MY_ID, $sformatf("There is an impulse on the clk_out port when en_clk=0. Expected clk_out period: --; Got: %0t.", tres_out))
                  end
                end
              end
            end : clk_disable_stable_check

            begin : clk_stable_check
              @(posedge clk_out_if.clk);
              forever begin
                @(check_e);
                if (!switch && !clk_en_change && clk_en) begin
                  tres_stable = get_duration(sel_clk);
                  if (!(tres_out inside {[tres_stable-freq_delta:tres_stable+freq_delta]})) begin
                    `uvm_error(MY_ID, $sformatf("Invalid clk_out duration when stable! Expected: %0t, Got: %0t", tres_stable, tres_out))
                  end
                end
             end
            end : clk_stable_check

            begin : clk_switching_check
              forever begin
                @(switch);
                fork
                  begin : check_switching_clk_out
                    id_switch = process::self();
                    forever begin  
                      @(clk_out_changed);
                      lower_bound = find_min_max_half_period(MIN, '{sel_clk_last, sel_clk})-freq_delta;
                      upper_bound = find_min_max_half_period(MAX, '{sel_clk_last, sel_clk})*2*`CLK_OUT_FROZEN_DURING_SWITCH_NUM_CYCLES+freq_delta;
                      if (are_there_both_glitchfree_mux_involved() && bypass_ref_pll_changed) begin
                        upper_bound += find_min_max_half_period(MAX, '{CLK_OUT_SEL_REF, CLK_OUT_SEL_PLL_MACRO})*2*`CLK_OUT_FROZEN_DURING_SWITCH_NUM_CYCLES;
                      end
                      if (!((tres_out inside {[lower_bound:upper_bound]}) || (tres_out == 0 && clk_en_change))) begin
                        `uvm_error(MY_ID, $sformatf("Invalid clk_out duration when switch! Expected: %0t < tres_out < %0t, Got: %0t.", lower_bound, upper_bound, tres_out));
                      end
                    end
                  end : check_switching_clk_out

                  begin : switching_timeout
                    realtime switch_delay;
                    process  id_switch_timeout[$];

                    fork
                      begin : wait_for_switch_timeout
                        id_switch_timeout.push_back(process::self());
                        repeat(`TIMEOUT1_APB_CLK) begin
                          @(posedge apb_clk_if.clk);
                        end
                        repeat(`TIMEOUT2_REF_CLK) begin
                          @(posedge clk_ref_if.clk);
                        end
                        if (is_there_any_glitchfree_mux_involved()) begin
                          switch_delay = `TIMEOUT3_LOWEST_CLK*2*find_min_max_half_period(MAX, '{sel_clk_last, sel_clk});
                          if (are_there_both_glitchfree_mux_involved() && bypass_ref_pll_changed) begin
                            switch_delay += `TIMEOUT3_LOWEST_CLK*2*find_min_max_half_period(MAX, '{CLK_OUT_SEL_REF, CLK_OUT_SEL_PLL_MACRO});
                          end
                          #switch_delay;
                        end
                      end : wait_for_switch_timeout

                      begin : wait_for_clk_delay
                        realtime clk_out_last_duration;

                        id_switch_timeout.push_back(process::self());
                        clk_out_last_duration = get_duration(sel_clk_last);
                        wait(!((tres_out inside {[clk_out_last_duration-freq_delta:clk_out_last_duration+freq_delta]}) || (tres_out == 0)));
                        #1step;
                        tres_out = get_duration(sel_clk);
                      end : wait_for_clk_delay
                    join_any

                    foreach (id_switch_timeout[i]) begin
                      if (id_switch_timeout[i].status() != process::FINISHED) begin
                        id_switch_timeout[i].kill();
                      end
                    end

                    switch = 0;
                  end : switching_timeout
                join_any
                id_switch.kill();
              end
            end : clk_switching_check

            begin : clk_disable_changing_check
              forever begin
                @(clk_en_change);
                fork
                  begin : check_disable_changing_clk_out
                    id_gate = process::self();
                    forever begin
                      @(check_e);
                      tres_en_clk = get_duration(sel_clk);
                      if (!switch) begin
                        if (!((tres_out inside {[tres_en_clk-freq_delta:tres_en_clk+freq_delta]}) || (tres_out == 0))) begin
                          `uvm_error(MY_ID, $sformatf("Invalid clk_out duration when en_clk not stable! Expected: %0t or 0, Got tres_out: %0t, clk_out_o: %0b", tres_en_clk, tres_out, clk_out_if.clk))
                        end
                      end
                    end
                  end : check_disable_changing_clk_out

                  begin : gate_disable_timeout
                    realtime gate_dis_delay;
                    process  id_gate_dis_timeout[$];

                    fork
                      begin : wait_for_gate_disable_timeout
                        id_gate_dis_timeout.push_back(process::self());
                        repeat(`TIMEOUT1_APB_CLK) begin
                          @(posedge apb_clk_if.clk);
                        end
                        repeat(`TIMEOUT2_REF_CLK) begin
                          @(posedge clk_ref_if.clk);
                        end
                        if (!switch) begin
                          gate_dis_delay = `TIMEOUT3_LOWEST_CLK*2*get_duration(sel_clk);
                        end else begin
                          gate_dis_delay = `TIMEOUT3_LOWEST_CLK*2*find_min_max_half_period(MAX, '{sel_clk_last, sel_clk});
                        end
                        #gate_dis_delay;
                        tres_out     = 0;
                        last_out_clk = 0;
                      end : wait_for_gate_disable_timeout

                      begin : wait_for_clk_delay_after_gate_change
                        id_gate_dis_timeout.push_back(process::self());
                        if (!clk_en) begin
                          wait(tres_out == 0);
                        end else begin
                          wait(tres_out != 0);
                        end
                      end : wait_for_clk_delay_after_gate_change
                    join_any

                    foreach (id_gate_dis_timeout[i]) begin
                      if (id_gate_dis_timeout[i].status() != process::FINISHED) begin
                        id_gate_dis_timeout[i].kill();
                      end
                    end

                    clk_en_change = 0;
                  end : gate_disable_timeout
                join_any
                id_gate.kill();
              end
            end : clk_disable_changing_check
          join
        end : main_loop
      join_any
      disable fork; 
      reset_logic();
      wait_reset_deassert();
    end
  end


  task reset_logic();
    bypass_ref_pll_changed   = 1'b0;
    first_pulse_after_enable = 1'b0;
    clk_en_change            = 1'b0;
    if (YMP_ONLY_PLL_INT) begin
      sel_clk_latch = CLK_OUT_SEL_REF;
      sel_clk_last  = CLK_OUT_SEL_REF;
      sel_clk       = CLK_OUT_SEL_REF;
    end else begin
      sel_clk_latch = CLK_OUT_SEL_EXT;
      sel_clk_last  = CLK_OUT_SEL_EXT;
      sel_clk       = CLK_OUT_SEL_EXT;
    end
    clk_en = 1'b1;
    switch = 1'b0;
  endtask : reset_logic


  task wait_reset_deassert();
    realtime tres_expected;

    first_pulse_after_reset = 1'b1;
    while (!apb_slv_reset_if.common_reset) begin
      @(posedge clk_out_if.clk);
      if (!first_pulse_after_reset) begin
        tres_expected = (YMP_ONLY_PLL_INT) ? get_duration(CLK_OUT_SEL_REF) : get_duration(CLK_OUT_SEL_EXT);
        if (!(tres_out inside {[tres_expected-freq_delta:tres_expected+freq_delta]})) begin
          `uvm_error(MY_ID, $sformatf("Invalid clk_out duration when reset! Expected: %0t, Got: %0t.", tres_expected, tres_out))
        end
      end else begin
        first_pulse_after_reset = 1'b0;
      end
    end
  endtask : wait_reset_deassert


  task wait_reset_assert();
    wait(!apb_slv_reset_if.common_reset);
  endtask : wait_reset_assert


  function automatic realtime get_duration(clk_out_sel_e sel_clk);
    case (sel_clk)
      CLK_OUT_SEL_EXT:       return tres_ext;
      CLK_OUT_SEL_EXT_CML:   return tres_p;
      CLK_OUT_SEL_REF:       return tres_ref;
      CLK_OUT_SEL_PLL_MACRO: return pll_macro_half_period;
    endcase
  endfunction : get_duration


  function automatic realtime find_min_max_half_period(min_max_e f_cmd, clk_out_sel_e f_clk_out_sel[]);
    realtime result;
    realtime iter_var;

    result = get_duration(f_clk_out_sel[0]);
    for (int i = 1; i < f_clk_out_sel.size(); i++) begin
      iter_var = get_duration(f_clk_out_sel[i]);
      if ((iter_var > result) && (f_cmd == MAX) ||
          (iter_var < result) && (f_cmd == MIN)) begin
        result = iter_var;
      end
    end

    return result;
  endfunction : find_min_max_half_period


  function automatic bit is_there_any_glitchfree_mux_involved();
    return (!(((sel_clk_last == CLK_OUT_SEL_EXT)     && (sel_clk == CLK_OUT_SEL_EXT_CML)) ||
              ((sel_clk_last == CLK_OUT_SEL_EXT_CML) && (sel_clk == CLK_OUT_SEL_EXT))));
  endfunction : is_there_any_glitchfree_mux_involved


  function automatic bit are_there_both_glitchfree_mux_involved();
    return ((((sel_clk_last == CLK_OUT_SEL_EXT)       && (sel_clk inside {CLK_OUT_SEL_REF, CLK_OUT_SEL_PLL_MACRO})) ||
             ((sel_clk_last == CLK_OUT_SEL_EXT_CML)   && (sel_clk inside {CLK_OUT_SEL_REF, CLK_OUT_SEL_PLL_MACRO})) ||
             ((sel_clk_last == CLK_OUT_SEL_REF)       && (sel_clk inside {CLK_OUT_SEL_EXT, CLK_OUT_SEL_EXT_CML}))   ||
             ((sel_clk_last == CLK_OUT_SEL_PLL_MACRO) && (sel_clk inside {CLK_OUT_SEL_EXT, CLK_OUT_SEL_EXT_CML}))));
  endfunction : are_there_both_glitchfree_mux_involved

  ymp_pll_int_env_if_service_impl if_service; 

  function ymp_pll_int_env_if_service get_if_service();
    if(null == if_service) begin
      if_service = new("pll_int_env_if_service");
    end
    return if_service;
  endfunction
endinterface : ymp_elct_pll_int_env_if

`endif



  typedef enum {
    CLK_OUT_SEL_EXT,
    CLK_OUT_SEL_EXT_CML,
    CLK_OUT_SEL_REF,
    CLK_OUT_SEL_PLL_MACRO
  } clk_out_sel_e;

  typedef enum {
    CLK_IN_EXT,
    CLK_IN_EXT_CML,
    CLK_IN_REF,
    CLK_IN_APB
  } clk_in_e;


    // Update clk_out_sel
    if (regs_fields_val.clk_out == 1 && regs_fields_val.bypass_ext_cml == 1 && !pll_int_env_cfg.pll_int_only) begin
      clk_out_sel = CLK_OUT_SEL_EXT;
    end else if (regs_fields_val.clk_out == 1 && regs_fields_val.bypass_ext_cml == 0 && !pll_int_env_cfg.pll_int_only) begin
      clk_out_sel = CLK_OUT_SEL_EXT_CML;
    end else if ((regs_fields_val.clk_out == 0 || pll_int_env_cfg.pll_int_only) && regs_fields_val.bypass_ref_pll == 1) begin
      clk_out_sel = CLK_OUT_SEL_REF;
    end else if ((regs_fields_val.clk_out == 0 || pll_int_env_cfg.pll_int_only) && regs_fields_val.bypass_ref_pll == 0) begin
      clk_out_sel = CLK_OUT_SEL_PLL_MACRO;
    end
