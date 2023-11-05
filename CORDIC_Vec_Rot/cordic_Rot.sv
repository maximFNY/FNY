`define PI 12861  //(16,12)  
`define STAGE 12
module cordic_Rot (
    input                           clk,
    input                           rst,
    input   logic   signed  [15:0]  ROT_x_i,
    input   logic   signed  [15:0]  ROT_y_i,
    input   logic   signed  [15:0]  ROT_z_i,
    input   logic                   rot_valid,
    output  logic   signed  [11:0]  x_re_out,
    output  logic   signed  [11:0]  x_im_out,
    output  logic                   valid_o
);



logic ROT_start;
logic ROT_glue_out;
logic signed [15:0] ROT_z_after_rot;
logic signed [15:0] ROT_z_after_rot_nxt;
logic signed [15:0] ROT_x_after_rot;
logic signed [15:0] ROT_x_after_rot_nxt;
logic signed [15:0] ROT_y_after_rot;
logic signed [15:0] ROT_y_after_rot_nxt;
logic signed [15:0] ROT_x_o_temp [0:`STAGE-1];
logic signed [15:0] ROT_y_o_temp [0:`STAGE-1];
logic signed [15:0] ROT_z_o_temp [0:`STAGE-1];
logic signed [15:0] ROT_x_rot_out;
logic signed [15:0] ROT_y_rot_out;
logic signed [15:0] ROT_z_rot_out;

integer ROT_i;
logic signed [15:0] ROT_LUT [0:`STAGE-1];

// pre-rotation: all the inputs should be in quadrant 1
logic [1:0] ROT_quadrant, ROT_quadrant_nxt;
logic [1:0] ROT_quadrant_reg [0:`STAGE-1];
logic ROT_glue_out_reg [0:`STAGE-1];


always_ff @ (posedge clk) begin
    if (rst) begin
        ROT_z_after_rot <= 12'd0;
        ROT_x_after_rot <= 12'd0;
        ROT_y_after_rot <= 12'd0;
        ROT_quadrant <= 0;
        ROT_start <=0;
        
    end
    else begin
        ROT_z_after_rot <= ROT_z_after_rot_nxt;
        ROT_x_after_rot <= ROT_x_after_rot_nxt;
        ROT_y_after_rot <= ROT_y_after_rot_nxt;
        ROT_quadrant <= ROT_quadrant_nxt;
        ROT_start <= rot_valid;
    end
end


always_comb begin
    if (rot_valid) begin
        if (ROT_z_i>0 && ROT_z_i < (`PI >>>1)) begin         //quadrant1
            ROT_z_after_rot_nxt = ROT_z_i;
            ROT_x_after_rot_nxt = ROT_x_i;
            ROT_y_after_rot_nxt = ROT_y_i;
            ROT_quadrant_nxt = 2'b00;
        end 
        else if (ROT_z_i > (`PI >>>1) && ROT_z_i < `PI) begin    //quadrant2
            ROT_z_after_rot_nxt = ROT_z_i - (`PI >>>1);
            ROT_x_after_rot_nxt = (ROT_x_i);
            ROT_y_after_rot_nxt = ROT_y_i;
            ROT_quadrant_nxt = 2'b01;
        end
        else if (ROT_z_i > `PI && ROT_z_i < (`PI )*3 >>>1) begin     //quadrant3 
            ROT_z_after_rot_nxt = ROT_z_i - (`PI);
            ROT_x_after_rot_nxt = (ROT_x_i);
            ROT_y_after_rot_nxt = ROT_y_i;
            ROT_quadrant_nxt = 2'b10;
        end           
        else begin                  //quadrant4
            ROT_z_after_rot_nxt = ROT_z_i - ((`PI )*3 >>>1);
            ROT_x_after_rot_nxt = ROT_x_i;
            ROT_y_after_rot_nxt = ROT_y_i;
            ROT_quadrant_nxt = 2'b11;
         end
    end
end




// LUT
always_comb begin
    ROT_LUT[0] = 16'b0000110010010000;
    ROT_LUT[1] = 16'b0000011101101011;
    ROT_LUT[2] = 16'b0000001111101011;
    ROT_LUT[3] = 16'b0000000111111101;
    ROT_LUT[4] = 16'b0000000011111111;
    ROT_LUT[5] = 16'b0000000001111111;
    ROT_LUT[6] = 16'b0000000000111111;
    ROT_LUT[7] = 16'b0000000000011111;
    ROT_LUT[8] = 16'b0000000000001111;
    ROT_LUT[9] = 16'b0000000000000111;
    ROT_LUT[10] = 16'b0000000000000011;
    ROT_LUT[11] = 16'b0000000000000001;
end   

