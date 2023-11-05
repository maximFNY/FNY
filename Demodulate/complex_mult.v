module complex_mult (
    input clock, 
    input rst,
    input signed [9:0] sig_modulated_fixed_real,
    input signed [9:0]sig_modulated_fixed_imag,
    input signed [9:0]demod_Lo_real,
    input signed [9:0]demod_Lo_imag,
    output signed [21:0]sig_baseband_real,
    output signed [21:0]sig_baseband_imag);

    reg signed [21:0] sig_baseband_real_temp ;
    reg signed[21:0] sig_baseband_imag_temp ;

    always @(*) begin
        sig_baseband_real_temp= (sig_modulated_fixed_real * demod_Lo_real) - (sig_modulated_fixed_imag * demod_Lo_imag);
        sig_baseband_imag_temp= (sig_modulated_fixed_real * demod_Lo_imag) + (sig_modulated_fixed_imag * demod_Lo_real);        
    end
    assign sig_demod_real = sig_baseband_real_temp;
    assign sig_baseband_imag = sig_baseband_imag_temp;

    always @(posedge clock) begin
        if(rst) begin
            sig_baseband_imag_temp <=0;
            sig_baseband_real_temp <=0;
        end
        else begin
            sig_baseband_imag_temp <= sig_baseband_imag_temp;
            sig_baseband_real_temp <= sig_baseband_real_temp;
        end
    end
    
endmodule
    


