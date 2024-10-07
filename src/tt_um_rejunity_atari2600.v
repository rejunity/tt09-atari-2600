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
  wire [9:0] vga_xpos;
  wire [9:0] vga_ypos;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  vga_hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    // .force_vsync(tia_ypos == 1),
    // .force_vsync(tia_vsync),
    .force_vsync(0),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(vga_xpos),
    .vpos(vga_ypos)
  );

  // Inputs
  // TODO: fix a weird mapping in TIA.v / PIA.v
  wire [6:0] buttons = ui_in[6:0];
  wire [3:0] switches = {ena, ui_in[7], uio_in[1:0]};

  // UXL3S was: buttons({~r_btn[6:1], r_btn[0]})

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

  reg [4:0] clk_counter;
  always @(posedge clk) begin
    if (~rst_n || vga_xpos >= 798 ) begin // skip last 2 pixels to match TIA scanline 228*7=1596 to pair of VGA 800*2=1600 scanlines
      clk_counter <= 0;
    end else begin
        if (clk_counter == 20) begin
          clk_counter <= 0;
        end else
          clk_counter <= clk_counter + 1'b1;
    end
  end


  // TIA clock
  // 012345678901234567890
  // ***    ***    ***    ***
  // _ _    _ _    _ _ 
  //    _ _    _ _    

  // wire clk_tia = clk_counter[4:1] == 0 | clk_counter[4:1] == 3 | clk_counter[4:1] == 7;
  // wire clk_cpu = clk_counter[4:3] == 2'b0; // 8 out of 21, so that we have at least 1 TIA clock during the CPU clock pulses
  // wire clk_pia = ~clk_cpu; // opposite of clk_cpu, emulates phi2 out from CPU
  // wire clk_tia_ = clk_counter == 0 | clk_counter == 7 | clk_counter == 14;
  // wire clk_cpu_ = clk_counter[4] == 0; // 16 out of 21, alternative clock ^^^
  // wire clk_pia_ = clk_counter == 16;
  wire cpu_enable = clk_counter == 0;
  wire tia_enable = clk_counter == 1 | clk_counter == 8 | clk_counter == 15;//!wait_for_vga_vsync;
  wire pia_enable = clk_counter == 0;


  // // Global buffer instantiation for the divided clock signal
  // `ifdef ICE40
  // wire clk_tia;
  // SB_GB clk_tia_inst (
  //     .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_tia_),
  //     .GLOBAL_BUFFER_OUTPUT(clk_tia)
  // );
  // wire clk_cpu;
  // SB_GB clk_cpu_inst (
  //     .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_cpu_),
  //     .GLOBAL_BUFFER_OUTPUT(clk_cpu)
  // );
  // wire clk_pia;
  // SB_GB clk_pia_inst (
  //     .USER_SIGNAL_TO_GLOBAL_BUFFER(clk_pia_),
  //     .GLOBAL_BUFFER_OUTPUT(clk_pia)
  // );
  // `else
  // wire clk_tia = clk_tia_;
  // wire clk_cpu = clk_cpu_;
  // wire clk_pia = clk_pia_;
  // `endif

  // reg [6:0] scanline [159:0];
  reg [7:0] scanline [255:0];
  wire [7:0] tia_xpos;
  always @(posedge clk) begin
    // if (tia_xpos < 30)// && clk_tia)
    //   scanline[tia_xpos] <= 6'b00_00_11 | tia_color_out[5:0];
    // else if (tia_xpos < 160)// && clk_tia)
    //   scanline[tia_xpos] <= 6'b00_11_00 | tia_color_out[5:0];
    if (tia_xpos < 160)// && clk_tia)
      scanline[tia_xpos] <= tia_color_out[5:0];
  end

  wire [8:0] tia_ypos;
  wire wait_for_vga_vsync = 0;//tia_ypos == 2 & vga_ypos < 10'h1EA;

  // always @(posedge clk)
  // wire [8:0] tia_ypos;
  // reg wait_for_vga_vsync;
  // reg tia_vsync_last;
  // always @(posedge clk)
  //   if (~rst_n) begin
  //     wait_for_vga_vsync <= 0;
  //     prev_tia_vsync <= 0;
  //   end else begin
  //     if (~tia_vsync_last & tia_vsync) // posedge _/
  //       wait_for_vga_vsync <= 1;
  //     if (vsync)
  //       wait_for_vga_vsync <= 0;
  //     tia_vsync_last <= tia_vsync;
  //   end

  wire [6:0] hue_luma = vga_xpos < 640 ? scanline[vga_xpos / 4] : 0;
  wire [3:0] hue = hue_luma[6:3];
  wire [3:0] luma = {hue_luma[2:0], 1'b0};
  wire [23:0] rgb_24bpp;
  palette palette_24bpp (
      .hue(hue),
      .lum(luma),
      .rgb_24bpp(rgb_24bpp)
  );


  reg [7:0] tia_xpos_;
  reg [6:0] hue_luma_;
  // always @(posedge clk)
  //   if (clk_tia)
  //     tia_xpos_ <= tia_xpos;
  // always @(negedge clk_tia)
  //     tia_xpos_ <= tia_xpos;
  // always @(negedge clk_tia)
  //     hue_luma_ <= hue_luma;
  // always @(negedge clk_tia)
  //   if (tia_xpos < 160)
  //     scanline[tia_xpos] <= tia_color_out;

  assign {R, G, B} = (!video_active) ? 6'b00_00_00:
                      // scanline[vga_xpos[6:0]][5:0]
                      scanline[vga_xpos[9:2]][5:0]
                      // tia_color_out[6:1]
  // & ~tia_vblank) ? 
                          // (tia_vsync ? 6'b11_00_00 : 0) |
                           // (
                           //  (tia_xpos_ <  80) ? 6'b11_00_00:
                           //  (tia_xpos_ < 160) ? 6'b00_11_00:
                           //                     6'b00_00_11)
                           // (~tia_wr) ? 6'b11_00_00 :
                          // (tia_vblank ? 6'b01_01_01 : 0)
                       // {rgb_24bpp[23], rgb_24bpp[23-1],
                       //  // rgb_24bpp[15], rgb_24bpp[15-1],
                       //  tia_ypos[2:1],
                       //  rgb_24bpp[ 7], rgb_24bpp[ 7-1]}
                        ;

  // -------------------------------------------------------------------------
  wire [15:0] address_bus_w;
  reg [15:0] address_bus_r;
  wire [15:0] address_bus = cpu_enable ? address_bus_w : address_bus_r;
  reg  [7:0] data_in; // register - because that's how Arlet Otten's 6502 impl wants it
  wire [7:0] data_out;
  wire write_enable;
  reg stall_cpu;

  always @(posedge clk)
    address_bus_r <= address_bus;

  // roms/pong.asm:
  //                Clear label is reached just after    6 us
  //                1st WSYNC            --//--       2139 us
  //    after Clear STA COLUPF           --//--       2140 us             
  //                Frame label          --//--       2250 us
  //                VBLANK is initiated  --//--       2263 us
  //                1st write PIA#296    --//--       2424 us
  //                Vblank0 label        --//--       -//- us
  //                1st read  PIA#284    --//--       2490 us

  cpu cpu(
    .clk(clk), // TODO: wrong clock
    .reset(~rst_n),
    .AB(address_bus_w),
    .DI(data_in),
    .DO(data_out),
    .WE(write_enable),
    .IRQ(1'b0),  // pins are not inverted in Arlet Otten's 6502 impl
    .NMI(1'b0),  // pins are not inverted in Arlet Otten's 6502 impl
    .RDY(cpu_enable & !stall_cpu) // & !wait_for_vga_vsync));
    );

  reg [7:0] ram [ 127:0];
  reg [7:0] rom [4095:0];
  initial begin
    $readmemh("../roms/rom.mem", rom, 0, 4095);
    // DEBUG: override reset vector
    // rom[12'hFFD] <= 8'hF0; rom[12'hFFC] <= 8'h00;
  end

  wire [3:0] audio_l;
  wire [3:0] audio_r;
  wire [7:0] tia_data_in = data_out;
  reg  [7:0] tia_data_out;
  reg  [6:0] tia_color_out;
  // wire  [7:0] tia_data_out;
  // wire  [6:0] tia_color_out;
  wire       tia_vblank;
  wire       tia_vsync;
  reg        tia_wr;

  tia tia (
    .clk_i(clk),//_tia),
    .rst_i(~rst_n),
    .stb_i(tia_cs & cpu_enable),
    .we_i(write_enable),
    .adr_i(address_bus[5:0]),
    .dat_i(tia_data_in),
    .dat_o(tia_data_out),
    .buttons(buttons),
    .pot(8'd200),
    .audio_left(audio_l),
    .audio_right(audio_r),
    .stall_cpu(stall_cpu),
    .enable_i(tia_enable),
    .cpu_enable_i(cpu_enable),
    .vid_out(tia_color_out),
    .vid_xpos(tia_xpos),
    .vid_ypos(tia_ypos),
    .vid_vblank(tia_vblank),
    .vid_vsync(tia_vsync),
    // .vid_addr(vid_out_addr),
    .vid_wr(tia_wr),
    .pal(1'b0)
    // .pal(pal),
    // .diag(tia_diag)
  );

  wire [7:0] pia_data_in = data_out;
  wire [7:0] pia_data_out;

  pia pia (
    .clk_i(clk),
    .rst_i(~rst_n),
    .enable_i(pia_enable),
    .stb_i(pia_cs & cpu_enable),
    .we_i(write_enable),
    .adr_i(address_bus[6:0]),
    .dat_i(pia_data_in),
    .dat_o(pia_data_out),
    .buttons(buttons),
    .sw(switches)
    // .diag(pia_diag)
  );


  // TODO: mirrors
  // TODO: according to schematics  tia_cs = (/CS0)~12 & (/CS3)~7
  //                                pia_cs = (/CS2)~12 & ( CS1) 7 & ( RS) 9
  //                                ram_cs = (/CS2)~12 & ( CS1) 7 &!( RS) 9
  //wire ram_cs = (address_bus[12:7] == 6'b0_0000_1);   // RAM: 0080-00FF
  wire rom_cs = (address_bus[12  ] == 1'b1);          // ROM: F000-FFFF
  // wire tia_cs = (address_bus[12:6] == 7'b0_0000_00);  // TIA registers: 0000h - 003Fh 
  // wire pia_cs = (address_bus[12:5] == 8'b0_0010_100); // PIA registers: 0280h - 029Fh
  wire tia_cs = (address_bus[12] == 0 && address_bus[7] == 0);  // TIA registers: 0000h - 003Fh 
  wire pia_cs = (address_bus[12] == 0 && address_bus[7] == 1 && address_bus[9] == 1);  // TIA registers: 0000h - 003Fh 
  wire ram_cs = (address_bus[12] == 0 && address_bus[7] == 1 && address_bus[9] == 0);   // RAM: 0080-00FF
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
    if (cpu_enable) begin
      if (write_enable && ram_cs) ram[address_bus[6:0]] <= data_out;
      if (ram_cs) data_in <= ram[address_bus[ 6:0]];
      if (rom_cs) data_in <= rom[address_bus[11:0]];
    end
    if (tia_cs) data_in <= tia_data_out;
    if (pia_cs) data_in <= pia_data_out;
  end
endmodule
