`define PI 12867  //(16,12)  //(14,10)
`define STAGE 12
module cordic_vector (
    input                           clk,
    input                           rst,
    input   logic   signed  [`STAGE-1:0]  x_i,
    input   logic   signed  [`STAGE-1:0]  y_i,
    input   logic   signed  [`STAGE-1:0]  z_i,
    input   logic                   valid_i,
    output  logic   signed  [`STAGE-1:0]  z_o,
    output  logic   signed  [15:0]  inst_freq,
    output  logic                   valid_o
);

logic start;
logic glue_out;
logic wrap;
logic signed [`STAGE-1:0] x_after_rot;
logic signed [`STAGE-1:0] y_after_rot;
logic signed [`STAGE-1:0] x_after_rot_nxt;
logic signed [`STAGE-1:0] y_after_rot_nxt;
logic signed [`STAGE-1:0] x_o_temp [0:`STAGE-1];
logic signed [`STAGE-1:0] y_o_temp [0:`STAGE-1];
logic signed [`STAGE-1:0] z_o_temp [0:`STAGE-1];

logic signed [`STAGE-1:0] z_glue_in;
logic signed [`STAGE-1:0] z_glue_in_nxt;
integer i;
logic [11:0] LUT [0:11];

// pre-rotation: all the inputs should be in quadrant 1
logic [1:0] quadrant, quadrant_nxt;
logic [1:0] quadrant_reg [0:`STAGE-1];
logic glue_out_reg [0:`STAGE-1];


//assign valid_o = start;


// 
always_ff @ (posedge clk) begin
    if (rst) begin
        x_after_rot <= 12'd0;
        y_after_rot <= 12'd0;
        quadrant <= 0;
        start <=0;
    end
    else begin
        x_after_rot <= x_after_rot_nxt;
        y_after_rot <= y_after_rot_nxt;
        quadrant <= quadrant_nxt;
        start <=valid_i;
    end
end

always_comb begin
    if (valid_i) begin
        if (x_i > 0 && y_i > 0) begin         //quadrant1
            x_after_rot_nxt = x_i;
            y_after_rot_nxt = y_i;
            quadrant_nxt = 2'b00;
        end 
        else if (x_i < 0 && y_i > 0) begin    //quadrant2
            x_after_rot_nxt = y_i;
            y_after_rot_nxt = (~ x_i)+1;
            quadrant_nxt = 2'b01;
        end
        else if (x_i < 0 && y_i < 0) begin     //quadrant3 
                x_after_rot_nxt = (~x_i)+1 ;
                y_after_rot_nxt = (~y_i)+1;
                quadrant_nxt = 2'b10;
        end           
        else if (x_i >0 && y_i < 0) begin       //quadrant4
                x_after_rot_nxt = (~y_i)+1;
                y_after_rot_nxt = x_i;
                quadrant_nxt = 2'b11;
         end
    end
end



// LUT
always_comb begin
    LUT[0] = 12'b001100100100;
    LUT[1] = 12'b000111011011;
    LUT[2] = 12'b000011111011;
    LUT[3] = 12'b000001111111;
    LUT[4] = 12'b000001000000;
    LUT[5] = 12'b000000100000;
    LUT[6] = 12'b000000010000;
    LUT[7] = 12'b000000001000;
    LUT[8] = 12'b000000000100;
    LUT[9] = 12'b000000000010;
    LUT[10] = 12'b000000000001;
    LUT[11] = 12'b000000000000;
end   

// vector mode  z_in =0
// iteration: 12 times  //求theta(z_o)
//pipeline=12
always_ff @ (posedge clk) begin
    if (rst) begin
        x_o_temp [0:`STAGE-1] <= '{default: '0};
        z_o_temp [0:`STAGE-1] <= '{default: '0};
        y_o_temp  [0:`STAGE-1] <= '{default: '0};
        quadrant_reg[0:`STAGE-1] <= '{default: '0};
        glue_out_reg[0:`STAGE-1] <= '{default: '0};
    end
    else begin
        if (start) begin   
            if (y_after_rot >= 0) begin
                x_o_temp[0] <= x_after_rot + y_after_rot;
                z_o_temp[0] <= z_i + LUT[0];
                y_o_temp[0] <= y_after_rot - x_after_rot;
                quadrant_reg[0] <= quadrant;
                glue_out_reg[0] <=1;
            end
            else begin
                    x_o_temp[0] <= x_after_rot - y_after_rot;
                    z_o_temp[0] <= z_i - LUT[0];
                    y_o_temp[0] <= y_after_rot + x_after_rot;
                    quadrant_reg[0] <= quadrant;
                    glue_out_reg[0] <=1;
            end

            for (i=1; i<`STAGE; i=i+1) begin
                if (y_o_temp[i-1]> 0) begin
                    x_o_temp[i] <= x_o_temp[i-1] + (y_o_temp[i-1] >>>i);
                    z_o_temp[i] <= z_o_temp[i-1] + LUT[i];
                    y_o_temp[i] <= y_o_temp[i-1] - (x_o_temp[i-1] >>> i);
                    quadrant_reg[i] <= quadrant_reg [i-1];
                    glue_out_reg[i] <= glue_out_reg[i-1];
                end
                else begin
                    x_o_temp[i] <= x_o_temp[i-1] - (y_o_temp[i-1] >>> i);
                    z_o_temp[i] <= z_o_temp[i-1] - LUT[i];
                    y_o_temp[i] <= y_o_temp[i-1] + (x_o_temp[i-1] >>> i);
                    quadrant_reg[i] <= quadrant_reg [i-1];
                    glue_out_reg[i] <= glue_out_reg[i-1];
                end
            end
            //assign z_o = x_o_temp[11];
            
        end
        
    end 
end



//glue logic at output
always_ff @(posedge clk) begin
    if (glue_out_reg[11]) begin
        if (quadrant_reg[11] == 2'b00) begin
            z_glue_in <= z_o_temp[11];
            wrap <= 1;
            //valid_o <=1;
        end
        else if (quadrant_reg[11] == 2'b01) begin
            z_glue_in <= z_o_temp[11] + (`PI >>> 1);
            wrap <= 1;
            //valid_o <=1;
        end
        else if (quadrant_reg[11] == 2'b10) begin
            z_glue_in <= z_o_temp[11] + `PI;
            wrap <= 1;
            //valid_o <=1;
        end
        else if (quadrant_reg[11] == 2'b11) begin
            z_glue_in <= z_o_temp[11] + (-`PI >>> 1);
            wrap <= 1;
            //valid_o <=1;
        end
    end
end


// instaneous frequency

logic signed [15:0] theta_diff; 
logic [15:0] input_delay;    
logic [15:0] wrap_delay;


always_ff @ (posedge clk) begin
    if (rst) begin
        input_delay <= 0;
        wrap_delay <= 0;
    end else begin
        input_delay <= z_glue_in;
        wrap_delay <= wrap; 
    end
end

always_comb begin
    if (wrap_delay) begin
        theta_diff = (z_glue_in - input_delay) ;     /// <<<12 ?
        if (theta_diff < `PI && theta_diff > (-`PI))
            inst_freq = theta_diff;
        else if (theta_diff > `PI)
            inst_freq = (theta_diff) - 2*`PI;
        else  
            inst_freq = (theta_diff) + 2*`PI;
    end
end

assign valid_o = wrap && wrap_delay;

endmodule
