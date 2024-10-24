// VGA timing: https://projectf.io/posts/video-timings-vga-720p-1080p/
// PLL setup and sync: https://forum.1bitsquared.com/t/fpga4fun-pong-vga-demo/44
// DVI PMOD 12bpp pcf: https://github.com/icebreaker-fpga/icebreaker-pmod/blob/master/dvi-12bit/icebreaker.pcf or https://github.com/projf/projf-explore/blob/main/graphics/fpga-graphics/ice40/icebreaker.pcf
// DVI PMOD 4bpph pcf: https://github.com/icebreaker-fpga/icebreaker-pmod/blob/master/dvi-4bit/icebreaker.pcf
// Also see: https://projectf.io/posts/fpga-graphics/

`define VGA_6BPP
// `define VGA_12BPP
// `define DVI

module vga_pll(
    input  clk_in,
    output clk_out,
    output locked
);

    // iCE40 PLLs are documented in Lattice TN1251 and ICE Technology Library
    // Given input frequency:        12.000 MHz
    // Requested output frequency:   25.175 MHz
    // Achieved output frequency:    25.125 MHz

    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'b0000),         // DIVR =  0
        .DIVF(7'b1000010),      // DIVF = 66
        // .DIVF(7'b0111000),      // DIVF =  ??
        .DIVQ(3'b101),          // DIVQ =  5
        .FILTER_RANGE(3'b001)   // FILTER_RANGE = 1
    ) pll (
        .LOCK(locked),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PACKAGEPIN(clk_in),
        .PLLOUTCORE(clk_out)
    );
endmodule

module top (
    input  CLK,

    input BTN_N,
    input BTN1,
    input BTN2,
    input BTN3,

    output LED1,
    output LED2,
    output LED3,
    output LED4,
    output LED5,

`ifdef VGA_6BPP
    output           vga_6bpp_hsync,
    output           vga_6bpp_vsync,
    output wire[1:0] vga_6bpp_r,
    output wire[1:0] vga_6bpp_g,
    output wire[1:0] vga_6bpp_b,
    
    output wire[7:0] pmod_1b
`elsif VGA_12BPP
    output           vga_12bpp_hsync,
    output           vga_12bpp_vsync,
    output wire[3:0] vga_12bpp_r,
    output wire[3:0] vga_12bpp_g,
    output wire[3:0] vga_12bpp_b,
`elsif DVI
    output           dvi_clk,
    output           dvi_hsync,
    output           dvi_vsync,
    output           dvi_de,
    output wire[3:0] dvi_r,
    output wire[3:0] dvi_g,
    output wire[3:0] dvi_b
`else
    output wire[7:0] pmod_1a,
    output wire[7:0] pmod_1b
`endif
);
    reg [31:0] counter;
    reg flip;
    always @(posedge clk_pixel) begin
        counter <= counter + 1;
        if (counter == 60*800*525) begin
            flip <= ~flip;
            counter <= 0;
        end
    end

    assign LED1 = flip;
    assign LED2 = BTN1;
    assign LED3 = BTN2;
    assign LED4 = BTN3;

    reg clk_pixel;
    vga_pll pll(
        .clk_in(CLK),
        .clk_out(clk_pixel),
        .locked()
    );

    reg reset_on_powerup = 1;
    always @(posedge clk_pixel)
        if (reset_on_powerup & counter > 10)
            reset_on_powerup <= 0;

    reg [31:0] reset_button_hold_counter;
    always @(posedge clk_pixel) begin
        if (~BTN_N)
            reset_button_hold_counter <= reset_button_hold_counter + 1;
        else
            reset_button_hold_counter <= 0;
    end
    wire reset_button = reset_button_hold_counter >= 60*800*525; // 1 sec

    reg [7:0] out_pmod1;
    reg [7:0] out_pmod2;
    tt_um_rejunity_atari2600 atari2600(
        // localparam UP = 3, RIGHT = 6, LEFT = 5, DOWN = 4, SELECT = 2, RESET = 0, FIRE = 1;
        .ui_in({BTN3, BTN2, BTN3, BTN2, 1'b0, BTN1, BTN_N}),
        .uo_out(out_pmod1),
        .uio_in(8'h00),
        .uio_out(out_pmod2),
        .uio_oe(),
        .ena(1'b1),
        .clk(clk_pixel),
        .rst_n(~(reset_button || reset_on_powerup))
    );

    assign LED5 = out_pmod2[0];

`ifdef VGA_6BPP
    // TinyVGA by Mole99
    assign {
            vga_6bpp_hsync, vga_6bpp_b[0], vga_6bpp_g[0], vga_6bpp_r[0],
            vga_6bpp_vsync, vga_6bpp_b[1], vga_6bpp_g[1], vga_6bpp_r[1]} = out_pmod1;
                                                                         // ^ BTN1 * (out_pmod2[0] * 8'b0111_0111);
    assign pmod_1b = {8{out_pmod2[0]}};
`elsif VGA_12BPP
    // VGA double PMOD from Digilent
    assign {vga_12bpp_r, vga_12bpp_g, vga_12bpp_b,
            vga_12bpp_hsync, vga_12bpp_vsync} = {pixel_12bpp_rgb, h_sync, v_sync};
`elsif DVI
    // DVI/HDMI double PMOD from Digilent
    wire is_display_area = !h_sync && !v_sync;
    assign {dvi_r, dvi_g, dvi_b,
            dvi_hsync, dvi_vsync, dvi_de, dvi_clk} = {pixel_12bpp_rgb, h_sync, v_sync, is_display_area, clk_pixel};
`else
`endif

`ifdef VGA_6BPP
`else 
    wire h_sync = out_pmod1[7];
    wire v_sync = out_pmod1[3];
    wire [11:0] pixel_12bpp_rgb =  {out_pmod1[4], out_pmod1[0], 2'b00,
                                    out_pmod1[5], out_pmod1[1], 2'b00,
                                    out_pmod1[6], out_pmod1[2], 2'b00};
`endif

endmodule
