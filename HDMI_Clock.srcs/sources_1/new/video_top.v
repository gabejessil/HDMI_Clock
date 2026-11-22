`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Gabriel J. Silva
// 
// Create Date: 10/18/2026 10:59:51 PM
// Design Name: HDMI Vertical Bars 
// Module Name: video_top
// Project Name: HDMI_bars_project
// Target Devices: PYNQ Z-1, ZYNQ XC7Z020-1CLG400C
// Tool Versions: 2023.2
// Description: Top level file; First HDMI project; Attempting to get vertical colored bars on the display
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module video_top(
    input sys_clk,
    input sys_rst,
    output TMDS_Clk_p,
    output TMDS_Clk_n,
    output [2:0] TMDS_Data_p,
    output [2:0] TMDS_Data_n
);

    wire video_vde;
    wire video_hsync;
    wire video_vsync;
    wire [23:0] video_data;
    wire pixel_clk;
    wire clk_locked;
    wire clk_reset;
    wire ready;
    
    assign ready = sys_rst | ~clk_locked;
    // Instantiate the clock wizard
     clk_wiz_0 updated_inst (
        .clk_in1(sys_clk),
        .clk_out1(pixel_clk),
        .reset(clk_reset), 
        .locked(clk_locked)
      );
    
    // Instantiate the video timing and pattern generator
    video_tim_pat_gen timing_pattern_inst (
        .pixel_clk (pixel_clk),
        .rst (ready),
        .vid_pVDE (video_vde),
        .vid_pHSync (video_hsync),
        .vid_pVSync (video_vsync),
        .vid_Data (video_data)
    );
    
    // Instantiate the Digilent IP
    rgb2dvi #(
        // PARAMETERS
        .kGenerateSerialClk (1'b1),
        .kClkPrimitive      ("PLL"),
        .kClkRange          (2),
        .kRstActiveHigh     (1'b1)
    ) rgb2dvi_inst (
        // OUPUTS
        .TMDS_Clk_p  (TMDS_Clk_p),
        .TMDS_Clk_n  (TMDS_Clk_n),
        .TMDS_Data_p (TMDS_Data_p),
        .TMDS_Data_n (TMDS_Data_n),
        
        // INPUTS
        .aRst        (ready),
        .aRst_n      (~ready),
        
        .vid_pData   (video_data),
        .vid_pVDE    (video_vde),
        .vid_pHSync  (video_hsync),
        .vid_pVSync  (video_vsync),
        
        .PixelClk    (pixel_clk),
        .SerialClk   (1'b0) 
    );
endmodule
