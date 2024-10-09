// VGA timing: https://projectf.io/posts/video-timings-vga-720p-1080p/
// PLL setup and sync: https://forum.1bitsquared.com/t/fpga4fun-pong-vga-demo/44
// DVI PMOD 12bpp pcf: https://github.com/icebreaker-fpga/icebreaker-pmod/blob/master/dvi-12bit/icebreaker.pcf or https://github.com/projf/projf-explore/blob/main/graphics/fpga-graphics/ice40/icebreaker.pcf
// DVI PMOD 4bpph pcf: https://github.com/icebreaker-fpga/icebreaker-pmod/blob/master/dvi-4bit/icebreaker.pcf
// Also see: https://projectf.io/posts/fpga-graphics/

`define VGA_6BPP
// `define VGA_12BPP
// `define DVI

module top  (
    input  wire clk_pixel,
    input  wire reset,
    input  wire btn_select,
    input  wire btn_reset,
    input  wire btn_fire,
    input  wire btn_up,
    input  wire btn_down,
    input  wire btn_left,
    input  wire btn_right,
    input  wire sw1,
    input  wire sw2,
    input  wire sw3,
    input  wire sw4,
    // output      [9:0] xpos,
    // output      [9:0] ypos,
    // output      video_active,
    output      vsync,
    output      hsync,
    output      [7:0] r,
    output      [7:0] g,
    output      [7:0] b
);

    wire[1:0] vga_6bpp_r;
    wire[1:0] vga_6bpp_g;
    wire[1:0] vga_6bpp_b;

    reg [7:0] demo_out_pmod1;
    reg [7:0] demo_out_pmod2;
    tt_um_rejunity_atari2600 demo(
        // localparam UP = 3, RIGHT = 6, LEFT = 5, DOWN = 4, SELECT = 2, RESET = 0, FIRE = 1;
        .ui_in({btn_right, btn_left, btn_down, btn_up, btn_select, btn_fire, ~btn_reset}),
        .uo_out(demo_out_pmod1),
        .uio_in({4'b0000, sw4, sw3, sw2, sw1}),
        .uio_out(demo_out_pmod2),
        .uio_oe(),
        .ena(1'b1),
        .clk(clk_pixel),
        .rst_n(~reset)
    );
    assign {
            hsync, vga_6bpp_b[0], vga_6bpp_g[0], vga_6bpp_r[0],
            vsync, vga_6bpp_b[1], vga_6bpp_g[1], vga_6bpp_r[1]} = demo_out_pmod1;
                                                             // ^ BTN1 * (demo_out_pmod2[0] * 8'b0111_0111);

    // assign pmod_1b = demo_out_pmod2;

    assign r = {vga_6bpp_r, 6'd0}; 
    assign g = {vga_6bpp_g, 6'd0};
    assign b = {vga_6bpp_b, 6'd0};

endmodule
