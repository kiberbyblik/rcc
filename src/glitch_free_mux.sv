module glitch_free_mux #(
  parameter DELAY = 2
)(
  input  logic rstn_i,
  input  logic clk_a_i,
  input  logic clk_b_i,
  input  logic sel_i,
  output logic clk_o
);

`ifndef SYNTHESIS
//============================================================================== gen_mux
  logic [DELAY-1:0] a_ff, b_ff;
  
  always_ff @(posedge clk_a_i or negedge rstn_i) begin
    if (~rstn_i) begin
      a_ff <= '0;
    end else begin
      a_ff <= {a_ff[0+:DELAY-1], ~sel_i && ~b_ff[DELAY-1]};
    end
  end
  
  always_ff @(posedge clk_b_i or negedge rstn_i) begin
    if (~rstn_i) begin
      b_ff <= '0;
    end else begin
      b_ff <= {b_ff[0+:DELAY-1], sel_i && ~a_ff[DELAY-1]};
    end
  end
  
  assign clk_o = (clk_a_i && a_ff[DELAY-1]) || (clk_b_i && b_ff[DELAY-1]);
//============================================================================== gen_mux : end
`elsif  PROTOTYPE
//============================================================================== gen_mux_prot
  logic [DELAY-1:0] a_ff, b_ff;
  
  always_ff @(posedge clk_a_i or negedge rstn_i) begin
    if (~rstn_i) begin
      a_ff <= '0;
    end else begin
      a_ff <= {a_ff[0+:DELAY-1], ~sel_i && ~b_ff[DELAY-1]};
    end
  end
  
  always_ff @(posedge clk_b_i or negedge rstn_i) begin
    if (~rstn_i) begin
      b_ff <= '0;
    end else begin
      b_ff <= {b_ff[0+:DELAY-1], sel_i && ~a_ff[DELAY-1]};
    end
  end
  
  assign clk_o = (clk_a_i && a_ff[DELAY-1]) || (clk_b_i && b_ff[DELAY-1]);
