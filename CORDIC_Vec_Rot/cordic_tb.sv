`timescale 1ns/1ps

module cordic_tb();

logic clk, rst, valid_i, rotate_valid;
logic signed [15:0] x_i, y_i, z_i;
logic signed [15:0] ROT_x_i, ROT_y_i, ROT_z_i;
logic signed [15:0] x_vec_out, y_vec_out, z_vec_out;
logic valid_o;
logic signed [11:0] x_re_out, x_im_out;
logic signed [15:0] x_real_mem [0:255], x_imag_mem [0:255];



cordic_Vec c1(
    .clk(clk), .rst(rst), .x_i(x_i), .y_i(y_i), .z_i(z_i), .valid_i(valid_i),
    .x_vec_out(x_vec_out), .y_vec_out(y_vec_out), .z_vec_out(z_vec_out), .rotate_valid(rotate_valid)
);

cordic_Rot r1 (
    .clk(clk), .rst(rst), .rot_valid(rotate_valid), .ROT_x_i(x_vec_out), .ROT_y_i(y_vec_out), .ROT_z_i(z_vec_out),
    .x_re_out(x_re_out), .x_im_out(x_im_out), .valid_o(valid_o)
);


always begin
    #5 clk = ~clk;
end


integer i; 
integer fout0, fout1;

initial begin
    clk =0;
    rst =0;
    z_i =0;
    valid_i = 0;
    @(posedge clk);
    @(posedge clk);
    $readmemb("x_real.txt", x_real_mem);
    $readmemb("x_imag.txt", x_imag_mem);
    

    @(posedge clk);
    @(posedge clk);
    #1
    for (i = 0; i<255; i++) begin
        @(negedge clk);
        x_i = x_real_mem[i][15:0];
        y_i = x_imag_mem[i][15:0];
        valid_i = 1;
    end

    @(negedge clk);
    valid_i = 0;


    # 1000;
    $finish;
    
end

always_ff @(posedge clk) begin
    fout0 = $fopen("x_re_out.txt", "w");
    fout1 = $fopen("x_im_out.txt", "w");
    if (valid_o) begin
        $fwrite (fout0, "%b\n", x_re_out);
        $fwrite (fout1, "%b\n", x_im_out);
    end
end

endmodule
