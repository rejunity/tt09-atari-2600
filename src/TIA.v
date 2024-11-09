/*
 *
 * Atari 2600 TIA module.
 * Original source from: https://github.com/lawrie/ulx3s_atari_2600/blob/main/src/tia.v
 */

`default_nettype none
module tia #(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 6
) (
  input                           clk_i,
  input                           rst_i,
  input                           enable_i,
  input                           cpu_enable_i,

  input                           stb_i,
  input                           we_i,
  input [ADDR_WIDTH-1:0]          adr_i,
  input [DATA_WIDTH-1:0]          dat_i,

  output reg [DATA_WIDTH-1:0]     dat_o,

  // buttons
  input [6:0]                     buttons,
  input [7:0]                     pot,

  input                           pal,

  // audio
  output [3:0]                    audio_left,
  output [3:0]                    audio_right,

  // cpu control
  output reg                      stall_cpu,

  // video
  output reg [6:0]                vid_out,
  output                          vid_vblank,
  output                          vid_vsync,
  output [15:0]                   vid_addr,
  output [7:0]                    vid_xpos,
  output [8:0]                    vid_ypos,
  output reg                      vid_wr,
  output [127:0]                  diag
);
  // Button numbers
    localparam UP = 3, RIGHT = 6, LEFT = 5, DOWN = 4, SELECT = 2, RESET = 0, FIRE = 1;

  // TIA registers
  reg [6:0]        colubk, colup0, colup1, colupf;
  reg              vsync, vblank, enam0, enam1, enabl, vdelbl, vdelp0, vdelp1;
  reg              refp0, refp1, refpf, scorepf, pf_priority;
  reg [7:0]        grp0, grp1, old_grp0, old_grp1;
  reg [7:0]        x_p0, x_p1, x_m0, x_m1, x_bl;
  reg [19:0]       pf;
  reg signed [7:0] hmp0, hmp1, hmm0, hmm1, hmbl;
  reg [14:0]       cx;
  reg              cx_clr;
  reg [3:0]        audc0, audc1, audv0, audv1;
  reg [4:0]        audf0, audf1;
  reg              m0_locked, m1_locked;
  reg [3:0]        ball_w, m0_w, m1_w;
  reg [5:0]        p0_w, p1_w;
  reg [1:0]        p0_scale, p1_scale;
  reg [1:0]        p0_copies, p1_copies;
  reg [6:0]        p0_spacing, p1_spacing;
  reg              latch_ports, dump_ports;

  // Diagnostics
  assign diag = {16'b0, grp0, grp1, pf, 4'b0, x_p0, x_p1, x_m0, x_m1, x_bl, colubk, 1'b0, colup0, 1'b0, colup1, 1'b0, colupf, 1'b0};

  // Video data
  reg [7:0]        xpos;
  reg [8:0]        ypos;

  wire [8:0] depth = pal ? 312 : 262;
  wire [8:0] start = pal ? 36 : 22;
  wire [8:0] hblank_area = pal ? 48 : 38;

  assign vid_addr = (ypos - start) * 160 + xpos;
  assign vid_xpos = xpos;
  assign vid_ypos = ypos;

  assign vid_vblank = vblank;
  assign vid_vsync = vsync;

  // Wishbone-like interface
  wire       valid_cmd = stb_i;
  wire       valid_write_cmd = valid_cmd && we_i;
  wire       valid_read_cmd = valid_cmd && !we_i;

  // Drive the video like a CRT, racing the beam
  wire       pf_bit   = pf[xpos < 80 ? (xpos >> 2) : ((!refpf ? xpos - 80 : 159 - xpos) >> 2)];
  wire       p0_bit   = (xpos >= x_p0 && xpos < x_p0 + p0_w ||
                        (p0_copies > 0 && ((xpos - p0_spacing) >= x_p0 &&
                        (xpos - p0_spacing) < x_p0 + p0_w)) ||
                        (p0_copies > 1 && ((xpos - (p0_spacing << 1)) >= x_p0 &&
                        (xpos - (p0_spacing << 1)) < x_p0 + p0_w))) &&
                         (vdelp0 ? 
			   old_grp0[refp0 ? (xpos - x_p0) >> p0_scale  : 7 - ((xpos - x_p0) >> p0_scale)] :
			   grp0[refp0 ? (xpos - x_p0) >> p0_scale  : 7 - ((xpos - x_p0) >> p0_scale)]);
  wire       p1_bit   = (xpos >= x_p1 && xpos < x_p1 + p1_w ||
                        (p1_copies > 0 && ((xpos - p1_spacing) >= x_p1 &&
                        (xpos - p1_spacing) < x_p1 + p1_w)) ||
                        (p1_copies > 1 && ((xpos - (p1_spacing << 1)) >= x_p1 &&
                        (xpos - (p1_spacing << 1)) < x_p1 + p1_w))) &&
                         (vdelp1 ?
			   old_grp1[refp1 ? (xpos - x_p1) >> p1_scale : 7 - ((xpos - x_p1) >> p1_scale)] :
			   grp1[refp1 ? (xpos - x_p1) >> p1_scale : 7 - ((xpos - x_p1) >> p1_scale)]);
  wire       bl_bit   = enabl && xpos >= x_bl && xpos < x_bl + ball_w;
  wire       m0_bit   = enam0 && xpos >= x_m0 && xpos < x_m0 + m0_w;
  wire       m1_bit   = enam1 && xpos >= x_m1 && xpos < x_m1 + m1_w;
  wire [6:0] pf_color = (scorepf ? (xpos < 160 ? colup0 : colup1) :  colupf);
  // Audio - only frequencies supported, not other waveforms
  wire [15:0] audio_div0 = 38 * (audf0 + 1) *
   (audc0 == 2 ? 15 :
    audc0 == 4 || audc0 == 5 ? 2 :
    audc0 == 6 || audc0 == 10 ? 31 :
    audc0 == 12 || audc0 == 13 || audc0 == 15 ? 6 :
    audc0 == 14 ? 93 : 1) ;

  wire [15:0] audio_div1 = 38 * (audf1 + 1) *
   (audc1 == 2 ? 15 :
    audc1 == 4 || audc1 == 5 ? 2 :
    audc1 == 6 || audc1 == 10 ? 31 :
    audc1 == 12 || audc1 == 13 || audc1 == 15 ? 6 :
    audc1 == 14 ? 93 : 1) ;

  reg [15:0] audio_left_counter, audio_right_counter;

  integer i;

  // always @(posedge cpu_clk_i) begin <--- TODO: Figure out why would this be clocked at CPU frequency?
  //                                              Is that how original TIA chip actually worked?
  always @(posedge clk_i) begin
      // Read-only registers
      if (valid_read_cmd) begin
        dat_o <= 0;
        case (adr_i[3:0])
          'h0: dat_o <= cx[14:13] << 6;         // CXM0P
          'h1: dat_o <= cx[12:11] << 6;         // CXM1P
          'h2: dat_o <= cx[10:9] << 6;          // CXP0FB
          'h3: dat_o <= cx[8:7] << 6;           // CXP1FB
          'h4: dat_o <= cx[6:5] << 6;           // CXM0FB
          'h5: dat_o <= cx[4:3] << 6;           // CXM1FB
          'h6: dat_o <= cx[2] << 7;             // CXBLPF
          'h7: dat_o <= cx[1:0] << 6;           // CXPPMM
          'h8: dat_o <= ypos > pot ? 8'h80 : 8'h00;                     // INPT0
          'h9: dat_o <= 0;                      // INPT1
          'ha: dat_o <= 0;                      // INPT2
          'hb: dat_o <= 0;                      // INPT3
          'hc: dat_o <= {buttons[FIRE], 7'b0};  // INPT4
          'hd: dat_o <= {buttons[FIRE], 7'b0};  // INPT5
        endcase
      end
  end
  
  // TIA implementation
  always @(posedge clk_i) begin
    if (rst_i) begin
      colubk <= 0;
      colupf <= 0;
      colup0 <= 0;
      colup1 <= 0;
      vsync <= 0;
      vblank <= 0;
      enam0 <= 0;
      enam1 <= 0;
      enabl <= 0;
      vdelbl <= 0;
      vdelp0 <= 0;
      vdelp1 <= 0;
      refp0 <= 0;
      refp1 <= 0;
      refpf <= 0;
      scorepf <= 0;
      pf_priority <= 0;
      grp0 <= 0;
      grp1 <= 0;
      x_p0 <= 0;
      x_p1 <= 0;
      x_m0 <= 0;
      x_m1 <= 0;
      x_bl <= 0;
      pf <= 0;
      hmp0 <= 0;
      hmp1 <= 0;
      hmm0 <= 0;
      hmm1 <= 0;
      hmbl <= 0;
      cx <= 0;
      cx_clr <= 0;
      m0_locked <= 0;
      m1_locked <= 0;
      ball_w <= 0;
      m0_w <= 0;
      m1_w <= 0;
      p0_w <= 0;
      p1_w <= 0;
      p0_scale <= 0;
      p1_scale <= 0;
      p0_copies <= 0;
      p1_copies <= 0;
      p0_spacing <= 0;
      p1_spacing <= 0;

      audv0 <= 0;
      audv1 <= 0;
      audc0 <= 0;
      audc1 <= 0;
      audf0 <= 0;
      audf1 <= 0;

      xpos <= 0;
      ypos <= 0;
      stall_cpu <= 0;
      vid_wr <= 0;

    // Process reads and writes from CPU
    end else if (cpu_enable_i) begin // TODO: if write_cmd instead, don't unnecesarry depend on cpu clock here
      cx_clr <= 0;

      // Write-only registers
      if (valid_write_cmd) begin
        case (adr_i) 
          'h00: begin                     // VSYNC
                  vsync <= dat_i[1];

                  if (vsync == 0 && dat_i[1] == 1) begin
                    xpos <= 0;
                    ypos <= 0;
                  end
                end
          'h01: begin                     // VBLANK
                  vblank <= dat_i[1];
                  latch_ports <= dat_i[6];
                  dump_ports <= dat_i[7];
                end
          'h02: stall_cpu <= 1;           // WSYNC
          // 'h03: ypos <= 0;                         // RSYNC      TODO: shouldn't RSYNC reset xpos or ypos?
          'h03: ;                         // RSYNC      TODO: shouldn't RSYNC reset xpos or ypos?
          'h04: begin                     // NUSIZ0 
                  m0_w <= (1 << dat_i[5:4]);
                  p0_scale <= 0;
                  case (dat_i[2:0])
                    0: begin p0_w <= 8; p0_copies <= 0; end
                    1: begin p0_w <= 8; p0_copies <= 1; p0_spacing <= 16; end
                    2: begin p0_w <= 8; p0_copies <= 1; p0_spacing <= 32; end
                    3: begin p0_w <= 8; p0_copies <= 2; p0_spacing <= 16; end
                    4: begin p0_w <= 8; p0_copies <= 1; p0_spacing <= 64; end
                    5: begin p0_w <= 16; p0_scale <= 1; p0_copies <= 0; end
                    6: begin p0_w <= 8; p0_copies <= 2; p0_spacing <= 32; end
                    7: begin p0_w <=32; p0_scale <= 2; p0_copies <= 0; end
                  endcase
                end
          'h05: begin                     // NUSIZ1
                  m1_w <= (1 << dat_i[5:4]);
                  p1_scale <= 0;
                  case (dat_i[2:0])
                    0: begin p1_w <= 8; p1_copies <= 0; end
                    1: begin p1_w <= 8; p1_copies <= 1; p1_spacing <= 16; end
                    2: begin p1_w <= 8; p1_copies <= 1; p1_spacing <= 32; end
                    3: begin p1_w <= 8; p1_copies <= 2; p1_spacing <= 16; end
                    4: begin p1_w <= 8; p1_copies <= 1; p1_spacing <= 64; end
                    5: begin p1_w <= 16; p1_scale <= 1; p1_copies <= 0; end
                    6: begin p1_w <= 8; p1_copies <= 2; p1_spacing <= 32; end
                    7: begin p1_w <=32; p1_scale <= 2; p1_copies <= 0; end
                  endcase
                end
          'h06: colup0 <= dat_i[7:1];     // COLUP0
          'h07: colup1 <= dat_i[7:1];     // COLUP1
          'h08: colupf <= dat_i[7:1];     // COLUPPF
          'h09: colubk <= dat_i[7:1];     // COLUPBK
          'h0a: begin                     // CTRLPF
                  ball_w <= (1 << dat_i[5:4]); 
                  refpf <= dat_i[0];
                  scorepf <= dat_i[1];
                  pf_priority <= dat_i[2];
                end
          'h0b: refp0 <= dat_i[3];        // REFP0
          'h0c: refp1 <= dat_i[3];        // REFP1
          'h0d: for(i = 0; i<4; i = i + 1) pf[i] <= dat_i[4+i];   // PF0
          'h0e: for(i = 0; i<8; i = i + 1) pf[4+i] <= dat_i[7-i]; // PF1
          'h0f: for(i = 0; i<8; i = i + 1) pf[12+i] <= dat_i[i];  // PF2
          // 'h10: x_p0 <= (xpos >= 160 | ypos < start) ? 0 : xpos + 5;        // RESP0
          // 'h11: x_p1 <= (xpos >= 160 | ypos < start) ? 0 : xpos + 5;        // RESP1
          // 'h12: x_m0 <= (xpos >= 160 | ypos < start) ? 0 : xpos + 5;        // RESM0
          // 'h13: x_m1 <= (xpos >= 160 | ypos < start) ? 0 : xpos + 5;        // RESM1
          // 'h14: x_bl <= (xpos >= 160 | ypos < start) ? 0 : xpos + 5;        // RESBL
          'h10: x_p0 <= xpos >= 160 ? 0 : xpos + 5;        // RESP0
          'h11: x_p1 <= xpos >= 160 ? 0 : xpos + 5;        // RESP1
          'h12: x_m0 <= xpos >= 160 ? 0 : xpos + 5;        // RESM0
          'h13: x_m1 <= xpos >= 160 ? 0 : xpos + 5;        // RESM1
          'h14: x_bl <= xpos >= 160 ? 0 : xpos + 5;        // RESBL
          'h15: audc0 <= dat_i[3:0];      // AUDC0
          'h16: audc1 <= dat_i[3:0];      // AUDC1
          'h17: audf0 <= dat_i[4:0];      // AUDF0
          'h18: audf1 <= dat_i[4:0];      // AUDF1
          'h19: audv0 <= dat_i[3:0];      // AUDV0
          'h1a: audv1 <= dat_i[3:0];      // AUDV1
	  'h1b: begin grp0 <= dat_i; old_grp1 <= grp1; end            // GRP0
	  'h1c: begin grp1 <= dat_i; old_grp0 <= grp0; end            // GRP1
          'h1d: enam0 <= dat_i[1];        // ENAM0
          'h1e: enam1 <= dat_i[1];        // ENAM1
          'h1f: enabl <= dat_i[1];        // ENABL
          'h20: hmp0 <= $signed(dat_i[7:4]);       // HMP0
          'h21: hmp1 <= $signed(dat_i[7:4]);       // HMP1
          'h22: hmm0 <= $signed(dat_i[7:4]);       // HMM0
          'h23: hmm1 <= $signed(dat_i[7:4]);       // HMM1
          'h24: hmbl <= $signed(dat_i[7:4]);       // HMBL
          'h25: vdelp0 <= dat_i[0];       // VDELP0
          'h26: vdelp1 <= dat_i[0];       // VDELP1
          'h27: vdelbl <= dat_i[0];       // VDELBL
          'h28: begin x_m0 <= x_p0 + (p0_w >> 1); m0_locked <= dat_i[1]; end // RESMP0
          'h29: begin x_m1 <= x_p1 + (p1_w >> 1); m1_locked <= dat_i[1]; end // RESMP1
          'h2a: begin                     // HMOVE
                  x_p0 <= x_p0 - hmp0;
                  x_p1 <= x_p1 - hmp1;
                  x_m0 <= x_m0 - hmm0;
                  x_m1 <= x_m1 - hmm1;
                  x_bl <= x_bl - hmbl;
                end
          'h2b: begin
                  hmp0 <= 0;              // HMCLR
                  hmp1 <= 0;
                  hmm0 <= 0;  
                  hmm1 <= 0;  
                  hmbl <= 0; 
                end
          'h2c: cx_clr <= 1;              // CXCLR
        endcase
      end
    end
    
    // Un-stall the cpu at hsync
    if (xpos == 160) stall_cpu <= 0;

    // Produce the video signal with a clock 3 times as fast as cpu clock
    if (!rst_i && enable_i) begin
      if (cx_clr) cx <= 0;
      vid_wr <= 0;

      if (ypos < depth - 1) begin // 262 clock counts depth for NSTC
        if (xpos < 227)  begin // 228 clocks width
           xpos <= xpos + 1;
        end else begin
           xpos <= 0;
           ypos <= ypos + 1;
        end

        // Check for collisions
        if (m0_bit) begin
          if (p1_bit) cx[14] <= 1;
          if (p0_bit) cx[13] <= 1;
        end

        if (m1_bit) begin
          if (p0_bit) cx[12] <= 1; // Looks wrong
          if (p1_bit) cx[11] <= 1;
        end

        if (p0_bit) begin
          if (pf_bit) cx[10] <= 1;
          if (bl_bit) cx[9] <= 1;
        end

        if (p1_bit) begin
          if (pf_bit) cx[8] <= 1;
          if (bl_bit) cx[7] <= 1;
        end

        if (m0_bit) begin
          if (pf_bit) cx[6] <= 1;
          if (bl_bit) cx[5] <= 1;
        end

        if (m1_bit) begin
          if (pf_bit) cx[4] <= 1;
          if (bl_bit) cx[3] <= 1;
        end

        if (bl_bit && pf_bit) cx[2] <= 1;

        if (p0_bit && p1_bit) cx[1] <= 1;

        if (m0_bit && m1_bit) cx[0] <= 1;

        // Draw pixel
        if ( ypos >= start && xpos < 160) begin // Don't draw in blank area
          // if (ypos >= hblank_area)
            vid_out <=
               bl_bit ? colupf :
               m0_bit ? colup0 :
               m1_bit ? colup1 :
               pf_priority && pf_bit ? pf_color :
               p0_bit ? colup0 :
               p1_bit ? colup1 :
               pf_bit ? pf_color : colubk;
          // else vid_out <= 8'b0;

          vid_wr <= 1;
        end
      end else begin
         ypos <= 0;
      end
    end
  end

  reg audio_l, audio_r;
  wire p4_l, p5_l, p9_l, p4_r, p5_r, p9_r;

  poly4 poly4_l (
    .clk(clk_i),
    .ena(audio_left_counter == audio_div0),
    .reset(rst_i),
    .q(p4_l)
  );

  poly5 poly5_l (
    .clk(clk_i),
    .ena(audio_left_counter == audio_div0),
    .reset(rst_i),
    .q(p5_l)
  );

  poly9 poly9_l (
    .clk(clk_i),
    .ena(audio_left_counter == audio_div0),
    .reset(rst_i),
    .q(p9_l)
  );

  poly4 poly4_r (
    .clk(clk_i),
    .ena(audio_right_counter == audio_div0),
    .reset(rst_i),
    .q(p4_r)
  );

  poly5 poly5_r (
    .clk(clk_i),
    .ena(audio_right_counter == audio_div0),
    .reset(rst_i),
    .q(p5_r)
  );

  poly9 poly9_r (
    .clk(clk_i),
    .ena(audio_right_counter == audio_div0),
    .reset(rst_i),
    .q(p9_r)
  );

  // Produce the audio
  always @(posedge clk_i) begin // WAS always @(posedge cpu_clk_i)
    if (rst_i) begin
      audio_l <= 0;
      audio_r <= 0;
      audio_left_counter <= 0;
      audio_right_counter <= 0;
    end else
    // Audio counts at CPU frequency
    if (cpu_enable_i) begin
      audio_left_counter <= audio_left_counter + 1;
      audio_right_counter <= audio_right_counter + 1;

      if (audc0 != 4'h0 && audc0 != 4'hb) begin
        if (audio_left_counter >= audio_div0) begin
          if (audc0 == 1) audio_l <= p4_l;
        	else if (audc0 == 8) audio_l <= p9_l;
          else if (audc0 == 9 || audc0 == 7) audio_l <= p5_l;
          else audio_l <= !audio_l;
          audio_left_counter <= 0;
        end
      end else audio_l <= 1;

      if (audc1 != 4'h0 && audc1 != 4'hb) begin
        if (audio_right_counter >= audio_div1) begin
          if (audc1 == 1) audio_r <= p4_r;
          else if (audc1 == 8) audio_r <= p9_r;
          else if (audc1 == 9 || audc1 == 7) audio_r <= p5_r;
          else audio_r <= !audio_r;
          audio_right_counter <= 0;
        end
      end else audio_r <= 1;
    end
  end

  assign audio_left = audio_l * audv0;
  assign audio_right = audio_r * audv1;

endmodule

module poly4 (
  input clk,
  input ena,
  input reset,
  output q
);

reg [3:0] x;

always @(posedge clk) begin
  if (reset) x <= 4'b1111;
  else if (ena) x <= {x[1] ^ x[0], x[3:1]};
end

assign q = x[0];

endmodule

module poly5 (
  input clk,
  input ena,
  input reset,
  output q
);

reg [4:0] x;

always @(posedge clk) begin
  if (reset) x <= 5'b1_1111;
  else if (ena) x <= {x[2] ^ x[0], x[4:1]};
end

assign q = x[0];

endmodule

module poly9 (
  input clk,
  input ena,
  input reset,
  output q
);

reg [8:0] x;

always @(posedge clk) begin
  if (reset) x <= 9'b1_1111_1111;
  else if (ena) x <= {x[4] ^ x[0], x[8:1]};
end

assign q = x[0];

endmodule