// rotata mode  z_in =0
// iteration: 12 times  //求theta(z_o)
//pipeline=12
always_ff @ (posedge clk) begin
    if (rst) begin
        ROT_x_o_temp [0:`STAGE-1] <= '{default: '0};
        ROT_z_o_temp [0:`STAGE-1] <= '{default: '0};
        ROT_y_o_temp  [0:`STAGE-1] <= '{default: '0};
        ROT_quadrant_reg[0:`STAGE-1] <= '{default: '0};
        ROT_glue_out_reg[0:`STAGE-1] <= '{default: '0};
    end
    else begin
        if (ROT_start) begin   
            if (ROT_z_after_rot < 0) begin
                ROT_x_o_temp[0] <= ROT_x_after_rot + ROT_y_after_rot;
                ROT_z_o_temp[0] <= ROT_z_after_rot + ROT_LUT[0];
                ROT_y_o_temp[0] <= ROT_y_after_rot - ROT_x_after_rot;
                ROT_quadrant_reg[0] <= ROT_quadrant;
                ROT_glue_out_reg[0] <=1;
            end
            else begin
                ROT_x_o_temp[0] <= ROT_x_after_rot - ROT_y_after_rot;
                ROT_z_o_temp[0] <= ROT_z_after_rot - ROT_LUT[0];
                ROT_y_o_temp[0] <= ROT_y_after_rot + ROT_x_after_rot;
                ROT_quadrant_reg[0] <= ROT_quadrant;
                ROT_glue_out_reg[0] <=1;
            end

            for (ROT_i=1; ROT_i<`STAGE; ROT_i=ROT_i+1) begin
                if (ROT_z_o_temp [ROT_i-1] < 0) begin
                    ROT_x_o_temp[ROT_i] <= ROT_x_o_temp[ROT_i-1] + (ROT_y_o_temp[ROT_i-1] >>> ROT_i);
                    ROT_y_o_temp[ROT_i] <= ROT_y_o_temp[ROT_i-1] - (ROT_x_o_temp[ROT_i-1] >>> ROT_i);
                    ROT_z_o_temp[ROT_i] <= ROT_z_o_temp[ROT_i-1] + ROT_LUT[ROT_i];
                    ROT_quadrant_reg[ROT_i] <= ROT_quadrant_reg [ROT_i-1];
                    ROT_glue_out_reg[ROT_i] <= ROT_glue_out_reg[ROT_i-1];
                end
                else begin
                    ROT_x_o_temp[ROT_i] <= ROT_x_o_temp[ROT_i-1] - (ROT_y_o_temp[ROT_i-1] >>> ROT_i);
                    ROT_z_o_temp[ROT_i] <= ROT_z_o_temp[ROT_i-1] - ROT_LUT[ROT_i];
                    ROT_y_o_temp[ROT_i] <= ROT_y_o_temp[ROT_i-1] + (ROT_x_o_temp[ROT_i-1] >>> ROT_i);
                    ROT_quadrant_reg[ROT_i] <= ROT_quadrant_reg [ROT_i-1];
                    ROT_glue_out_reg[ROT_i] <= ROT_glue_out_reg[ROT_i-1];
                end
            end
        end
    end 
end



//glue logic at output
always_ff @(posedge clk) begin
    if (rst) begin
        x_re_out <= 0;
        x_im_out <= 0;
        valid_o <= 0;
    end
    if (ROT_glue_out_reg[`STAGE-1]) begin
        if (ROT_quadrant_reg[`STAGE-1] == 2'b00) begin
            x_re_out <= ((ROT_x_o_temp[`STAGE-1])/13) <<< 3;
            x_im_out <= (ROT_y_o_temp[`STAGE-1]/13) <<< 3 ;
            ROT_z_rot_out <= ROT_z_o_temp[`STAGE-1];
            valid_o <= 1;
        end
        else if (ROT_quadrant_reg[`STAGE-1] == 2'b01) begin
            x_re_out <= ((-(ROT_y_o_temp[`STAGE-1]))/13) <<< 3;
            x_im_out <= ((ROT_x_o_temp[`STAGE-1])/13) <<< 3;
            ROT_z_rot_out <= ROT_z_o_temp[`STAGE-1] + (`PI >>> 1);
            valid_o <= 1;
        end
        else if (ROT_quadrant_reg[`STAGE-1] == 2'b10) begin
            x_re_out <= ((-(ROT_x_o_temp[`STAGE-1]))/13) <<< 3;
            x_im_out <= ((-(ROT_y_o_temp[`STAGE-1]))/13) <<< 3;
            ROT_z_rot_out <= ROT_z_o_temp[`STAGE-1] + `PI;
            valid_o <= 1;
        end
        else if (ROT_quadrant_reg[`STAGE-1] == 2'b11) begin
            x_re_out <= (((ROT_y_o_temp[`STAGE-1]))/13) <<< 3;
            x_im_out <= ((-(ROT_x_o_temp[`STAGE-1]))/13) <<< 3;
            ROT_z_rot_out <= ROT_z_o_temp[`STAGE-1] + ((-`PI )>>> 1);
            valid_o <= 1;
        end
    end
end




endmodule