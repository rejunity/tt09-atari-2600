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
    // input  wire [7:0] buttons,
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
        // .ui_in({BTN2, BTN3, BTN2, BTN3, 1'b0, BTN1, 1'b0}),
        .ui_in(8'h00),
        .uo_out(demo_out_pmod1),
        .uio_in(8'h00),
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
