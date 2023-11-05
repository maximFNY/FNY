
module controller_tb();
    reg clock, reset;
    reg [7:0] period;
    reg [12:0] p1;
    reg [9:0] my_sine_out;
    reg [9:0] my_cosine_out;


    controller_trial c1(.clock(clock), .reset(reset), .period(period), .p1(p1));
    
    sine s1(.clock(clock), .reset(reset),
        .p1(p1), .my_sine_out(my_sine_out), .my_cosine_out(my_cosine_out));
   
   
    always begin
        #50;
        clock=~clock;
    end

    initial begin
        clock = 1'b0;
        reset = 1'b1;

        // 8us
        period = 8'd8;

        // 13us


        @(negedge clock);
        @(negedge clock);
        
        reset = 1'b0;
        @(negedge clock);
        #1000000
        @(negedge clock);
        @(negedge clock);
        $finish;

    end
endmodule