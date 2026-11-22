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
    
    // Hour Indicator Coordinate LUT; Column 0 = Horizontal; Column 1 = Vertical
    reg [10:0] hr_coo [0:11][0:1];
    
    initial begin
        hr_coo[0][0] = 11'd640;
        hr_coo[1][0] = 11'd815;
        hr_coo[2][0] = 11'd943;
        hr_coo[3][0] = 11'd990;
        hr_coo[4][0] = 11'd943;
        hr_coo[5][0] = 11'd846;
        hr_coo[6][0] = 11'd640;
        hr_coo[7][0] = 11'd465;
        hr_coo[8][0] = 11'd337;
        hr_coo[9][0] = 11'd290;
        hr_coo[10][0] = 11'd337;
        hr_coo[11][0] = 11'd465;
        
        hr_coo[0][1] = 11'd10;
        hr_coo[1][1] = 11'd57;
        hr_coo[2][1] = 11'd185;
        hr_coo[3][1] = 11'd360;
        hr_coo[4][1] = 11'd535;
        hr_coo[5][1] = 11'd643;
        hr_coo[6][1] = 11'd710;
        hr_coo[7][1] = 11'd663;
        hr_coo[8][1] = 11'd535;
        hr_coo[9][1] = 11'd360;
        hr_coo[10][1] = 11'd185;
        hr_coo[11][1] = 11'd57;
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
            end else if (((h_cnt <= ((H_ACT-V_ACT)>>1)+20) && (h_cnt >= (H_ACT-V_ACT)>>1)) &&
                         ((v_cnt <= (V_ACT>>1)+10) && (v_cnt >=(V_ACT>>1)-10))) begin
                red <= 8'hff;
                green <= 8'hff;
                blue <= 8'hff;
            end else if (((h_cnt <= V_ACT+((H_ACT-V_ACT)>>1)) && (h_cnt >= V_ACT+(((H_ACT-V_ACT)>>1)-20))) &&
                         ((v_cnt <= (V_ACT>>1)+10) && (v_cnt >=(V_ACT>>1)-10))) begin
                red <= 8'hff;
                green <= 8'hff;
                blue <= 8'hff; 
            end else if (((h_cnt <= (H_ACT>>1)+10) && (h_cnt >= (H_ACT>>1)-10)) &&
                         ((v_cnt <= 20) && (v_cnt >=0))) begin
                red <= 8'hff;
                green <= 8'hff;
                blue <= 8'hff;
            end else if (((h_cnt <= (H_ACT>>1)+10) && (h_cnt >= (H_ACT>>1)-10)) &&
                         ((v_cnt <= V_ACT) && (v_cnt >=V_ACT-20))) begin
                red <= 8'hff;
                green <= 8'hff;
                blue <= 8'hff;    
                   
            end else begin
                red <= 8'h00;
                green <= 8'h00;
                blue <= 8'h00;
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
