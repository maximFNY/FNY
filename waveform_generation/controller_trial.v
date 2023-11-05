module controller_trial(
    input clock,
    input reset,
    input reg [7:0] period,
    output p1

);

reg [12:0]p1;
reg [12:0]n_p1;

reg[7:0] cnt;
reg[7:0] next_cnt;

localparam hf =0, lf=1 ;
//period = 8000ns
reg state, next_state;


always @(*) begin
    case(state)
        hf: n_p1 = 88;
        lf: n_p1 = 13;
    endcase
end


always @ (*) begin
    case(state)
        hf: begin
            if (cnt < period*5+1) begin
                next_cnt = cnt+1;
                next_state = hf;
            end
            else begin
                next_cnt =0;
                next_state =lf;
            end
        end

        lf: begin
            if (cnt < period*5+1) begin
                next_cnt = cnt+1;
                next_state = lf;
            end
            else begin
                next_cnt =0;
                next_state =hf;
            end
        end
    endcase
end

always @(posedge clock)begin
    if(reset)begin
    cnt <= 0;
    p1 <= 13'b0;
    state <= hf;
    end
    else begin
        cnt <= next_cnt;
        p1 <= n_p1;
        state <= next_state;
    end   
end

endmodule