//============================================================================== gen_mux_prot : end
`else
//============================================================================== tech_mux
// schematic from https://vlsitutorials.com/glitch-free-clock-mux/
  logic sel, sel_n;
  logic sync_a, sync_b;
  logic sync_a_n, sync_b_n;
  logic rstn_a, rstn_b;
  logic i_and_a, i_and_b;
  logic o_and_a, o_and_b;

// rst sync
  logic rstn_a_ff1, rstn_b_ff1;
  // a
  FD2QHS handplace_rst_sync_a_ff1 (
    .CD ( rstn_i     ),
    .D  ( 1'b1       ),
    .CP ( clk_a_i    ),
    .Q  ( rstn_a_ff1 )
  );

  FD2QHS handplace_rst_sync_a_ff2 (
    .CD ( rstn_i     ),
    .D  ( rstn_a_ff1 ),
    .CP ( clk_a_i    ),
    .Q  ( rstn_a     )
  );
  // b
  FD2QHS handplace_rst_sync_b_ff1 (
    .CD ( rstn_i     ),
    .D  ( 1'b1       ),
    .CP ( clk_b_i    ),
    .Q  ( rstn_b_ff1 )
  );

  FD2QHS handplace_rst_sync_b_ff2 (
    .CD ( rstn_i     ),
    .D  ( rstn_b_ff1 ),
    .CP ( clk_b_i    ),
    .Q  ( rstn_b     )
  );

// gfm
  assign sel = sel_i;

  IVHS handplace_sel_inv(
    .A ( sel   ),
    .Z ( sel_n )
  );

  // a 

  AN2HS handplace_i_and_a_inst(
    .A ( sel_n    ),
    .B ( sync_b_n ),
    .Z ( i_and_a  )
  );

  logic a_ff1;
  FD2HS handplace_ff1_a(
    .CD ( rstn_a  ),
    .D  ( i_and_a ),
    .CP ( clk_a_i ),
    .QN (         ),
    .Q  ( a_ff1   )
  );

  FD2HS handplace_ff2_a(
    .CD ( rstn_a   ),
    .D  ( a_ff1    ),
    .CP ( clk_a_i  ),
    .QN ( sync_a_n ),
    .Q  ( sync_a   )
  );

  AN2HS handplace_o_and_a_inst(
    .A ( sync_a  ),
    .B ( clk_a_i ),
    .Z ( o_and_a )
  );

  // b
  AN2HS handplace_i_and_b_inst(
    .A ( sel      ),
    .B ( sync_a_n ),
    .Z ( i_and_b  )
  );

  logic b_ff1;
  FD2HS handplace_ff1_b(
    .CD ( rstn_b  ),
    .D  ( i_and_b ),
    .CP ( clk_b_i ),
    .QN (         ),
    .Q  ( b_ff1   )
  );

  FD2HS handplace_ff2_b(
    .CD ( rstn_b   ),
    .D  ( b_ff1    ),
    .CP ( clk_b_i  ),
    .QN ( sync_b_n ),
    .Q  ( sync_b   )
  );

  AN2HS handplace_o_and_b_inst(
    .A ( sync_b  ),
    .B ( clk_b_i ),
    .Z ( o_and_b )
  );

  // out 
  OR2HS handplace_clk_out_or(
    .A ( o_and_a ),
    .B ( o_and_b ),
    .Z ( clk_o   )
  );
//============================================================================== tech_mux : end

//------------------------------ old hp mux
  // //definitions
  //   wire clk_sel_i;
  //   wire clk_sel_i_inv  ;
  //   wire ff1_a_in       ;
  //   wire ff1_a_to_ff2_a ;
  //   wire clk_a_i_inv    ;
  //   wire clk_a_feedback ;
  //   wire clk_b_feedback ;
  //   wire ff2_a_out      ;
  //   wire mux_clk_a      ;
  //   wire ff1_b_in       ;
  //   wire ff1_b_to_ff2_b ;
  //   wire clk_b_i_inv    ;
  //   wire ff2_b_out      ;
  //   wire mux_clk_b      ;
  //   //Reset sync logic
  //     wire rst_ff1_clk_a;
  //     wire rst_ff2_clk_a;
  //     wire rst_ff1_clk_b;
  //     wire rst_ff2_clk_b;

  // assign clk_sel_i = sel_i;

  // //Reset sync logic
  //   //sync a channel
  //   FD2QHS handplace_sync_rst_ff1_clk_a (
  //     .CD ( rstn_i       ),
  //     .D  ( 1'b1          ),
  //     .CP ( clk_a_i       ),
  //     .Q  ( rst_ff1_clk_a )
  //   );

  //   FD2QHS handplace_sync_rst_ff2_clk_a (
  //     .CD ( rstn_i        ),
  //     .D  ( rst_ff1_clk_a  ),
  //     .CP ( clk_a_i        ),
  //     .Q  ( rst_ff2_clk_a  )
  //   );

  // //sync b channel
  //   FD2QHS handplace_sync_rst_ff1_clk_b (
  //     .CD ( rstn_i       ),
  //     .D  ( 1'b1          ),
  //     .CP ( clk_b_i       ),
  //     .Q  ( rst_ff1_clk_b )
  //   );

  //   FD2QHS handplace_sync_rst_ff2_clk_b (
  //     .CD ( rstn_i        ),
  //     .D  ( rst_ff1_clk_b  ),
  //     .CP ( clk_b_i        ),
  //     .Q  ( rst_ff2_clk_b  )
  //   );

  // // clk_a line
  // IVHS handplace_clk_a_sel_i_inv(
  //   .A ( clk_sel_i     ),
  //   .Z ( clk_sel_i_inv )
  // );

  // AN2HS handplace_and2_select_a(
  //   .A ( clk_sel_i_inv  ),
  //   .B ( clk_b_feedback ),
  //   .Z ( ff1_a_in       )
  // );

  // FD4QHS handplace_ff1_a(
  //   .SD ( rst_ff2_clk_a  ),
  //   .D  ( ff1_a_in       ),
  //   .CP ( clk_a_i        ),
  //   .Q  ( ff1_a_to_ff2_a )
  // );

  // IVHS handplace_clk_a_i_inv_inst(
  //   .A ( clk_a_i     ),
  //   .Z ( clk_a_i_inv )
  // );

  // FD4HS handplace_ff2_a(
  //   .SD ( rst_ff2_clk_a  ),
  //   .D  ( ff1_a_to_ff2_a ),
  //   .CP ( clk_a_i_inv    ),
  //   .QN ( clk_a_feedback ),
  //   .Q  ( ff2_a_out      )
  // );

  // AN2HS handplace_and_clk_a (
  //  .A ( ff2_a_out ),
  //  .B ( clk_a_i   ),
  //  .Z ( mux_clk_a )
  // );
  // //AN2HS and_clk_a might be changed to this cell
  // // CBUFLHS cg_buf_a(
  // //   .CP ( clk_a_i   ),
  // //   .E  ( ff2_a_out ),
  // //   .TE ( '0        ),
  // //   .G  ( mux_clk_a )
  // // );

  // // clk_b line
  // AN2HS handplace_and2_select_b(
  //   .A ( clk_sel_i      ),
  //   .B ( clk_a_feedback ),
  //   .Z ( ff1_b_in       )
  // );

  // FD2QHS handplace_ff1_b(
  //   .CD ( rst_ff2_clk_b  ),
  //   .D  ( ff1_b_in       ),
  //   .CP ( clk_b_i        ),
  //   .Q  ( ff1_b_to_ff2_b )
  // );

  // IVHS handplace_clk_b_i_inv_inst(
  //   .A ( clk_b_i     ),
  //   .Z ( clk_b_i_inv )
  // );

  // FD2HS handplace_ff2_b(
  //   .CD ( rst_ff2_clk_b  ),
  //   .D  ( ff1_b_to_ff2_b ),
  //   .CP ( clk_b_i_inv    ),
  //   .QN ( clk_b_feedback ),
  //   .Q  ( ff2_b_out      )
  // );

  // AN2HS handplace_and_clk_b (
  //   .A ( ff2_b_out ),
  //   .B ( clk_b_i   ),
  //   .Z ( mux_clk_b )
  // );
  // //AN2HS and_clk_b might be changed to this cell
  // // CBUFLHS cg_buf_b(
  // //   .CP ( clk_b_i   ),
  // //   .E  ( ff2_b_out ),
  // //   .TE ( '0        ),
  // //   .G  ( mux_clk_b )
  // // );

  // // clk_out
  // OR2HS handplace_clk_out_or(
  //   .A ( mux_clk_a ),
  //   .B ( mux_clk_b ),
  //   .Z ( clk_o     )
  // );
`endif
endmodule