/*
 * Copyright (c) 2024 Renaldas Zioma
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none
// `define VGA_50MHz
// `define VGA_RESYNC_TO_TIA
// `define VGA_REGISTERED_OUTPUTS
`define VGA_PWM_DITHERING
// `define VALIDATE_QSPI_ROM_AGAINST_INTERNAL_ROM
`define QSPI_ROM

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
  
  // Configuration captured during RESET phase
  reg [7:0] rom_config;

  always @(posedge clk)
    if (~rst_n)
      rom_config <= ui_in;

  // -------------------------------------------------------------------------

  wire [11:0] address_bus;
  wire        rom_cycle;
  wire        valid_rom_address_on_bus; // WAS: (cpu_enable && !stall_cpu && rom_cs)


  wire [6:0] tia_video;
  wire [4:0] tia_audio;

  wire [7:0] tia_xpos;
  wire [8:0] tia_ypos;
  wire       tia_vsync;
  wire       tia_vblank;

  wire system_enable = ~wait_for_vga_sync && ~wait_for_memory;

  atari2600 atari2600 (
    .clk(clk),
    .reset(~rst_n),
    .system_enable(system_enable),
    // inputs
    .input_switches(switches[4:1]),
    .input_joystick_0(joystick_0),
    .input_joystick_1(joystick_1),
    .input_paddle_0(8'd200),
    .input_paddle_1(8'd200),
    .input_paddle_2(8'd200),
    .input_paddle_3(8'd200),
    // cartridge ROM
    .rom_read(valid_rom_address_on_bus),
    .rom_address(address_bus),
    .rom_data(rom_data),
    .rom_cycle(rom_cycle),
    // video & audio outputs
    .video(tia_video),
    .xpos(tia_xpos),
    .ypos(tia_ypos),
    .vsync(tia_vsync),
    .vblank(tia_vblank),
    .audio(tia_audio)
  );

  // -------------------------------------------------------------------------

  // video & audio signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire audio_pwm;

  // TinyVGA PMOD
  // https://github.com/mole99/tiny-vga
`ifdef VGA_REGISTERED_OUTPUTS
  reg [7:0] UO_OUT;
  always @(posedge clk)
    UO_OUT <= {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
  assign uo_out = UO_OUT;
`else
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
`endif

  // ROM QSPI + Audio PMODs
  // QSPI PMod: https://github.com/mole99/qspi-pmod
  //  - PMOD1 uio[0]  CS0 Flash ROM
  //  - PMOD2 uio[1]  SD0/MOSI
  //  - PMOD3 uio[2]  SD1/MISO
  //  - PMOD4 uio[3]  SCK
  //  - PMOD5 uio[4]  SD2
  //  - PMOD6 uio[5]  SD3
  //  - PMOD7 uio[6]  CS1 (unused)
  //  - PMOD8 uio[7]  CS2 (audio)
  // Audio PMOD: https://github.com/MichaelBell/tt-audio-pmod
  //  - PMOD8 uio[7]  PWM Audio
  // 1 bidirectional pin is unused (tia_vsync for diagostics in Verilator)
  // @TODO: output video_active for DVI
`ifdef QSPI_ROM
  `ifdef SIM
  wire cs1_tiavs = tia_vsync;
  `else 
  wire cs1_tiavs = 1'b1;
  `endif
  assign uio_out = {audio_pwm, cs1_tiavs, spi_data_out[3:2], spi_clk_out, spi_data_out[1:0], spi_select};
  assign uio_oe  = {     1'b1,      1'b1,  spi_data_oe[3:2],        1'b1,  spi_data_oe[1:0],       1'b1};
  assign spi_data_in = {uio_in[5:4], uio_in[2:1]};
`else
  assign uio_out = {audio_pwm, tia_vsync,       6'b000000};
  assign uio_oe  = {     1'b1,      1'b1,       6'b000000};
`endif

  // Inputs
  // 
  // Atari joystick port
  //     1 2 3 4 5
  //      6 7 8 9
  //  1 Up, 2 Down, 3 Left, 4 Right, 5 Paddle B
  //  6 Fire,                        9 Paddle A
  //  (7 +5V), (8 ground)

  // Define similar layout for PMOD
  //  0 Up, 1 Down, 2 Left, 3 Right
  //  4 Fire, 5 Joystick 1/2, 6 Switches, 7 Reset

  // TODO: fix a weird mapping in TIA.v / PIA.v
  // localparam UP = 3, RIGHT = 6, LEFT = 5, DOWN = 4, SELECT = 2, RESET = 0, FIRE = 1;
  //wire [6:0] buttons = {~ui_in[6:1], ui_in[0]};
  reg [6:0] joystick_0;
  reg [6:0] joystick_1;
  reg [4:0] switches;
  wire [6:0] joypmod = {~ui_in[3], ~ui_in[2], ~ui_in[1], ~ui_in[0], switches[0] /* select */, ~ui_in[4], ~ui_in[7]};

  always @(posedge clk) begin
    if (~rst_n) begin
      joystick_0 <= {5'b11111, 1'b0};
      joystick_1 <= {5'b11111, 1'b0};
      switches   <=  5'b11111;
    end else begin
      if (ui_in[6])
        switches <= ~ui_in[4:0];
      if (~ui_in[5])
        joystick_0 <= joypmod;
      else
        joystick_1 <= joypmod;
    end
  end

  // Suppress unused signals warning
  wire _unused_ok = &{ena, uio_in[7:4]};
  // -------------------------------------------------------------------------

  wire video_active;
  wire [9:0] vga_xpos;
  wire [9:0] vga_ypos;

