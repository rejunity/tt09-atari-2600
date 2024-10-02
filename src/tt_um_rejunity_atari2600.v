/*
 * Copyright (c) 2024 Renaldas Zioma
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_rejunity_atari2600 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] x;
  wire [9:0] y;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  reg [9:0] counter;

  vga_hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(x),
    .vpos(y)
  );


  // ===============================================================
  // Clock Enable Generation
  // ===============================================================

  // Atari 2600 Clocks
  // Video Color Clock: 3.579545 MHz (NTSC), 3.546894 MHz (PAL)
  // CPU Machine Clock: 1.193182 MHz (NTSC), 1.182298 MHz (PAL)
  // The CPU Clock is derived from Video clock divided by three.
  // One color clock = 1 pixel. One machine clock = 3 pixels.

  // pixel ~1:7  VGA clock
  // CPU   ~1:21 VGA clock

  // reg [c_speed:0] clk_counter = 0;
  // wire            cpu_enable = clk_counter == 0;
  // wire            tia_enable = clk_counter >= 5 && clk_counter <= 7;
  // wire            clk_cpu = clk_counter[c_speed];

  // -------------------------------------------------------------------------
  wire [15:0] address_bus;
  reg  [7:0] data_in; // register - because that's how Arlet Otten's 6502 impl wants it
  wire [7:0] data_out;
  wire write_enable;
  // reg stall_cpu;
  wire  stall_cpu = 1'b0;

  cpu cpu(
    .clk(clk), // TODO: wrong clock
    .reset(~rst_n),
    .AB(address_bus),
    .DI(data_in),
    .DO(data_out),
    .WE(write_enable),
    .IRQ(1'b0), // pins are not inverted in Arlet Otten's 6502 impl
    .NMI(1'b0), // pins are not inverted in Arlet Otten's 6502 impl
    .RDY(!stall_cpu));

  reg [7:0] ram [ 127:0];
  reg [7:0] rom [4095:0];
  initial begin
    $readmemh("../roms/rom.mem", rom, 0, 4095);
    // DEBUG: override reset vector
    // rom[12'hFFD] <= 8'hF0; rom[12'hFFC] <= 8'h00;
  end

  wire ram_cs = (address_bus[12:7] == 6'b0_0000_1);   // RAM: 0080-00FF
  wire rom_cs = (address_bus[12  ] == 1'b1);          // ROM: F000-FFFF
  wire tia_cs = (address_bus[12:6] == 7'b0_0000_00);  // TIA registers: 0000h - 003Fh 
  wire pia_cs = (address_bus[12:5] == 8'b0_0010_100); // PIA registers: 0280h - 029Fh
  // F000-FFFF ROM   11111111  Cartridge ROM (4 Kbytes max)
  // F000-F07F RAMW  11111111  Cartridge RAM Write (optional 128 bytes)
  // F000-F0FF RAMW  11111111  Cartridge RAM Write (optional 256 bytes)
  // F080-F0FF RAMR  11111111  Cartridge RAM Read (optional 128 bytes)
  // F100-F1FF RAMR  11111111  Cartridge RAM Read (optional 256 bytes)
  // 003F      BANK  ......11  Cart Bank Switching (for some 8K ROMs, 4x2K)
  // FFF4-FFFB BANK  <strobe>  Cart Bank Switching (for ROMs greater 4K)
  // FFFC-FFFD ENTRY 11111111  Cart Entrypoint (16bit pointer)
  // FFFE-FFFF BREAK 11111111  Cart Breakpoint (16bit pointer)

  // assign data_in = rom[address_bus[11:0]];
                  // //tia_cs ? tia_dat_o :
                  //  //pia_cs ? pia_dat_o :
                  //  ram_cs ? ram[address_bus[ 6:0]] :
                  //  rom_cs ? rom[address_bus[11:0]] : 
                  //  8'h00; // pull-downs

  always @(posedge clk) begin
    if (write_enable && ram_cs) ram[address_bus[6:0]] <= data_out;
    if (ram_cs) data_in <= ram[address_bus[ 6:0]];
    if (rom_cs) data_in <= rom[address_bus[11:0]];
  end

endmodule
