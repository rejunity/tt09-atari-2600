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

  wire [4:0] audio_wip = audio_l + audio_r;

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = {tia_vblank, tia_vsync, audio_wip[4-:2], 4'b0};
  assign uio_oe  = 8'b1111_0000;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, uio_in[7:4]};

  vga_hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(vga_xpos),
    .vpos(vga_ypos)
  );

  // Inputs
  // TODO: fix a weird mapping in TIA.v / PIA.v
  // localparam UP = 3, RIGHT = 6, LEFT = 5, DOWN = 4, SELECT = 2, RESET = 0, FIRE = 1;
  wire [6:0] buttons = {~ui_in[6:1], ui_in[0]};
  wire [3:0] switches = ~uio_in[3:0];

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


  // Atari 2600 NTSC is mapped to 640x480@60Hz VGA:
  //  NTSC: 228 clocks (160 visible pixels) x 262 scanlines (progressive)
  //   VGA: 800 clocks (640 visible pixels) x 525 scanlines
  //  NTSC scanline is mapped to 2 VGA scanlines
  //  Each Atari 2600 pixel is mapped to 4x2 VGA pixels

  // We need to skip the last 2 pixels of each 800 VGA scanline
  // to match TIA slightly shorter scanline 228*7=1596 clocks to pair of VGA 800*2=1600 scanlines
  wire system_enable = vga_xpos < 798 && ~wait_for_vga_vsync;

  // reg [4:0] clk_counter;
  // always @(posedge clk) begin
  //   if (~rst_n || clk_counter == 20) // 21 cycles clock counter dividing VGA clock
  //                                    // VGA / (7*3) = 1.19 MHz (CPU/PIA)
  //                                    // VGA /   7   = 3.57 MHz (NTSC/TIA)
  //       clk_counter <= 0;
  //     else
  //       clk_counter <= clk_counter + 1'b1;
  // end

  // reg [4:0] clk_counter;
  // always @(posedge clk) begin
  //   if (~rst_n)
  //     clk_counter <= 0;
  //   else if (system_enable) begin
  //     if (clk_counter >= 20)  // 21 cycles clock counter dividing VGA clock
  //                             // VGA / (7*3) = 1.19 MHz (CPU/PIA)
  //                             // VGA /   7   = 3.57 MHz (NTSC/TIA)
  //       clk_counter <= 0;
  //     else
  //       clk_counter <= clk_counter + 1'b1;
  //   end
  // end
  // wire tia_enable = system_enable && ((clk_counter ==  0 || clk_counter == 7 || clk_counter == 15) ||
  //                                     (stall_cpu && tia_vsync));
  // wire cpu_enable = system_enable &&  clk_counter ==  0;
  // wire pia_enable = system_enable && ((clk_counter == 16) ||
  //                                     (clk_counter < 7 && stall_cpu && tia_vsync));

  // wire turbo = stall_cpu;
  // reg [3:0] clk_counter7;
  // reg [1:0] clk_counter3;
  // always @(posedge clk) begin
  //   if (~rst_n) begin
  //     clk_counter7 <= 0;
  //     clk_counter3 <= 0;
  //   end else if (system_enable) begin
  //     if (clk_counter7 == 6 || turbo) begin
  //       if (clk_counter3 == 2)
  //         clk_counter3 <= 0;
  //       else
  //         clk_counter3 <= clk_counter3 + 1'b1;
  //       clk_counter7 <= 0;
  //     end else
  //       clk_counter7 <= clk_counter7 + 1'b1;
  // end


  // wire clk_step = turbo ? 7 : 1;
  reg  turbo;
  reg  [8:0] clk_counter;
  wire [8:0] clk_counter_next = clk_counter + (turbo ? 7 : 1);
  always @(posedge clk) begin
    if (~rst_n) begin
      clk_counter <= 0;
      turbo <= 0;
    end else if (system_enable) begin
      // 21 cycles clock counter dividing VGA clock
      // VGA / (7*3) = 1.19 MHz (CPU/PIA)
      // VGA /   7   = 3.57 MHz (NTSC/TIA)
      
      if (clk_counter_next == 21) begin
        clk_counter <= 0;
        // turbo <= stall_cpu; // tia_vblank makes sprites jump in RiverRaid
        // turbo <= stall_cpu && tia_vblank; // tia_vblank makes sprites jump in RiverRaid
        turbo <= stall_cpu && tia_vsync;
        // turbo <= 0;
      end else
        clk_counter <= clk_counter_next;
    end
  end

  // Strobes (enable) signals emulate the 3 clocks of the Atari 2600 system:
  // tia_enable - XTAL 3.57 MHz system master clock / NTSC clock
  // cpu_enable - PHI0 generated by TIA and driving CPU clock
  // pia_enable - PHI2 generated by CPU and driving PIA clock
  wire tia_enable = system_enable && (clk_counter == 0 || clk_counter == 7 || clk_counter == 14);
  wire cpu_enable = system_enable &&  clk_counter == 1; // TIA & CPU must tick on the same cycle, otherwise player sprites jitter
  wire pia_enable = system_enable &&  clk_counter == 7;
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
 

  reg [6:0] scanline [255:0];
  wire [7:0] tia_xpos;
  always @(posedge clk) begin
    if (tia_xpos < 160)
      scanline[tia_xpos] <= tia_color_out;
  end

  wire [8:0] tia_ypos;
  // reg [15:0] tia_vsync_counter;
  // reg [15:0] tia_screen_counter;  
  // always @(posedge clk) begin
  //   if (~rst_n) begin
  //     tia_vsync_counter <= 0;
  //     tia_screen_counter <= 0;
    
  //   end else begin
  //     if (tia_vsync)
  //       tia_vsync_counter <= tia_vsync_counter + tia_enable; // VGA clocks 0F6C .. 1125 .. 113A
  //                                                           // TIA scr  clocks 2053  E7CA  E7CA
  //                                                           // TIA sync clocks 233    274   272
  //                                                           // TIA x            AE     AF    AE
  //     else 
  //       tia_vsync_counter <= 0;

  //     if (tia_vsync)
  //       tia_screen_counter <= 0;
  //     else
  //       tia_screen_counter <= tia_screen_counter + tia_enable; // TIA clocks E7CA
  //   end

  //   // sync started x=3,y=2 | x=04, y=0 <--> x=AF,y=2
  //   // sync started x=3,y=2 | x=04, y=0 <--> x=AE,y=2
  // end

  wire wait_for_vga_vsync = tia_ypos == 4 && vga_ypos < (480 + 10 + 2);

  //(tia_xpos == 0 && vga_xpos == 0) &&
  // wire = stall_cpu & tia_vsync;


  //   if (vsync || ~rst_n)
  //     tia_vsync_counter <= 0;
  //   else begin
  //     if (tia_vsync && tia_vsync_counter == 0)
  //       tia_vsync_counter <= 6 * 800;

  //     if (tia_vsync_counter > 0)
  //       tia_vsync_counter <= tia_vsync_counter - 1'b1;
  //   end
  // end

  // 0xE3 * 0x104 = (227+1) (260+1)
  // 228 * 262 = 59736        | 59338 398
  //              * 7 => 418152
  // 

  // wire wait_for_vga_vsync = 
  //   ( tia_ypos * 228 + tia_xpos == (228*3+0) &&
  //     vga_ypos * 800 + vga_xpos <= (480 + 10 + 2) * 800);
  //(tia_ypos * 228 + tia_xpos < V_SYNC_END * 800 + tia_xpos < V_SYNC_END * 800);


  // tia_vsync_counter >= 6*800 && !vsync;// = tia_ypos == 2 && vga_ypos < 10'h1EA;

  // wire wait_for_vga_vsync = tia_vsync_counter > 0;// tia_vsync_counter >= 6*800 && !vsync;// = tia_ypos == 2 && vga_ypos < 10'h1EA;
  // reg wait_for_vga_vsync;

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

  wire [6:0] hue_luma = vga_xpos[9:2] < 160 ? scanline[vga_xpos[9:2]] : 0;
  wire [3:0] hue = hue_luma[6:3];
  wire [3:0] luma = {hue_luma[2:0], 1'b0};
  wire [23:0] rgb_24bpp;
  palette palette_24bpp (
      .hue(hue),
      .lum(luma),
      .rgb_24bpp(rgb_24bpp)
  );

  assign {R, G, B} = (!video_active || tia_vblank) ? 6'b00_00_00:
                                      {rgb_24bpp[23], rgb_24bpp[23-1],
                                       rgb_24bpp[15], rgb_24bpp[15-1],
                                       rgb_24bpp[ 7], rgb_24bpp[ 7-1]};

  // -------------------------------------------------------------------------
  wire [15:0] address_bus_w;
  reg  [15:0] address_bus_r;
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
    .RDY(cpu_enable && !stall_cpu) // & !wait_for_vga_vsync));
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
  wire       tia_vblank;
  wire       tia_vsync;
  reg        tia_wr;

  tia tia (
    .clk_i(clk),//_tia),
    .rst_i(~rst_n),
    .stb_i(tia_cs && cpu_enable),
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
  reg  [7:0] pia_data_out;

  pia pia (
    .clk_i(clk),
    .rst_i(~rst_n),
    .enable_i(pia_enable),
    .stb_i(pia_cs && cpu_enable),
    .we_i(write_enable),
    .adr_i(address_bus[6:0]),
    .dat_i(pia_data_in),
    .dat_o(pia_data_out),
    .buttons(buttons),
    .sw(switches)
    // .diag(pia_diag)
  );

  // All memory is mirrored in steps of 2000h
  // TIA Write Mirrors (Step 40h,100h)
  // TIA Read Mirrors (Step 10h,100h)
  // PIA I/O Mirrors (Step 2h,8h,100h,400h)
  // PIA RAM Mirrors (Step 100h,400h)
  // 0000-002C  TIA Write
  // 0000-000D  TIA Read
  // 0080-00FF  PIA RAM (128 bytes)
  // 0280-0297  PIA Reads & Writes
  // F000-FFFF  Cartridge Memory (4 Kbytes area)

  // Atari 2600 schematics:
  // - TIA select = ~A12 (-> TIA /CS0) & ~A7 (-> TIA /CS3)
  // - PIA select = ~A12 (-> PIA /CS2) &  A7 (-> PIA  CS1) &  A9 ('1' -> PIA RS)
  // - RAM select = ~A12 (-> PIA /CS2) &  A7 (-> PIA  CS1) & ~A9 ('0' -> PIA RS)
  wire rom_cs = (address_bus[12] == 1);
  wire tia_cs = (address_bus[12] == 0 && address_bus[7] == 0);
  wire pia_cs = (address_bus[12] == 0 && address_bus[7] == 1 && address_bus[9] == 1);
  wire ram_cs = (address_bus[12] == 0 && address_bus[7] == 1 && address_bus[9] == 0);

  reg [7:0] rom_data;
  always @(posedge clk) begin
    // ROM
    rom_data <= rom[address_bus[11:0]]; // makes yosys iCE40 BRAM inference happy
                                        // and allows it to be used as ROM storage

    // CPU writes
    if (cpu_enable && write_enable && ram_cs) ram[address_bus[6:0]] <= data_out;

    // CPU reads
    if (ram_cs) data_in <= ram[address_bus[ 6:0]];
    if (rom_cs) data_in <= rom_data;
    if (tia_cs) data_in <= tia_data_out;
    if (pia_cs) data_in <= pia_data_out;
  end
endmodule
