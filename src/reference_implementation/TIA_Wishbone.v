/*
 * Wishbone compliant Atari 2600 TIA module.
 * Original source from: https://github.com/lawrie/atari_2600/blob/master/verilog/wb_tia.v
 */
module wb_tia #(
    parameter WB_DATA_WIDTH = 8,
    parameter WB_ADDR_WIDTH = 7,
    parameter RAM_DEPTH = 128
) (
    // wishbone interface
    input                           clk_i,
    input                           rst_i,

    input                           stb_i,
    input                           we_i,
    input [WB_ADDR_WIDTH-1:0]       adr_i,
    input [WB_DATA_WIDTH-1:0]       dat_i,

    output reg                      ack_o,
    output reg [WB_DATA_WIDTH-1:0]  dat_o,

    // lcd interface
    output                          nreset,
    output                          cmd_data,
    output                          write_edge,
    output [7:0]                    dout,

    // buttons
    input [7:0]                     buttons,
    output [7:0]                    leds,

    // audio
    output                          audio_left,
    output                          audio_right,

    // cpu control
    output                          stall_cpu
);
    // Diagnostics
    assign leds = x_m0;

    // CPU control
    assign stall_cpu = wsync;

    // Button numbers
    localparam UP = 4, RIGHT = 7, LEFT = 6, DOWN = 5,
               A = 3, B = 1, X = 0, Y = 2;

    // TIA registers
    reg [15:0] colors [0:128];
    reg [6:0] colubk, colup0, colup1, colupf;
    reg vsync, vblank, wsync, enam0, enam1, enabl, vdelbl, vdelp0, vdelp1;
    reg refp0, refp1, refpf, scorepf, pf_priority;
    reg [7:0] grp0, grp1;
    reg [7:0] x_p0, x_p1, x_m0, x_m1, x_bl;
    reg [19:0] pf;
    reg signed [7:0] hmp0, hmp1, hmm0, hmm1, hmbl;
    reg [14:0] cx;
    reg cx_clr;
    reg [3:0] audc0, audc1, audv0, audv1;
    reg [4:0] audf0, audf1;
    reg m0_locked, m1_locked;
    reg [3:0] ball_w = 1, m0_w = 1, m1_w = 1;
    reg [5:0] p0_w = 8, p1_w = 8;
    reg [1:0] p0_scale, p1_scale;
    reg [1:0] p0_copies, p1_copies;
    reg [6:0] p0_spacing, p1_spacing;
    reg inpt0 = 0, inpt1 = 0, inpt2 = 0, inpt3 = 0, inpt4 = 0, inpt5 = 0;
    reg dump_ports, latch_ports;
    reg free_cpu, do_sync, done_sync;
    
    // Read the color numbers
    initial $readmemh("colors.mem", colors);

    // Wishbone interface
    wire valid_cmd = !rst_i && stb_i;
    wire valid_write_cmd = valid_cmd && we_i;
    wire valid_read_cmd = valid_cmd && !we_i;

    integer i;

    // TIA implementation
    always @(posedge clk_i) begin
        if (done_sync) do_sync <= 0;
        if (free_cpu) wsync <= 0;
        cx_clr <= 0;

        // Read-only registers
        if (valid_read_cmd) begin
          dat_o <= 0;
          case (adr_i)
          'h30, 'h00: dat_o <= cx[14:13] << 6;       // CXM0P
          'h31, 'h01: dat_o <= cx[12:11] << 6;       // CXM1P
          'h32, 'h02: dat_o <= cx[10:9] << 6;        // CXP0FB
          'h33, 'h03: dat_o <= cx[8:7] << 6;         // CXP1FB
          'h34, 'h04: dat_o <= cx[6:5] << 6;         // CXM0FB
          'h35, 'h05: dat_o <= cx[4:3] << 6;         // CXM1FB
          'h36, 'h06: dat_o <= cx[2] << 7;           // CXBLPF
          'h37, 'h07: dat_o <= cx[1:0] << 6;         // CXPPMM
          'h38, 'h08: dat_o <= inpt0 << 7;           // INPT0
          'h39, 'h09: dat_o <= inpt1 << 7;           // INPT1
          'h3a, 'h0a: dat_o <= inpt2 << 7;           // INPT2
          'h3b, 'h0b: dat_o <= inpt3 << 7;           // INPT3
          'h3c, 'h0c: dat_o <= buttons[A] << 7;      // INPT4
          'h3d, 'h0d: dat_o <= inpt5 << 7;           // INPT5
          endcase
        end

        // Write-only registers
        if (valid_write_cmd) begin
          case (adr_i) 
          'h00: begin                     // VSYNC
                   vsync <= dat_i[1]; 
                   if (vsync == 0 & dat_i[1]) do_sync <= 1; 
                end
          'h01: begin                     // VBLANK
                  vblank <= dat_i[1];
                  latch_ports <= dat_i[6];
                  dump_ports <= dat_i[7];
                end
          'h02: wsync <= 1;               // WSYNC
          'h03: ;                         // RSYNC
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
          'h0f: for(i = 0; i<8; i = i + 1) pf[12+i] = dat_i[i];   // PF2
          'h10: x_p0 <= xp >= 160 ? 0 : xp;        // RESP0
          'h11: x_p1 <= xp >= 160 ? 0 : xp;        // RESP1
          'h12: x_m0 <= xp >= 160 ? 0 : xp;        // RESM0
          'h13: x_m1 <= xp >= 160 ? 0 : xp;        // RESM1
          'h14: x_bl <= xp >= 160 ? 0 : xp;        // RESBL
          'h15: audc0 <= dat_i[3:0];      // AUDC0
          'h16: audc1 <= dat_i[3:0];      // AUDC1
          'h17: audf0 <= dat_i[4:0];      // AUDF0
          'h18: audf1 <= dat_i[4:0];      // AUDF1
          'h19: audv0 <= dat_i[3:0];      // AUDV0
          'h1a: audv1 <= dat_i[3:0];      // AUDV1
          'h1b: grp0 <= dat_i;            // GRP0
          'h1c: grp1 <= dat_i;            // GRP1
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
          'h28: begin x_m0 = x_p0 + (p0_w >> 1); m0_locked = dat_i[1]; end // RESMP0
          'h29: begin x_m1 = x_p1 + (p1_w >> 1); m1_locked = dat_i[1]; end // RESMP1
          'h2a: begin                     // HMOVE
                  x_p0 <= x_p0 - hmp0;
                  x_p1 <= x_p1 - hmp1;
                  x_m0 <= x_m0 - hmm0;
                  x_m1 <= x_m1 - hmm1;
                  x_bl <= x_bl - hmbl; 
                end
          'h2b: begin 
                  hmp0 <= 0;             // HMCLR
                  hmp1 <= 0;  
                  hmm0 <= 0;  
                  hmm1 <= 0;  
                  hmbl <= 0; 
                end
          'h2c: cx_clr <= 1;                  // CXCLR
          endcase
        end

        if (ypos < 40 || ypos >= 232) begin
          enabl <= 0;
          enam0 <= 0;
          enam1 <= 0;
        end

        ack_o <= valid_cmd;
    end

   // LCD data
   reg[8:0] xpos;
   reg[8:0] ypos;

   reg        pix_clk = 0;
   reg        reset_cursor = 0;
   wire       busy;
   reg [15:0] pix_data;
   wire       blank_busy = !(&busy_counter);
   reg [1:0]  busy_counter = 0;

   // ILI9341 LCD 8-bit parallel interface
   ili9341 lcd (
                .resetn(!rst_i),
                .clk_16MHz (clk_i),
                .nreset (nreset),
                .cmd_data (cmd_data),
                .write_edge (write_edge),
                .dout (dout),
                .reset_cursor (reset_cursor),
                .pix_data (pix_data),
                .pix_clk (pix_clk),
                .busy (busy)
                );

   // Drive the LCD like a CRT, racing the beam
   wire pf_bit = pf[xpos < 160 ? (xpos >> 3) : ((!refpf ? xpos - 160 : 319 - xpos) >> 3)];
   wire [7:0] xp = (xpos >> 1);
   wire p0_bit = (xp >= x_p0 && xp < x_p0 + p0_w ||
                   (p0_copies > 0 && ((xp - p0_spacing) >= x_p0 &&
                   (xp - p0_spacing) < x_p0 + p0_w)) ||
                   (p0_copies > 1 && ((xp - (p0_spacing << 1)) >= x_p0 &&
                   (xp - (p0_spacing << 1)) < x_p0 + p0_w))) &&
                    grp0[refp0 ? (xp - x_p0) >> p0_scale  : 7 - ((xp - x_p0) >> p0_scale)];
   wire p1_bit = (xp >= x_p1 && xp < x_p1 + p1_w ||
                   (p1_copies > 0 && ((xp - p1_spacing) >= x_p1 &&
                   (xp - p1_spacing) < x_p1 + p1_w)) ||
                   (p1_copies > 1 && ((xp - (p1_spacing << 1)) >= x_p1 &&
                   (xp - (p1_spacing << 1)) < x_p1 + p1_w))) &&
                    grp1[refp1 ? (xp - x_p1) >> p1_scale : 7 - ((xp - x_p1) >> p1_scale)];
   wire bl_bit = enabl && xp >= x_bl && xp < x_bl + ball_w;
   wire m0_bit = enam0 && xp >= x_m0 && xp < x_m0 + m0_w;
   wire m1_bit = enam1 && xp >= x_m1 && xp < x_m1 + m1_w;
   wire [6:0] pf_color = (scorepf ? (xp < 160 ? colup0 : colup1) :  colupf);

   always @(posedge clk_i) begin
      free_cpu <= 0;
      done_sync = 0;
      pix_clk <= 0;
      reset_cursor <= 0;

      if (cx_clr) cx <= 0;

      if (do_sync) begin
        reset_cursor <= 1;
        xpos <= 0;
        ypos <= 0;
        done_sync <= 1;
        free_cpu <= 1;
      end else if (!rst_i && !busy && !blank_busy && pix_clk == 0) begin
         if (ypos < 261) begin // 262 clock counts depth
            if (xpos < 455)  begin // 228 x 2 = 456 clock counts width
               xpos <= xpos + 1;
               if (xpos == 319) free_cpu <= 1; // Restart cpu in horizontal blank
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
            if ( ypos >= 16 && ypos < 256 && xpos < 320) begin // Don't draw in blank or overscan areas
              if (ypos >= 40 && ypos < 232) // Leave gap of 24 pixels at top and bottom
                pix_data <= colors[
                  bl_bit ? colupf :
                  m0_bit ? colup0 :
                  m1_bit ? colup1 :
                  pf_priority && pf_bit ? pf_color :
                  p0_bit ? colup0 :
                  p1_bit ? colup1 :
                  pf_bit ? pf_color : colubk];
              else pix_data <= 0;
             
              pix_clk <= 1;
           end else busy_counter <= 0; // Wait 8 clock cycles as if pixel were being written
              
         end else begin
            ypos <= 0;
         end
      end

      if (blank_busy) busy_counter <= busy_counter + 1;
   end

   // Audio
   wire [19:0] audio_div0 = 256 * audf0 * 
    (audc0 == 6 || audc0 == 10 ? 31 : 
     audc0 == 2 || audc0 == 3 ? 2 :
     audc0 == 12 || audc0 == 13 ? 6 :
     audc0 == 14 ? 93 : 1) ;

   wire [19:0] audio_div1 = 256 * audf1 * 
    (audc1 == 6 || audc1 == 10 ? 31 : 
     audc1 == 2 || audc1 == 3 ? 2 :
     audc1 == 12 || audc1 == 13 ? 6 :
     audc1 == 14 ? 93 : 1) ;

   reg [19:0] audio_left_counter, audio_right_counter;

   always @(posedge clk_i) begin
     audio_left_counter <= audio_left_counter + 1;
     audio_right_counter <= audio_right_counter + 1;

     if (audv0 > 0 && audio_left_counter >= audio_div0) begin
       audio_left <= !audio_left;
       audio_left_counter <= 0;
     end

     if (audv1 > 0 && audio_right_counter >= audio_div1) begin
       audio_right <= !audio_right;
       audio_right_counter <= 0;
     end
   end
endmodule
