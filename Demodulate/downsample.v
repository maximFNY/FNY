module downsample (
    input clock,
    input rst,
    input [31:0] lpf_output_real,
    input [31:0] lpf_output_imag,
    output [31:0] sig_demod_real,
    output [31:0] sig_demod_imag,
    output reg sample_valid );// Indicates when a valid sample is present


reg [4:0] counter;

always @(posedge clock or posedge rst) begin
    if (rst) begin
        counter <= 0;
        sample_valid <= 0;
    end else begin
        if (counter == 31) begin
            counter <= 0;
            sample_valid <= 1; // Indicate that a valid sample is present
        end else begin
            counter <= counter + 1;
            sample_valid <= 0; // Reset sample_valid when no valid sample is present
        end
    end
end

assign sig_demod_real = (sample_valid) ? lpf_output_real : 32'b0; 
assign sig_demod_imag = (sample_valid) ? lpf_output_imag : 32'b0; 

endmodule



