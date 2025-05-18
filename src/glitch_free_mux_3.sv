module glitch_free_mux_3 #(
  parameter DELAY = 2
)(
  input  logic       rstn_i,
  input  logic [1:0] sel_i,
  input  logic       clk_a_i,
  input  logic       clk_b_i,
  input  logic       clk_c_i,
  output logic       clk_o
);

//============================================================== global nets
  logic gfm_res;
//============================================================== global nets : end

//=================================================================== mux
  glitch_free_mux gfm_01 (
    .rstn_i     ( rstn_i      ),
    .clk_a_i    ( clk_a_i     ),
    .clk_b_i    ( clk_b_i     ),
    .sel_i      ( sel_i   [0] ),
    .clk_o      ( gfm_res     )
  );

  glitch_free_mux gfm_out (
    .rstn_i     ( rstn_i      ),
    .clk_a_i    ( gfm_res     ),
    .clk_b_i    ( clk_c_i     ),
    .sel_i      ( sel_i   [1] ),
    .clk_o      ( clk_o       )
  );
//=================================================================== mux : end

endmodule