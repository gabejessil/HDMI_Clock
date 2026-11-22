`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Gabriel J. Silva
// 
// Create Date: 10/18/2026 07:36:39 PM
// Design Name: HDMI Vertical Bars 
// Module Name: video_tim_pat_gen
// Project Name: HDMI_bars_project
// Target Devices: PYNQ Z-1, ZYNQ XC7Z020-1CLG400C
// Tool Versions: 2023.2
// Description: Sets timing for video; Establishes a simple "pattern generator" that creates RGB bars on display
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module video_tim_pat_gen(
        input pixel_clk,                // 74.25 MHz
        input rst,
        output vid_pVDE,            // Video Data Enable
        output vid_pHSync,          // Horiztonal Sync
        output vid_pVSync,          // Vertical Sync
        output reg [23:0] vid_Data      // Data: [23:16] red, [15:8] blue, [7:0] green
    );
    
    // DISPLAY DIMENSIONS - standard VESA or CEA timing parameters
    // In this case 1280x720 @ 60Hz
    // HORIZONTAL PARAMETERS
    parameter H_ACT = 1280;
    parameter H_FRO = 110;
    parameter H_SYN = 40;
    parameter H_BAC = 220;
    parameter H_TOT = H_ACT + H_FRO + H_SYN + H_BAC;
    
    //VERTICAL PARAMETERS
    parameter V_ACT = 720;
    parameter V_FRO = 5;
    parameter V_SYN = 5;
    parameter V_BAC = 20;
    parameter V_TOT = V_ACT + V_FRO + V_SYN + V_BAC;
    
    // Horizontal and Vertical Counters
    reg [$clog2(H_TOT):0] h_cnt;
    reg [$clog2(V_TOT):0] v_cnt;
       
    // RGB 
    reg [7:0] red;
    reg [7:0] green;
    reg [7:0] blue;
    
    // Hour Indicator Coordinate LUT; Column 0 = Horizontal; Column 1 = Vertical; Pixel color flag
    reg [10:0] hour_loc [0:11][0:1];
    reg pixel_white = 1'b0;
    integer i;

    initial begin
        hour_loc[0][0] = 11'd640;
        hour_loc[1][0] = 11'd790;
        hour_loc[2][0] = 11'd900;
        hour_loc[3][0] = 11'd940;
        hour_loc[4][0] = 11'd900;
        hour_loc[5][0] = 11'd817;
        hour_loc[6][0] = 11'd640;
        hour_loc[7][0] = 11'd490;
        hour_loc[8][0] = 11'd380;
        hour_loc[9][0] = 11'd340;
        hour_loc[10][0] = 11'd380;
        hour_loc[11][0] = 11'd490;
    
        hour_loc[0][1] = 11'd60;
        hour_loc[1][1] = 11'd100;
        hour_loc[2][1] = 11'd210;
        hour_loc[3][1] = 11'd360;
        hour_loc[4][1] = 11'd510;
        hour_loc[5][1] = 11'd603;
        hour_loc[6][1] = 11'd660;
        hour_loc[7][1] = 11'd620;
        hour_loc[8][1] = 11'd510;
        hour_loc[9][1] = 11'd360;
        hour_loc[10][1] = 11'd210;
        hour_loc[11][1] = 11'd100;
    end
    
    // Counter Loop, counts across H and V Pixels
    always @(posedge pixel_clk or posedge rst) begin
        if (rst) begin
            h_cnt <= 0;
            v_cnt <= 0;
        end else begin
            if (h_cnt == (H_TOT-1) && v_cnt == (V_TOT-1)) begin
                h_cnt <= 0;
                v_cnt <= 0;
            end else if (h_cnt == (H_TOT-1)) begin
                h_cnt <= 0;
                v_cnt <= v_cnt + 1;
            end else begin
                h_cnt <= h_cnt + 1;
            end
        end        
    end
    
    //
    
    // Determine Video Data Enable and if the horizontal & vertical counters are within their Sync Pulse
    assign vid_pVDE = !rst && (h_cnt < H_ACT && v_cnt < V_ACT);
    assign vid_pHSync = !rst && (h_cnt >= (H_ACT + H_FRO) && h_cnt < (H_ACT + H_FRO + H_SYN));
    assign vid_pVSync = !rst && (v_cnt >= (V_ACT + V_FRO) && v_cnt < (V_ACT + V_FRO + V_SYN));
    
    // Loop for setting RGB data, Pattern Generator!
    always @(posedge pixel_clk or posedge rst) begin
        if (rst) begin
            red <= 0;
            green <= 0;
            blue <= 0;
        end else begin
            if (!vid_pVDE) begin
                red <= 8'h00;
                green <= 8'h00;
                blue <= 8'h00;
            end else begin
                for (i = 0; i < 12; i = i +1) begin
                    if((h_cnt < (hour_loc[i][0] + 10) && h_cnt >= (hour_loc[i][0] - 10)) &&
                        (v_cnt < (hour_loc[i][1] + 10) && v_cnt >= (hour_loc[i][1] - 10))) begin
                        pixel_white = 1'b1;
                    end                 
                end
                if (pixel_white) begin
                    red <= 8'hff;
                    green <= 8'hff;
                    blue <= 8'hff;
                end else begin             
                   red <= 8'h00;
                   green <= 8'h00;
                   blue <= 8'h00;
                end
                pixel_white <= 1'b0;            
            end
        end
    end
    
    // Set the data out
    always @(*) begin
        vid_Data [23:16] = red;     // Channel 2
        vid_Data [15:8] = blue;     // Channel 0
        vid_Data [7:0] = green;     // Channel 1
    end       
endmodule
