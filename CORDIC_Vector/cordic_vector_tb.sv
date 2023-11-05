`timescale 1ns/1ps
module cordic_vector_tb ();

    logic clk, rst, valid_i;
	logic [11:0] x_i, y_i, z_i;
	logic valid_o;
    logic [15:0] inst_freq;
    logic [11:0] z_o;
    logic [11:0] x_real_mem [0:255], x_imag_mem [0:255];


    cordic_vector c1(
        .clk(clk), .rst(rst), .x_i(x_i), .y_i(y_i), .z_i(z_i), .valid_i(valid_i),
        .z_o(z_o), .inst_freq(inst_freq), .valid_o(valid_o)
    );

    always begin
        #10;
        clk = ~clk;
    end
    
    integer i; 
    integer fout0;

    always_ff @(posedge clk) begin
        if (valid_o) begin
            //$fwrite (fout0, "%d\n", z_o);
            fout0 = $fopen("inst_freq.txt", "w");
            $fwrite (fout0, "%d\n", inst_freq);
            
        end
    end

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
        //fout0 = $fopen("inst_freq.txt", "w");
        //fout0 = $fopen("z_o.txt", "w");
        for (i = 0; i<256; i++) begin
		    @(negedge clk);
            x_i = x_real_mem[i][11:0];
            y_i = x_imag_mem[i][11:0];
            valid_i = 1;
        end
        @(negedge clk);
        valid_i = 0;
       
        # 1000;
        $finish;
    end

endmodule