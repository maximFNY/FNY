`timescale 1ns/1ps
module demodulate_tb;
reg clock, rst;
reg  signed [9:0] sig_modulated_fixed_real, sig_modulated_fixed_imag , demod_Lo_real , demod_Lo_imag ;
reg signed [21:0] sig_baseband_real, sig_baseband_imag;
reg signed [11:0] my_lpf [0:31]; 
reg signed [31:0] lpf_output_real;
reg signed [31:0] lpf_output_imag;
reg signed [31:0] sig_demod_real;
reg signed [31:0] sig_demod_imag;
reg finish_readfile;
reg [$clog2(1497600)-1:0] count0;
reg [$clog2(1497600)-1:0] counta;

// Instantiate the complex_multiplier module
complex_mult uut (
    .rst(rst),
    .clock(clock),
    .sig_modulated_fixed_real(sig_modulated_fixed_real),
    .sig_modulated_fixed_imag(sig_modulated_fixed_imag),
    .demod_Lo_real(demod_Lo_real),
    .demod_Lo_imag(demod_Lo_imag),
    .sig_baseband_real(sig_baseband_real),
    .sig_baseband_imag(sig_baseband_imag)
);

lpf lpf (
        .rst(rst),
        .clock(clock),
        .sig_baseband_real(sig_baseband_real),
        .sig_baseband_imag(sig_baseband_imag),
        .my_lpf(my_lpf),
        .lpf_output_real(lpf_output_real),
        .lpf_output_imag(lpf_output_imag)
    );

downsample d1 (.clock(clock),
        .rst(rst),
        .lpf_output_real(lpf_output_real),
        .lpf_output_imag(lpf_output_imag),
        .sig_demod_real(sig_demod_real),
        .sig_demod_imag(sig_demod_imag)
);

 always begin
        #1;
        clock=~clock;
end
// Apply test inputs
reg signed [9:0] sig_modulated_fixed_real_mem [0:1497599];
reg signed [9:0] sig_modulated_fixed_imag_mem [0:1497599];
reg signed [9:0] demod_Lo_real_mem [0:1497599];
reg signed [9:0] demod_Lo_imag_mem [0:1497599];
reg signed [9:0] sig_baseband_real_mem [0:1497599];
reg signed [9:0] sig_baseband_imag_mem [0:1497599];
reg signed [11:0]my_lpf_mem [0:31];
integer counter, lpf_count, fd0, fd1, fd2, fd3, fl0, fout0, fout1, fout2, fout3, fout4, fout5, ta;


initial begin
    count0 = 0;
    rst = 0;
    counta = 0;
    clock = 0;
    finish_readfile = 0;
    fd0 = $fopen("sig_modulated_fixed_real.txt", "r");
    fd1 = $fopen("sig_modulated_fixed_imag.txt", "r");
    fd2 = $fopen("demod_Lo_real.txt", "r");
    fd3 = $fopen("demod_Lo_imag.txt", "r");
    fl0 = $fopen("my_lpf.txt", "r");
    fout0 = $fopen("sig_baseband_real.txt", "w");
    fout1 = $fopen("sig_baseband_imag.txt", "w");
    fout2 = $fopen("lpf_output_real.txt", "w");
    fout3 = $fopen("lpf_output_imag.txt", "w");
    fout4 = $fopen("sig_demod_real.txt", "w");
    fout5 = $fopen("sig_demod_imag.txt", "w");

    
    @(negedge clock);
    rst = 1;
    @(negedge clock);
    rst = 0;

    for (counter=0; counter<1497600; counter=counter + 1)begin
        ta = $fscanf(fd0, "%b", sig_modulated_fixed_real_mem[counter]);
        ta = $fscanf(fd1, "%b", sig_modulated_fixed_imag_mem[counter]);
        ta = $fscanf(fd2, "%b", demod_Lo_real_mem[counter]);
        ta = $fscanf(fd3, "%b", demod_Lo_imag_mem[counter]);
    end
    for (lpf_count=0; lpf_count<32; lpf_count = lpf_count +1) begin
        ta = $fscanf(fl0, "%b", my_lpf_mem[lpf_count]);
    end
    for (lpf_count=0; lpf_count < 32; lpf_count = lpf_count + 1) begin
        my_lpf[lpf_count] = my_lpf_mem[lpf_count];
    end
    $fclose(fd0);
    $fclose(fd1);
    $fclose(fd2);		
    $fclose(fd3);
    $fclose(fl0);
    // $display("A: %d, B: %d, C: %d, D: %d, E: %d\n", sig_modulated_fixed_real_mem[0],
    // sig_modulated_fixed_imag_mem[0],demod_Lo_real_mem[0], demod_Lo_imag_mem[0], my_lpf_mem[0]);
    
    finish_readfile = 1; //simultaneously writing the file
    #10000000
    finish_readfile = 0;
    #100
    $finish;
end


always@(posedge clock) begin
    if (count0 < 1497600 && finish_readfile) begin
        sig_modulated_fixed_real <= sig_modulated_fixed_real_mem[count0];
        sig_modulated_fixed_imag <= sig_modulated_fixed_imag_mem[count0];
        demod_Lo_real <= demod_Lo_real_mem[count0];
        demod_Lo_imag <= demod_Lo_imag_mem[count0];
        count0 <= count0 + 1;
        $fwrite(fout0, "%d\n", sig_baseband_real);
        $fwrite(fout1, "%d\n", sig_baseband_imag);
    end
    else begin
        sig_modulated_fixed_real <= 0;
        sig_modulated_fixed_imag <= 0;
        demod_Lo_real <= 0;
        demod_Lo_imag <= 0;
    end
end


reg [12:0] counta;
always@(posedge clock) begin
    if(rst) counta<=0;
    else if (counta == 6'd32) counta <= counta;
    else if(finish_readfile) counta <= counta + 1;
    else counta <= counta;
end
always@(posedge clock) begin
    if (finish_readfile && counta == 6'd31) begin
        $fwrite(fout2, "%d\n", lpf_output_real);
        $fwrite(fout3, "%d\n", lpf_output_imag);
    end
end

always@ (posedge clock) begin
    if (finish_readfile && counta == 6'd31) begin
        $fwrite(fout4, "%d\n", sig_demod_real);
        $fwrite(fout5, "%d\n", sig_demod_imag);
    end
end


endmodule