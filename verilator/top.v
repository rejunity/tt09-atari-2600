// VGA timing: https://projectf.io/posts/video-timings-vga-720p-1080p/
// PLL setup and sync: https://forum.1bitsquared.com/t/fpga4fun-pong-vga-demo/44
// DVI PMOD 12bpp pcf: https://github.com/icebreaker-fpga/icebreaker-pmod/blob/master/dvi-12bit/icebreaker.pcf or https://github.com/projf/projf-explore/blob/main/graphics/fpga-graphics/ice40/icebreaker.pcf
// DVI PMOD 4bpph pcf: https://github.com/icebreaker-fpga/icebreaker-pmod/blob/master/dvi-4bit/icebreaker.pcf
// Also see: https://projectf.io/posts/fpga-graphics/

`define VGA_6BPP
// `define VGA_12BPP
// `define DVI

`define NO_MACRO_ROMS
`define QSPI_ROM

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
    output      tia_vsync,
    output      tia_vblank,
    output      vsync,
    output      hsync,
    output      [7:0] r,
    output      [7:0] g,
    output      [7:0] b,
    output      pwm_audio
);
    wire[1:0] vga_6bpp_r;
    wire[1:0] vga_6bpp_g;
    wire[1:0] vga_6bpp_b;

    wire [7:0] pmod1_out;
    wire [7:0] pmod2_out;
    wire [7:0] pmod2_in;

    wire [4:0] switches = {sw4, sw3, sw2, sw1, btn_select};
    reg  [4:0] prev_switches; always @(posedge clk_pixel) prev_switches <= switches;
    tt_um_rejunity_atari2600 atari2600(
        // localparam UP = 3, RIGHT = 6, LEFT = 5, DOWN = 4, SELECT = 2, RESET = 0, FIRE = 1;
        // .ui_in({btn_right, btn_left, btn_down, btn_up, btn_select, btn_fire, ~btn_reset}),
        .ui_in(
            (prev_switches != switches) ?
            // (0)?
            {btn_reset, 1'b1, 1'b1, sw4, sw3, sw2, sw1, btn_select} :
            {btn_reset, 1'b0, 1'b0, btn_fire, btn_right, btn_left, btn_down, btn_up}),
        .uo_out (pmod1_out),
        .uio_in (pmod2_in ),
        .uio_out(pmod2_out),
        .uio_oe(),
        .ena(1'b1),
        .clk(clk_pixel),
        .rst_n(~reset)
    );
    assign {
            hsync, vga_6bpp_b[0], vga_6bpp_g[0], vga_6bpp_r[0],
            vsync, vga_6bpp_b[1], vga_6bpp_g[1], vga_6bpp_r[1]} = pmod1_out;

    assign r = {vga_6bpp_r, 6'd0};
    assign g = {vga_6bpp_g, 6'd0};
    assign b = {vga_6bpp_b, 6'd0};

`ifdef QSPI_ROM
    qspi_rom_emu qspi_rom_emu(
        .clk        (clk_pixel),
        .reset      (reset),
        .sclk       (pmod2_out[3]),
        .select     (pmod2_out[0]),
        .cmd_addr_in({pmod2_out[5:4], pmod2_out[2:1]}),
        .data_out   ({pmod2_in [5:4], pmod2_in [2:1]}));
    assign tia_vblank = 0; // not enough pins
`else
    assign pmod2_in = {4'b0000, sw4, sw3, sw2, sw1};
    assign tia_vblank = pmod2_out[5];
`endif
    assign tia_vsync  = pmod2_out[6];
    assign pwm_audio  = pmod2_out[7];

endmodule
