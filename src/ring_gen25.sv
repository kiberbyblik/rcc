// SCHEMATIC SPICE SIM w/o EXTRACTION

module ring_gen25 (clk_out, rst_n);

	input  rst_n;
	output logic clk_out;

	initial begin
		clk_out = 0;
	end

	always
		#40 clk_out = ~clk_out;
	// TODO!!!

endmodule
