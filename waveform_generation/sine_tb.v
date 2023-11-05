module sine_tb();

    reg clock, reset;
    reg [12:0] p1;
    reg [9 :0]  my_sine_out;
    reg [9 :0]  my_cosine_out;


    sine gen(.clock(clock), .reset(reset),
        .p1(p1), .my_sine_out(my_sine_out), .my_cosine_out(my_cosine_out));

    always begin
        #50;
        clock=~clock;
    end

    initial begin
        clock = 1'b0;
        reset = 1'b1;
        // 1.72 MHz: 581 ns/cycle---> 5.81 cycles to finish drawing a sine waveform
        //p1=13'd88;

        //0.93 MHz: 1080ns/cycle
        //p1=13'd47;

        //0.27 MHz;
        p1=13'd13;

        @(negedge clock);
        @(negedge clock);
        reset = 1'b0;
        //p = 13'd512;
        @(negedge clock);
        #1000000
        @(negedge clock);
        @(negedge clock);
        $finish;

    end
endmodule