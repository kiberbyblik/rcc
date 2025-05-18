module rst_sync #(
  parameter D = 2
)(
  input        clk_i,
  input        rstn_i,
  output logic rst_sync_o
);
  
  logic [ D-1 : 0 ] buff;

  always_ff @(posedge clk_i or negedge rstn_i) begin
    if (!rstn_i) begin
      buff <= '0;
    end else begin
      buff <= { buff [ 0 +: D-1 ], 1'b1 };
    end
  end

  assign rst_sync_o = buff[D-1];
    
endmodule
