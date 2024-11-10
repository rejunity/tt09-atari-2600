// VGA timing: https://projectf.io/posts/video-timings-vga-720p-1080p/
// PLL setup and sync: https://forum.1bitsquared.com/t/fpga4fun-pong-vga-demo/44
// DVI PMOD 12bpp pcf: https://github.com/icebreaker-fpga/icebreaker-pmod/blob/master/dvi-12bit/icebreaker.pcf or https://github.com/projf/projf-explore/blob/main/graphics/fpga-graphics/ice40/icebreaker.pcf
// DVI PMOD 4bpph pcf: https://github.com/icebreaker-fpga/icebreaker-pmod/blob/master/dvi-4bit/icebreaker.pcf
// Also see: https://projectf.io/posts/fpga-graphics/

`default_nettype none
`define FPGA
`define VGA_6BPP
// `define VGA_12BPP
// `define DVI

// `define VGA_50MHz
// `define QSPI_ROM_EMU
`define NO_MACRO_ROMS
`define QSPI_ROM

module vga_pll(
    input  clk_in,
    output clk_out,
    output locked
);

    // 25.175 MHz
    // USE Command line tool:
    //    icepll -i 12 -o 25.175
    // Given input frequency:        12.000 MHz
    // Requested output frequency:   25.175 MHz
    // Achieved output frequency:    25.125 MHz

    // 50.35 MHz (2x 25.175 MHz)
    // USE Command line tool:
    //    icepll -i 12 -o 50.35
    // Given input frequency:        12.000 MHz
    // Requested output frequency:   50.350 MHz
    // Achieved output frequency:    50.250 MHz

    // iCE40 PLLs are documented in Lattice TN1251 and ICE Technology Library

    SB_PLL40_PAD #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'b0000),         // DIVR =  0
        .DIVF(7'b1000010),      // DIVF = 66
`ifdef VGA_50MHz
        .DIVQ(3'b100),          // DIVQ =  4
`else
        .DIVQ(3'b101),          // DIVQ =  5
`endif
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

    output FLASH_SCK,
    output FLASH_SSB,
    inout  FLASH_IO0,
    inout  FLASH_IO1,
    inout  FLASH_IO2,
    inout  FLASH_IO3,

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
        if (reset_on_powerup & counter > 512)
            reset_on_powerup <= 0;

    reg [31:0] reset_button_hold_counter;
    always @(posedge clk_pixel) begin
        if (~BTN_N)
            reset_button_hold_counter <= reset_button_hold_counter + 1;
        else
            reset_button_hold_counter <= 0;
    end
    wire reset_button = reset_button_hold_counter >= 60*800*525; // 1 sec
    wire reset = reset_button || reset_on_powerup;

    wire [7:0] pmod1_out;
    wire [7:0] pmod2_out;
    wire [7:0] pmod2_in;
    wire [7:0] pmod2_oe;
    tt_um_rejunity_atari2600 atari2600(
        // localparam UP = 3, RIGHT = 6, LEFT = 5, DOWN = 4, SELECT = 2, RESET = 0, FIRE = 1;
        // .ui_in({BTN3, BTN2, BTN3, BTN2, 1'b0, BTN1, BTN_N}),
        .ui_in({~BTN_N, 1'b0, 1'b0, BTN1, BTN3, BTN2, BTN3, BTN2}),
        .uo_out(pmod1_out),
        .uio_in(pmod2_in),
        .uio_out(pmod2_out),
        .uio_oe(pmod2_oe),
        .ena(1'b1),
        .clk(clk_pixel),
        .rst_n(~reset)
    );

    assign LED5 = pmod2_out[7];

`ifdef VGA_6BPP
    // TinyVGA by Mole99
    assign {
            vga_6bpp_hsync, vga_6bpp_b[0], vga_6bpp_g[0], vga_6bpp_r[0],
            vga_6bpp_vsync, vga_6bpp_b[1], vga_6bpp_g[1], vga_6bpp_r[1]} = pmod1_out;

    assign pmod_1b = {8{pmod2_out[7]}};
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
    wire h_sync = pmod1_out[7];
    wire v_sync = pmod1_out[3];
    wire [11:0] pixel_12bpp_rgb =  {pmod1_out[4], pmod1_out[0], 2'b00,
                                    pmod1_out[5], pmod1_out[1], 2'b00,
                                    pmod1_out[6], pmod1_out[2], 2'b00};
`endif


`ifdef QSPI_ROM
    assign FLASH_SCK = pmod2_out[3];
    assign FLASH_SSB = pmod2_out[0];

    // FLASH_IO1..IO3 are bidirectional pins
    // iCE40 IO are documented in Lattice iCE40 Family Handbook
    // PIN_TYPE 
    //  PIN_OUTPUT_TRISTATE  1010       Non-registered tristate output
    //  PIN_INPUT            01         Direct not-registered input
    SB_IO #(
        .PIN_TYPE(6'b1010_01),  // Tri-state buffer with bidirectional control, not registered
        .PULLUP(1'b0)
    ) io0 (
        .PACKAGE_PIN(FLASH_IO0),
        .OUTPUT_ENABLE(pmod2_oe[1]),
        .D_OUT_0(pmod2_out[1]),
        .D_IN_0(pmod2_in[1])
    );

    SB_IO #(
        .PIN_TYPE(6'b1010_01),  // Tri-state buffer with bidirectional control, not registered
        .PULLUP(1'b0)
    ) io1 (
        .PACKAGE_PIN(FLASH_IO1),
        .OUTPUT_ENABLE(pmod2_oe[2]),
        .D_OUT_0(pmod2_out[2]),
        .D_IN_0(pmod2_in[2])
    );

    SB_IO #(
        .PIN_TYPE(6'b1010_01),  // Tri-state buffer with bidirectional control, not registered
        .PULLUP(1'b0)
    ) io2 (
        .PACKAGE_PIN(FLASH_IO2),
        .OUTPUT_ENABLE(pmod2_oe[4]),
        .D_OUT_0(pmod2_out[4]),
        .D_IN_0(pmod2_in[4])
    );

    SB_IO #(
        .PIN_TYPE(6'b1010_01),  // Tri-state buffer with bidirectional control, not registered
        .PULLUP(1'b0)
    ) io3 (
        .PACKAGE_PIN(FLASH_IO3),
        .OUTPUT_ENABLE(pmod2_oe[5]),
        .D_OUT_0(pmod2_out[5]),
        .D_IN_0(pmod2_in[5])
    );

`elsif QSPI_ROM_EMU
    qspi_rom_emu qspi_rom_emu(
        .clk        (clk_pixel),
        .reset      (reset),
        .sclk       (pmod2_out[3]),
        .select     (pmod2_out[0]),
        .cmd_addr_in({pmod2_out[5:4], pmod2_out[2:1]}),
        .data_out   ({pmod2_in [5:4], pmod2_in [2:1]}));

`else
    assign pmod2_in = 8'b0000_0000;
`endif

endmodule