`ifdef VGA_50MHz
  vga_640x480_50MHz_hvsync_generator hvsync_gen(
`else
  vga_640x480_25MHz_hvsync_generator hvsync_gen(
`endif
    .clk(clk),
`ifdef VGA_RESYNC_TO_TIA
    .reset(~rst_n || tia_vsync),
`else
    .reset(~rst_n),
`endif
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(vga_xpos),
    .vpos(vga_ypos)
  );

  // Atari 2600 Video Color Clock: 3.579545 MHz (NTSC), 3.546894 MHz (PAL)
  // Atari      CPU Machine Clock: 1.193182 MHz (NTSC), 1.182298 MHz (PAL)
  // The CPU Clock is derived from Video clock divided by three.
  // One color clock = 1 pixel. One machine clock = 3 pixels.

  // Atari NTSC graphics mode is mapped to 640x480@60Hz VGA:
  //  NTSC: 228 clocks (160 visible pixels) x 262 scanlines (progressive)
  //   VGA: 800 clocks (640 visible pixels) x 525 scanlines

  // Atari pixel clock   ~1:7  VGA clock
  // Atari CPU   clock   ~1:21 VGA clock

  //  NTSC scanline is mapped to 2 VGA scanlines
  //  Each Atari pixel is mapped to 4x2 VGA pixels
  
  wire wait_for_vga_sync = tia_ypos > 36 && (vga_ypos < tia_ypos * 2);

  reg [6:0] scanline [255:0];
  always @(posedge clk) begin
    if (tia_xpos < 160)
      scanline[tia_xpos] <= tia_video;  // scanline WRITE
  end

  reg tia_vsync_last; always @(posedge clk) tia_vsync_last <= tia_vsync;
  wire tia_vsync_posedge = (tia_vsync_last != tia_vsync) && tia_vsync;

  reg [2:0] frame_counter;
  always @(posedge clk)
    if (~rst_n)
      frame_counter <= 0;
    else if (tia_vsync_posedge)
      frame_counter <={((frame_counter[2:1] == 0) ? 2'd1 : // defines horizontal dithering pattern
                        (frame_counter[2:1] == 1) ? 2'd3 : //             --- // --- 
                        (frame_counter[2:1] == 2) ? 2'd0 : //             --- // --- 
                                                    2'd2), //             --- // --- 
                        ~frame_counter[0]};
  wire onset_scanline = (vga_ypos[  0] == frame_counter[  0]); // each Atari pixel maps to 4x2 VGA pixels, 2 scanlines
  wire onset_pixel    = (vga_xpos[1:0] == frame_counter[2:1]); //               --- // ---                 4 pixels

  wire [6:0] hue_luma = vga_xpos[9:2] < 160 ? scanline[vga_xpos[9:2]] : 0; // scanline READ
  wire [23:0] rgb_24bpp;
  palette palette_24bpp (
      .hue( hue_luma[6:3]),
      .lum({hue_luma[2:0], 1'b0}),
      .rgb_24bpp(rgb_24bpp)
  );
  wire [7:0] r_8bit = rgb_24bpp[23:16];
  wire [7:0] g_8bit = rgb_24bpp[15: 8];
  wire [7:0] b_8bit = rgb_24bpp[ 7: 0];

  // PWM based dithering, each scanline has a separate set of R, G, B accumulators
  reg [9:0] r_pwm_odd,  g_pwm_odd,  b_pwm_odd;  // 1st scanline
  reg [9:0] r_pwm_even, g_pwm_even, b_pwm_even; // 2nd scanline

  always @(posedge clk) begin
    if (vga_xpos == 0) begin
      r_pwm_odd  <= 0; g_pwm_odd  <= 0; b_pwm_odd  <= 0;
      r_pwm_even <= 0; g_pwm_even <= 0; b_pwm_even <= 0;
    end else begin

      // carry over dithering error horizonatally
      r_pwm_odd <=  (onset_pixel?0:((r_pwm_odd  & 10'h0FF)>>1)) + (r_8bit * 3);
      g_pwm_odd <=  (onset_pixel?0:((g_pwm_odd  & 10'h0FF)>>1)) + (g_8bit * 3);
      b_pwm_odd <=  (onset_pixel?0:((b_pwm_odd  & 10'h0FF)>>1)) + (b_8bit * 3);

      // simulate carry over vertically by keeping accumulators for 2 scanlines
      r_pwm_even <= (onset_pixel?0:((r_pwm_even & 10'h0FF)>>1)) + (r_8bit * 3) + 
                   ((onset_pixel?0:((r_pwm_odd  & 10'h0FF)>>1)) + (r_8bit * 3) & 10'h0FF);
      g_pwm_even <= (onset_pixel?0:((g_pwm_even & 10'h0FF)>>1)) + (g_8bit * 3) +
                   ((onset_pixel?0:((g_pwm_odd  & 10'h0FF)>>1)) + (g_8bit * 3) & 10'h0FF);
      b_pwm_even <= (onset_pixel?0:((b_pwm_even & 10'h0FF)>>1)) + (b_8bit * 3) +
                   ((onset_pixel?0:((b_pwm_odd  & 10'h0FF)>>1)) + (b_8bit * 3) & 10'h0FF);

    end
  end

  wire [9:0] r_pwm = onset_scanline ? r_pwm_odd: r_pwm_even;
  wire [9:0] g_pwm = onset_scanline ? g_pwm_odd: g_pwm_even;
  wire [9:0] b_pwm = onset_scanline ? b_pwm_odd: b_pwm_even;

`ifdef VGA_PWM_DITHERING
  assign {R, G, B} = (!video_active || tia_vblank) ? 6'b00_00_00:
                                                     {r_pwm[9-:2],
                                                      g_pwm[9-:2],
                                                      b_pwm[9-:2]};
`else
  assign {R, G, B} = (!video_active || tia_vblank) ? 6'b00_00_00:
                                                     {r_8bit[7-:2],
                                                      g_8bit[7-:2],
                                                      b_8bit[7-:2]};
`endif

  // -------------------------------------------------------------------------

  // Audio PWM
  reg [5:0] audio_pwm_accumulator;
  always @(posedge clk) begin
    if (~rst_n)
      audio_pwm_accumulator <= 0;
    else
      audio_pwm_accumulator <= audio_pwm_accumulator[4:0] + tia_audio;
  end
  assign audio_pwm = audio_pwm_accumulator[5];

  // -------------------------------------------------------------------------
  reg [7:0] builtin_rom [4095:0];
  initial begin
    $readmemh("../roms/rom_builtin.mem", builtin_rom, 0, 4095);
    // DEBUG: override reset vector
    // rom[12'hFFD] <= 8'hF0; rom[12'hFFC] <= 8'h00;
  end

  wire use_internal_rom = rom_config[4];
  reg  [7:0] internal_rom_data;
  reg  [7:0] external_rom_data;
  reg  [7:0] ram_data;
  reg  [7:0] rom_data;

  reg [11:0] romx_addr;
  wire [7:0] rom0_data;
  wire [7:0] rom1_data;
  wire [7:0] rom2_data;
  wire [7:0] rom3_data;
  reg  [7:0] rom0_data_r;
  reg  [7:0] rom1_data_r;
  reg  [7:0] rom2_data_r;
  reg  [7:0] rom3_data_r;

`ifdef NO_MACRO_ROMS
  always @(*)
   casez ({use_internal_rom, rom_config[3:0]})
     5'b0zzzz: rom_data = external_rom_data;
      default: rom_data = internal_rom_data;
   endcase
`else 
  rom_2600_0 rom0_I (
    .addr (romx_addr),
    .q    (rom0_data)
  );

  rom_2600_1 rom1_I (
    .addr (romx_addr),
    .q    (rom1_data)
  );

  rom_2600_2 rom2_I (
    .addr (romx_addr),
    .q    (rom2_data)
  );

  rom_2600_3 rom3_I (
    .addr (romx_addr),
    .q    (rom3_data)
  );

  always @(posedge clk)
  begin
    romx_addr <= address_bus;
    rom0_data_r <= rom0_data;
    rom1_data_r <= rom1_data;
    rom2_data_r <= rom2_data;
    rom3_data_r <= rom3_data;
  end
  always @(*)
   casez ({use_internal_rom, rom_config[3:0]})
     5'b0zzzz: rom_data = external_rom_data;
     5'b10001: rom_data = rom0_data_r;
     5'b10010: rom_data = rom1_data_r;
     5'b10100: rom_data = rom2_data_r;
     5'b11000: rom_data = rom3_data_r;
      default: rom_data = internal_rom_data;
   endcase
`endif

  always @(posedge clk) begin
  `ifdef VALIDATE_QSPI_ROM_AGAINST_INTERNAL_ROM
    `ifdef SIM
      if (valid_rom_address_on_bus)
        internal_rom_data <= builtin_rom[address_bus[11:0]];
      if (!use_internal_rom && valid_rom_address_on_bus && !wait_for_memory && external_rom_data != internal_rom_data)
        $display("ROM fail: %0H spi: %0H != %0H @ %0H", address_bus[11:0], external_rom_data, internal_rom_data, atari2600.cpu.PC[15:0]);
    `endif
  `else
    internal_rom_data <= builtin_rom[address_bus[11:0]];
  `endif
  end

`ifdef QSPI_ROM
  reg spi_restart;
  wire [23:0] spi_address = {4'b0001, rom_config[7:0], address_bus[11:0]}; // iceprog -o1024k
  // wire [23:0] spi_address = address_bus[11:0] + 24'h10_00_00; // iceprog -o1024k
  wire        need_new_rom_data = valid_rom_address_on_bus      && (rom_data_pending == 0) && !rom_addr_in_cache;
  wire        spi_start_read = !spi_busy && (need_new_rom_data || spi_restart);
  wire        spi_stop_read =   spi_busy && need_new_rom_data;
  // wire        spi_stop_read = spi_data_ready;
  // wire        spi_stall_read = spi_data_ready;
  reg         spi_stall_read;

  wire  [3:0] spi_data_in;
  reg   [3:0] spi_data_out;
  wire  [3:0] spi_data_oe;
  wire        spi_select;
  reg         spi_clk_out;
  // wire  [7:0] spi_data_read;
  wire  [7:0] spi_data_read;
  reg         spi_data_ready;
  reg         spi_data_ready_last;
  wire        spi_busy;
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
    .stall_read(spi_stall_read),
    .stop_read(spi_stop_read),

    // .data_out(spi_data_read),
    .data_out(external_rom_data),
    .data_ready(spi_data_ready),
    .busy(spi_busy)
  );

  reg [7:0] rom_data_pending;
  reg [11:0] rom_last_read_addr;
  reg [11:0] rom_next_addr_in_queue;
  wire rom_addr_in_cache = (rom_last_read_addr == address_bus[11:0] ||
                        rom_next_addr_in_queue == address_bus[11:0]);
  // wire rom_addr_in_cache = (rom_cached_addr == address_bus_r[11:0]) || (rom_cached_addr + 1'b1 == address_bus_r[11:0]);
  always @(posedge clk) begin
    if (~rst_n)         spi_restart <= 0;
    if (~rst_n)         rom_data_pending <= 0;
    if (~rst_n)         rom_last_read_addr <= 0;
    if (~rst_n)         rom_next_addr_in_queue <= 0;
    if (~rst_n)         spi_data_ready_last <= 0;
    if (spi_start_read) rom_last_read_addr <= address_bus[11:0];
    if (spi_start_read) rom_next_addr_in_queue <= address_bus[11:0];
    if (spi_start_read) spi_restart <= 0;
    // if (spi_start_read) spi_stall_read <= 1;
    if (rom_data_pending) spi_stall_read <= 1;
    else if (valid_rom_address_on_bus && address_bus[11:0] == rom_next_addr_in_queue && spi_data_ready) spi_stall_read <= 0;
    if (spi_data_ready && !spi_data_ready_last) begin
      rom_last_read_addr     <= rom_next_addr_in_queue;
      rom_next_addr_in_queue <= rom_next_addr_in_queue + 1'b1;
    end
    // if (spi_stop_read)  rom_cached_addr <= 0;
    if (spi_stop_read)  spi_restart <= 1;
    // if (spi_data_ready) rom_cached_addr <= rom_cached_addr + 1'b1;
    spi_data_ready_last <= spi_data_ready;
    rom_data_pending <= spi_busy && !spi_data_ready;

    // misses in Pitfall and Riverraid
    // 65..70% within ±4 bytes
    //  8..9%  within +4 bytes
  end
  wire        wait_for_memory = rom_cycle && (rom_data_pending > 0);
`else
  wire        wait_for_memory = 0;
`endif

// -------------------------------------------------------------------------
`ifdef SIM
  wire [31:0] vga_pos = (vga_ypos * 800 + vga_xpos);
  wire [31:0] tia_pos = (tia_ypos * 228 + tia_xpos) * 4 * 2;
  wire tia_ahead = tia_pos > vga_pos;
  wire vga_ahead = tia_pos < vga_pos;

  always @(posedge vga_ypos)
    if (vga_ahead && wait_for_vga_sync)
      $display("VGA ahead", vga_ypos, "x", vga_xpos, " vs ", tia_ypos, "x", tia_xpos);
`endif

endmodule
