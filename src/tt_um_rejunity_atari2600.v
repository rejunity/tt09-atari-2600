/*
 * Copyright (c) 2024 Renaldas Zioma
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
// `define QSPI_ROM

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

  wire [4:0] audio = audio_l + audio_r;
  reg [5:0] audio_pwm_accumulator;
  always @(posedge clk) begin
    if (~rst_n)
      audio_pwm_accumulator <= 0;
    else
      audio_pwm_accumulator <= audio_pwm_accumulator[4:0] + audio;
  end
  wire audio_pwm = 0;// @TEMP: audio_pwm_accumulator[5];

  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Audio PMOD + ROM SPI
  // 1 bidirectional pin is unused (tia_vsync for diagostics in Verilator)
  // TODO: output video_active for DVI instead
`ifdef QSPI_ROM
  assign uio_out = {audio_pwm, tia_vsync, spi_select, spi_clk_out, spi_data_out};
  assign uio_oe  = {     1'b1,      1'b1,       1'b1,        1'b1,  spi_data_oe};
`else
  assign uio_out = {audio_pwm, tia_vsync,       1'b0,        1'b0,       3'b000};
  assign uio_oe  = {     1'b1,      1'b1,       1'b1,        1'b1,       3'b111};
`endif
  assign spi_data_in = uio_in[3:0];

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
`ifdef QSPI_ROM
  wire [3:0] switches = 4'b1111;
`else
  wire [3:0] switches = ~uio_in[3:0];  // TODO: pass switches together with input
                                                  // adopt NES controller format
`endif
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
        // turbo <= stall_cpu;
        // turbo <= stall_cpu && tia_vblank; // tia_vblank makes sprites jump in RiverRaid
        // turbo <= stall_cpu && tia_vsync;
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

  // wire wait_for_vga_vsync = tia_ypos == 4 && vga_ypos < (480 + 10 + 2);
  // wire wait_for_vga_vsync = tia_ypos == 4 && vga_ypos > 10;
  // wire wait_for_vga_vsync = tia_ypos > 4 && vga_ypos > tia_ypos * 2;
  wire wait_for_vga_vsync = tia_ypos > 4 && (vga_ypos > tia_ypos * 2) && (vga_xpos > tia_xpos * 4);
  // wire wait_for_vga_vsync = tia_ypos == 260 && vga_ypos < 260*2-1;
  // wire wait_for_vga_vsync = tia_ypos == 40 && vga_ypos > 40*2;
  reg tia_vsync_last;
  always @(posedge clk)
    tia_vsync_last <= tia_vsync;


  reg [2:0] frame_counter;
  always @(posedge clk)
    if (~rst_n)
      frame_counter <= 0;
    else if (tia_vsync_last != tia_vsync && tia_vsync)
      frame_counter <={((frame_counter[2:1] == 0) ? 2'd1 : 
                        (frame_counter[2:1] == 1) ? 2'd3 : 
                        (frame_counter[2:1] == 2) ? 2'd0 :
                                                    2'd2),
                        ~frame_counter[0]};

      // frame_counter <= frame_counter + 3;
      // frame_counter <= frame_counter ^ 3'b101;
      // frame_counter <= (|frame_counter) ? {frame_counter[6:0],  frame_counter[3] ^ x[1] } : 1;

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
  // @TEMP:
  // assign {R, G, B} = (!video_active || tia_vblank) ? 6'b00_00_00:
  //                                                   {r_pwm_accum_[9-:2],
  //                                                    g_pwm_accum_[9-:2],
  //                                                    b_pwm_accum_[9-:2]};
  reg [9:0] r_pwm_accum;
  reg [9:0] g_pwm_accum;
  reg [9:0] b_pwm_accum;
  reg [9:0] r_pwm_accumA;
  reg [9:0] g_pwm_accumA;
  reg [9:0] b_pwm_accumA;
  reg [9:0] r_pwm_accumB;
  reg [9:0] g_pwm_accumB;
  reg [9:0] b_pwm_accumB;

  wire [9:0] r_pwm_accum_ = (vga_ypos[0] == frame_counter[0]) ? r_pwm_accumA: r_pwm_accumB;
  wire [9:0] g_pwm_accum_ = (vga_ypos[0] == frame_counter[0]) ? g_pwm_accumA: g_pwm_accumB;
  wire [9:0] b_pwm_accum_ = (vga_ypos[0] == frame_counter[0]) ? b_pwm_accumA: b_pwm_accumB;
  
  // wire [3:0] src_mul = 3;//(vga_ypos[0] == 1 && vga_xpos[1:0] == 0) ? 3 : 3;
  wire [3:0] src_mul = (vga_ypos[0] == 1 && vga_xpos[1:0] == 0) ? 4 : 3;
  wire [1:0] accum_div = (vga_xpos[1:0] == 0) ? 1 : 0;
  // wire [9:0] r_src = (attack ? ((rgb_24bpp[23:16] * 12) & 10'h1ff) : 0) + (rgb_24bpp[23:16] * 3);
  // wire [9:0] g_src = (attack ? ((rgb_24bpp[15: 8] * 12) & 10'h1ff) : 0) + (rgb_24bpp[15: 8] * 3);
  // wire [9:0] b_src = (attack ? ((rgb_24bpp[ 7: 0] * 12) & 10'h1ff) : 0) + (rgb_24bpp[ 7: 0] * 3);
  // wire [1:0] accum_div = (vga_xpos[1:0] == 0) ? 1 : 0;
  wire fade = (vga_xpos[1:0] == 0);
  // wire fade = (vga_xpos[1:0] == 2);
  // wire attack = (vga_ypos[0] == 0) || ((vga_ypos[0] == 1) && (vga_xpos[1:0] == 0));
  // wire attack = (vga_ypos[0] == 1) && (vga_xpos[1:0] == 0);
  // wire attack = (vga_ypos[0] == 1) ^^ (vga_xpos[1:0] == 0);
  // wire attack = (vga_ypos[0] == frame_counter[0]) && (vga_xpos[1:0] == 0);
  // wire r_attack = (vga_ypos[0] == frame_counter[0]) && (vga_xpos[1:0] == 2);
  // wire g_attack = (vga_ypos[0] == frame_counter[0]) && (vga_xpos[1:0] == 0);
  // wire b_attack = (vga_ypos[0] == frame_counter[0]) && (vga_xpos[1:0] == 1);
  // wire r_attack = (vga_ypos[0] == 1) && (vga_xpos == 2);
  // wire g_attack = (vga_ypos[0] == 1) && (vga_xpos == 0);
  // wire b_attack = (vga_ypos[0] == 1) && (vga_xpos == 1);
  // wire r_attack = (vga_ypos[0] == 1) && (vga_xpos[1:0] == 3);
  // wire g_attack = (vga_ypos[0] == 1) && (vga_xpos[1:0] == 3);
  // wire b_attack = (vga_ypos[0] == 1) && (vga_xpos[1:0] == 3);
  wire r_attack = (vga_ypos[0] == 1) && (vga_xpos[1:0] == frame_counter[1:0]);
  wire g_attack = (vga_ypos[0] == 1) && (vga_xpos[1:0] == frame_counter[1:0]);
  wire b_attack = (vga_ypos[0] == 1) && (vga_xpos[1:0] == frame_counter[1:0]);
  // wire [9:0] r_src = rgb_24bpp[23:16] * (r_attack ? 4 : 3);
  // wire [9:0] g_src = rgb_24bpp[15: 8] * (g_attack ? 4 : 3);
  // wire [9:0] b_src = rgb_24bpp[ 7: 0] * (b_attack ? 4 : 3);
  wire [9:0] r_src = (r_attack ? ((rgb_24bpp[23:16] * 12) & 10'h1ff) : 0) + (rgb_24bpp[23:16] * 3);
  wire [9:0] g_src = (g_attack ? ((rgb_24bpp[15: 8] * 12) & 10'h1ff) : 0) + (rgb_24bpp[15: 8] * 3);
  wire [9:0] b_src = (b_attack ? ((rgb_24bpp[ 7: 0] * 12) & 10'h1ff) : 0) + (rgb_24bpp[ 7: 0] * 3);
  // wire [9:0] r_src = r_attack ? 0 : (rgb_24bpp[23:16] * 3);
  // wire [9:0] g_src = g_attack ? 0 : (rgb_24bpp[15: 8] * 3);
  // wire [9:0] b_src = b_attack ? 0 : (rgb_24bpp[ 7: 0] * 3);
  // // wire [7:0] r_accum = fade ? 0 : r_pwm_accum[7:0];
  // wire [7:0] g_accum = fade ? 0 : g_pwm_accum[7:0];
  // wire [7:0] b_accum = fade ? 0 : b_pwm_accum[7:0];
  // wire [7:0] r_accum = fade ? 0 : r_pwm_accum[7:0];
  // wire [7:0] g_accum = fade ? 0 : g_pwm_accum[7:0];
  // wire [7:0] b_accum = fade ? 0 : b_pwm_accum[7:0];

  // wire [7:0] r_accum = r_pwm_accum[7:0]*(vga_xpos[1:0] == 2?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]*(vga_xpos[1:0] == 0?0:1);
  // wire [7:0] b_accum = b_pwm_accum[7:0]*(vga_xpos[1:0] == 1?0:1);
  wire [7:0] r_accum = r_pwm_accum[7:0]*(vga_xpos[1:0] == frame_counter[1:0]);
  wire [7:0] g_accum = g_pwm_accum[7:0]*(vga_xpos[1:0] == frame_counter[1:0]);
  wire [7:0] b_accum = b_pwm_accum[7:0]*(vga_xpos[1:0] == frame_counter[1:0]);

  // wire [7:0] r_accum = r_pwm_accum[7:0] >> 1;
  // wire [7:0] g_accum = g_pwm_accum[7:0] >> 1;
  // wire [7:0] b_accum = b_pwm_accum[7:0] >> 1;

  wire [1:0] __a = 2'd0+frame_counter[0];
  wire [1:0] __b = 2'd1+frame_counter[0];
  wire [1:0] __c = 2'd2+frame_counter[0];
  wire [1:0] __d = 2'd3+frame_counter[0];

  // wire [7:0] r_accum = r_pwm_accum[7:0]*(vga_xpos[1:0] == __c?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]*(vga_xpos[1:0] ==   0?0:1);
  // wire [7:0] b_accum = b_pwm_accum[7:0]*(vga_xpos[1:0] == __b?0:1);

  // wire [7:0] r_accum = r_pwm_accum[7:0]*((vga_xpos[1:0] == 0)?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]*((vga_xpos[1:0] == (2'b1+frame_counter[0]))?0:1);
  // wire [7:0] b_accum = b_pwm_accum[7:0]*((vga_xpos[1:0] == 0)?0:1);

  // wire [7:0] r_accum = r_pwm_accum[7:0]*(vga_xpos[1:0] == 0?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]*(vga_xpos[1:0] == (vga_ypos[0]+1'b1)?0:1);
  // wire [7:0] b_accum = b_pwm_accum[7:0]*(vga_xpos[1:0] == 3?0:1);

  // wire [7:0] r_accum = r_pwm_accum[7:0]*(vga_xpos[1:0] == (2'b11-vga_ypos[1:0])?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]*(vga_xpos[1:0] == (      vga_ypos[1:0])?0:1);
  // wire [7:0] b_accum = b_pwm_accum[7:0]*(vga_xpos[1:0] == ({vga_ypos[0],vga_ypos[1]})?0:1);

  // wire [7:0] r_accum = r_pwm_accum[7:0]*(vga_xpos[1:0] == 0?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]*(vga_xpos[  0] == 1?(!vga_ypos[0]):( vga_ypos[0]));
  // wire [7:0] b_accum = b_pwm_accum[7:0]*(vga_xpos[1:0] == 3?0:1);

  // wire [7:0] r_accum = r_pwm_accum[7:0]*(vga_xpos[1:0] == (vga_ypos[0]?0:1)?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]*(vga_xpos[1:0] == (vga_ypos[0]?2:3)?0:1);
  // wire [7:0] b_accum = b_pwm_accum[7:0]*(vga_xpos[1:0] == (vga_ypos[0]?3:0)?0:1);

  // wire [7:0] r_accum = r_pwm_accum[7:0]*(vga_xpos[1:0] == 1?(!vga_ypos[0]):( vga_ypos[0]));
  // wire [7:0] g_accum = g_pwm_accum[7:0]*(vga_xpos[1:0] == 0?(!vga_ypos[0]):( vga_ypos[0]));
  // wire [7:0] b_accum = b_pwm_accum[7:0]*(vga_xpos[1:0] == 3?(!vga_ypos[0]):( vga_ypos[0]));

  // wire [7:0] r_accum = r_pwm_accum[7:0]>>(vga_xpos[0] == 0?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]>>(vga_xpos[0] == 1?0:1);
  // wire [7:0] b_accum = b_pwm_accum[7:0]>>(vga_xpos[0] == 1?0:1);
  // wire [7:0] r_accum = r_pwm_accum[7:0]>>(vga_xpos[1:0] == 0?0:1);
  // wire [7:0] g_accum = g_pwm_accum[7:0]>>(vga_xpos[1:0] == 1?0:1);
  // wire [7:0] b_accum = b_pwm_accum[7:0]>>(vga_xpos[1:0] == 2?0:1);
  // wire [7:0] r_accum = r_pwm_accum[7:0]>>1;
  // wire [7:0] g_accum = g_pwm_accum[7:0]>>1;
  // wire [7:0] b_accum = b_pwm_accum[7:0]>>1;
  // wire [7:0] r_accum = r_pwm_accum[7:0];
  // wire [7:0] g_accum = g_pwm_accum[7:0];
  // wire [7:0] b_accum = b_pwm_accum[7:0];
  // wire [9:0] r_src = (attack ? ((rgb_24bpp[23:16] * 12) & 10'b00_1111_1111) : 0) + (rgb_24bpp[23:16] * 3);
  // wire [9:0] g_src = (attack ? ((rgb_24bpp[15: 8] * 12) & 10'b00_1111_1111) : 0) + (rgb_24bpp[15: 8] * 3);
  // wire [9:0] b_src = (attack ? ((rgb_24bpp[ 7: 0] * 12) & 10'b00_1111_1111) : 0) + (rgb_24bpp[ 7: 0] * 3);
  // wire [9:0] r_src = attack ? ((rgb_24bpp[23:16] * 12) & 10'hff) : rgb_24bpp[23:16] * 3;
  // wire [9:0] g_src = attack ? ((rgb_24bpp[15: 8] * 12) & 10'hff) : rgb_24bpp[15: 8] * 3;
  // wire [9:0] b_src = attack ? ((rgb_24bpp[ 7: 0] * 12) & 10'hff) : rgb_24bpp[ 7: 0] * 3;
  // wire [9:0] r_src = (rgb_24bpp[23:16] * 3);
  // wire [9:0] g_src = (rgb_24bpp[15: 8] * 3);
  // wire [9:0] b_src = (rgb_24bpp[ 7: 0] * 3);
  always @(posedge clk) begin
    if (vga_xpos == 0) begin
      r_pwm_accum <= 0;
      g_pwm_accum <= 0;
      b_pwm_accum <= 0;
      r_pwm_accumA <= 0;
      g_pwm_accumA <= 0;
      b_pwm_accumA <= 0;
      r_pwm_accumB <= 0;
      g_pwm_accumB <= 0;
      b_pwm_accumB <= 0;
    end else begin
      // r_pwm_accum <= r_pwm_accum[7:0] + rgb_24bpp[23-:8]*3;
      // g_pwm_accum <= g_pwm_accum[7:0] + rgb_24bpp[15-:8]*3;
      // b_pwm_accum <= b_pwm_accum[7:0] + rgb_24bpp[ 7-:8]*3;

      r_pwm_accum <= r_accum + r_src;
      g_pwm_accum <= g_accum + g_src;
      b_pwm_accum <= b_accum + b_src;

      r_pwm_accumA <= (vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((r_pwm_accumA & 10'h0FF)>>1)) + (rgb_24bpp[23:16] * 3);
      g_pwm_accumA <= (vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((g_pwm_accumA & 10'h0FF)>>1)) + (rgb_24bpp[15: 8] * 3);
      b_pwm_accumA <= (vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((b_pwm_accumA & 10'h0FF)>>1)) + (rgb_24bpp[ 7: 0] * 3);

      r_pwm_accumB <= (vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((r_pwm_accumB & 10'h0FF)>>1)) + (rgb_24bpp[23:16] * 3) + ((vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((r_pwm_accumA & 10'h0FF)>>1)) + (rgb_24bpp[23:16] * 3) & 10'h0FF);
      g_pwm_accumB <= (vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((g_pwm_accumB & 10'h0FF)>>1)) + (rgb_24bpp[15: 8] * 3) + ((vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((g_pwm_accumA & 10'h0FF)>>1)) + (rgb_24bpp[15: 8] * 3) & 10'h0FF);
      b_pwm_accumB <= (vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((b_pwm_accumB & 10'h0FF)>>1)) + (rgb_24bpp[ 7: 0] * 3) + ((vga_xpos[1:0]==(frame_counter[2:1]+0)?0:((b_pwm_accumA & 10'h0FF)>>1)) + (rgb_24bpp[ 7: 0] * 3) & 10'h0FF);

      // r_pwm_accum <= ((vga_xpos[1:0] != 0) ? r_pwm_accum[7:0] : 0) + rgb_24bpp[23:16] * src_mul;
      // g_pwm_accum <= ((vga_xpos[1:0] != 0) ? g_pwm_accum[7:0] : 0) + rgb_24bpp[15: 8] * src_mul;
      // b_pwm_accum <= ((vga_xpos[1:0] != 0) ? b_pwm_accum[7:0] : 0) + rgb_24bpp[ 7: 0] * src_mul;
      // r_pwm_accum <= r_pwm_accum[7:0] - ((vga_xpos[1:0] == 0) ? r_pwm_accum >> 1 : 0) + rgb_24bpp[23:16] * src_mul;
      // g_pwm_accum <= g_pwm_accum[7:0] - ((vga_xpos[1:0] == 0) ? g_pwm_accum >> 1 : 0) + rgb_24bpp[15: 8] * src_mul;
      // b_pwm_accum <= b_pwm_accum[7:0] - ((vga_xpos[1:0] == 0) ? b_pwm_accum >> 1 : 0) + rgb_24bpp[ 7: 0] * src_mul;

      // r_pwm_accum <= (r_pwm_accum[7:0] >> accum_div) + rgb_24bpp[23:16] * src_mul;
      // g_pwm_accum <= (g_pwm_accum[7:0] >> accum_div) + rgb_24bpp[15: 8] * src_mul;
      // b_pwm_accum <= (b_pwm_accum[7:0] >> accum_div) + rgb_24bpp[ 7: 0] * src_mul;
      // r_pwm_accum <= (r_pwm_accum[7:0] >> accum_div) + r_src;
      // g_pwm_accum <= (g_pwm_accum[7:0] >> accum_div) + g_src;
      // b_pwm_accum <= (b_pwm_accum[7:0] >> accum_div) + b_src;
      // r_pwm_accum <= (r_pwm_accum[7:0]>>1) + r_src;
      // g_pwm_accum <= (g_pwm_accum[7:0]>>1) + g_src;
      // b_pwm_accum <= (b_pwm_accum[7:0]>>1) + b_src;
      // r_pwm_accum <= ((vga_xpos[1:0] != 0) ? r_pwm_accum[7:0] : 0) + r_src;
      // g_pwm_accum <= ((vga_xpos[1:0] != 0) ? g_pwm_accum[7:0] : 0) + g_src;
      // b_pwm_accum <= ((vga_xpos[1:0] != 0) ? b_pwm_accum[7:0] : 0) + b_src;
      // r_pwm_accum <= r_pwm_accum[7:0] - ((vga_xpos[1:0] == 0) ? r_pwm_accum >> 1 : 0) + r_src;
      // g_pwm_accum <= g_pwm_accum[7:0] - ((vga_xpos[1:0] == 0) ? g_pwm_accum >> 1 : 0) + g_src;
      // b_pwm_accum <= b_pwm_accum[7:0] - ((vga_xpos[1:0] == 0) ? b_pwm_accum >> 1 : 0) + b_src;
    end
  end


  // -------------------------------------------------------------------------
  wire [15:0] address_bus_w;
  reg  [15:0] address_bus_r;
  wire [15:0] address_bus = cpu_enable ? address_bus_w : address_bus_r;
  reg  [7:0] data_in; // register - because that's how Arlet Otten's 6502 impl wants it
  wire [7:0] data_out;
  wire write_enable;
  reg stall_cpu;

  always @(posedge clk)
    if (~rst_n)
      address_bus_r <= 0;
    else
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
  reg [7:0] ram_data;
  always @(posedge clk) begin
    // ROM
  `ifdef QSPI_ROM
    if (spi_data_ready) rom_data <= spi_data_read;
  `else
    rom_data <= rom[address_bus[11:0]]; // makes yosys iCE40 BRAM inference happy
                                        // and allows it to be used as ROM storage
  `endif

    ram_data <= ram[address_bus[ 6:0]]; // makes yosys iCE40 BRAM inference happy

    // CPU writes
    if (cpu_enable && write_enable && ram_cs) ram[address_bus[6:0]] <= data_out;

    // CPU reads
    if (ram_cs) data_in <= ram_data; // ram[address_bus[ 6:0]];
    if (rom_cs) data_in <= rom_data;
    if (tia_cs) data_in <= tia_data_out;
    if (pia_cs) data_in <= pia_data_out;
  end

  // @TODO: is it possible to use 20 bit address instead of 24?
  wire [23:0] spi_address = address_bus[11:0] + 24'h10_00_00; // iceprog -o1024k
  wire        spi_start_read = cpu_enable && !stall_cpu && rom_cs;

  wire  [3:0] spi_data_in;
  reg   [3:0] spi_data_out;
  wire  [3:0] spi_data_oe;
  wire        spi_select;
  reg         spi_clk_out;
  wire  [7:0] spi_data_read;
  reg         spi_data_ready;
  wire        spi_busy;
  `ifdef QSPI_ROM
  qspi_flash_controller #(.DATA_WIDTH_BYTES(1), .ADDR_BITS(24)) flash_rom (
    .clk(clk),
    .rstn(rst_n),

    // External SPI interface
    .spi_data_in(spi_data_in),
    .spi_data_out(spi_data_out),
    .spi_data_oe(spi_data_oe),
    .spi_select(spi_select),
    .spi_clk_out(spi_clk_out),

    // Internal interface for reading/writing data
    .addr_in(spi_address),
    .start_read(spi_start_read),
    .stall_read(1'b0),
    .stop_read(1'b0), // TODO: does stopping read after 1 byte makes subsequent command faster?

    .data_out(spi_data_read),
    .data_ready(spi_data_ready),
    .busy(spi_busy)
  );
  `endif

endmodule
