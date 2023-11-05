`define PI 12861  //(16,12)  
`define STAGE 12
module cordic_Vec (
    input                           clk,
    input                           rst,
    input   logic   signed  [15:0]  x_i,
    input   logic   signed  [15:0]  y_i,
    input   logic   signed  [15:0]  z_i,
    input   logic                   valid_i,
    output  logic   signed  [15:0]  x_vec_out,
    output  logic   signed  [15:0]  y_vec_out,
    output  logic   signed  [15:0]  z_vec_out,
    output  logic   rotate_valid
);

logic start;
logic glue_out;

logic signed [15:0] x_after_rot;
logic signed [15:0] y_after_rot;
logic signed [15:0] x_after_rot_nxt;
logic signed [15:0] y_after_rot_nxt;
logic signed [15:0] x_o_temp [0:`STAGE-1];
logic signed [15:0] y_o_temp [0:`STAGE-1];
logic signed [15:0] z_o_temp [0:`STAGE-1];

logic signed [15:0] z_glue_in;
logic signed [15:0] z_glue_in_nxt;
integer i;
logic signed [15:0] LUT [0:`STAGE-1];

// pre-rotation: all the inputs should be in quadrant 1
logic [1:0] quadrant, quadrant_nxt;
logic [1:0] quadrant_reg [0:`STAGE-1];
logic glue_out_reg [0:`STAGE-1];
logic rotate_valid; 




always_ff @ (posedge clk) begin
    if (rst) begin
        x_after_rot <= 16'd0;
        y_after_rot <= 16'd0;
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
            y_after_rot_nxt = (~x_i)+1;
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
    LUT[0] = 16'b0000110010010000;
    LUT[1] = 16'b0000011101101011;
    LUT[2] = 16'b0000001111101011;
    LUT[3] = 16'b0000000111111101;
    LUT[4] = 16'b0000000011111111;
    LUT[5] = 16'b0000000001111111;
    LUT[6] = 16'b0000000000111111;
    LUT[7] = 16'b0000000000011111;
    LUT[8] = 16'b0000000000001111;
    LUT[9] = 16'b0000000000000111;
    LUT[10] = 16'b0000000000000011;
    LUT[11] = 16'b0000000000000001;
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
                    x_o_temp[i] <= x_o_temp[i-1] + (y_o_temp[i-1] >>> i);
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
        end
    end 
end



//glue logic at output
always_ff @(posedge clk) begin
    if (rst) begin
        x_vec_out <=0;
        y_vec_out <=0;
        z_vec_out <=0;
        rotate_valid <= 0;
    end
    if (glue_out_reg[`STAGE-1]) begin
        if (quadrant_reg[`STAGE-1] == 2'b00) begin
            x_vec_out <= ((x_o_temp[`STAGE-1])/13) <<< 3;  //12bit
            y_vec_out <= (y_o_temp[`STAGE-1]) * 0;
            z_vec_out <= z_o_temp[`STAGE-1];
            rotate_valid <=1;
        end
        else if (quadrant_reg[`STAGE-1] == 2'b01) begin
            x_vec_out <= ((x_o_temp[`STAGE-1])/13) <<< 3;
            y_vec_out <= (y_o_temp[`STAGE-1]) * 0;
            z_vec_out <= z_o_temp[`STAGE-1] + (`PI >>> 1);
            rotate_valid <=1;
        end
        else if (quadrant_reg[`STAGE-1] == 2'b10) begin
            x_vec_out <= ((x_o_temp[`STAGE-1])/13) <<< 3;
            y_vec_out <= (y_o_temp[`STAGE-1]) * 0;
            z_vec_out <= z_o_temp[`STAGE-1] + `PI;
            rotate_valid <=1;
        end
        else if (quadrant_reg[`STAGE-1] == 2'b11) begin
            x_vec_out <= ((x_o_temp[`STAGE-1])/13) <<< 3;
            y_vec_out <= (y_o_temp[`STAGE-1]) * 0;
            z_vec_out <= z_o_temp[`STAGE-1] + (`PI )*3 >>>1;
            rotate_valid <=1;
        end
    end
end





endmodule