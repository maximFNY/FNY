module lpf(
    input    clock, 
    input rst,
    input [21:0]sig_baseband_real,
    input [21:0]sig_baseband_imag,
    input [11:0] my_lpf [0:31],  //32 coefficients
    output [31:0] lpf_output_real,
    output [31:0] lpf_output_imag);

reg signed [31:0] lpf_output_real_temp;
reg signed [31:0] lpf_output_imag_temp;
reg signed [21:0] shift_register_real [0:31]; // 32-tap shift register
reg signed [21:0] shift_register_imag [0:31];
reg signed [31:0] multiplied_data_real [0:31]; 
reg signed[31:0] multiplied_data_imag [0:31]; 
reg signed[31:0] accumulator_real;
reg signed[31:0] accumulator_imag; 
integer i;
reg start;


always @(posedge clock) begin
    if(rst) begin
        for (i=0; i<31; i=i+1) begin   
            shift_register_real[i] <= 0;
            shift_register_imag[i] <= 0;       
        end        
    end else begin
        for (i=0; i<31; i=i+1) begin   
            shift_register_real[i] <= shift_register_real[i+1];
            shift_register_imag[i] <= shift_register_imag[i+1];       
        end
        shift_register_real[31] <= sig_baseband_real;
        shift_register_imag[31] <= sig_baseband_imag;
    end
end

always@(*) begin
    if(rst) start = 0;
    else if(shift_register_imag[0] != 0 || shift_register_real[0] != 0) start = 1;
    else start = start ;
end

always @(*) begin
    if (start) begin
        multiplied_data_real[0] = shift_register_real[0] * my_lpf[0];
        multiplied_data_imag[0] = shift_register_imag[0] * my_lpf[0];
        accumulator_real = multiplied_data_real[0];
        accumulator_imag = multiplied_data_imag[0];
        for (i=1;i<31; i=i+1) begin
            multiplied_data_real[i] = shift_register_real[i] * my_lpf[i];
            multiplied_data_imag[i] = shift_register_imag[i] * my_lpf[i];
            accumulator_real = accumulator_real + multiplied_data_real[i];
            accumulator_imag = accumulator_imag+ multiplied_data_imag[i];
            lpf_output_real_temp = accumulator_real;
            lpf_output_imag_temp= accumulator_imag;
        //shift =1;
        end   
    end   
end
assign lpf_output_real = lpf_output_real_temp;
assign lpf_output_imag = lpf_output_imag_temp;
endmodule



