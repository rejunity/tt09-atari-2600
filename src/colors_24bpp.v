// TODO: make into palette ROM
// Original source from: https://github.com/lawrie/ulx3s_atari_2600/blob/main/src/video/video.v


`default_nettype none
module video (
  input             clk,
  input             reset,
  input             pal,
  output [7:0]      vga_r,
  output [7:0]      vga_b,
  output [7:0]      vga_g,
  output            vga_hs,
  output            vga_vs,
  output            vga_de,
  input  [6:0]      vga_data,
  output reg [15:0] vga_addr
);

  parameter HA = 640;
  parameter HS  = 96;
  parameter HFP = 16;
  parameter HBP = 48;
  parameter HT  = HA + HS + HFP + HBP;

  parameter VA = 480;
  parameter VS  = 2;
  parameter VFP = 11;
  parameter VBP = 31;
  parameter VT  = VA + VS + VFP + VBP;
  parameter VB  = 0;
  parameter VB2 = VB/2;
  parameter HB = 0;
  parameter HB2 = HB/2;
  parameter HA2 = HA/2;

  reg [23:0] ntsc_palette [0:127];

  initial begin
    ntsc_palette[0]   = 24'h000000; // White
    ntsc_palette[1]   = 24'h404040;
    ntsc_palette[2]   = 24'h6c6c6c;
    ntsc_palette[3]   = 24'h909090;
    ntsc_palette[4]   = 24'hb0b0b0;
    ntsc_palette[5]   = 24'hc8c8c8;
    ntsc_palette[6]   = 24'hdcdcdc;
    ntsc_palette[7]   = 24'hececec;

    ntsc_palette[8]   = 24'h444400; // Gold
    ntsc_palette[9]   = 24'h646410;
    ntsc_palette[10]  = 24'h848424;
    ntsc_palette[11]  = 24'ha0a034;
    ntsc_palette[12]  = 24'hb8b840;
    ntsc_palette[13]  = 24'hd0d050;
    ntsc_palette[14]  = 24'he8e85c;
    ntsc_palette[15]  = 24'hfcfc68;

    ntsc_palette[16]  = 24'h702800; // Orange
    ntsc_palette[17]  = 24'h844414;
    ntsc_palette[18]  = 24'h985c28;
    ntsc_palette[19]  = 24'hac783c;
    ntsc_palette[20]  = 24'hbc8c4d;
    ntsc_palette[21]  = 24'hcca05c;
    ntsc_palette[22]  = 24'hdcb468;
    ntsc_palette[23]  = 24'hecc878;

    ntsc_palette[24]  = 24'h841800; // Red
    ntsc_palette[25]  = 24'h983418;
    ntsc_palette[26]  = 24'hac5030;
    ntsc_palette[27]  = 24'hc06848;
    ntsc_palette[28]  = 24'hd0985c;
    ntsc_palette[29]  = 24'he09470;
    ntsc_palette[30]  = 24'heca880;
    ntsc_palette[31]  = 24'hfcbc94;

    ntsc_palette[32]  = 24'h880000; // Pink
    ntsc_palette[33]  = 24'h9c2020;
    ntsc_palette[34]  = 24'hb03c3c;
    ntsc_palette[35]  = 24'hc05858;
    ntsc_palette[36]  = 24'hd07070;
    ntsc_palette[37]  = 24'he08888;
    ntsc_palette[38]  = 24'heca0a0;
    ntsc_palette[39]  = 24'hfcb4b4;

    ntsc_palette[40]  = 24'h78005c; // Purple
    ntsc_palette[41]  = 24'h8c2074;
    ntsc_palette[42]  = 24'ha03c88;
    ntsc_palette[43]  = 24'hb0589c;
    ntsc_palette[44]  = 24'hc070b0;
    ntsc_palette[45]  = 24'hd084c0;
    ntsc_palette[46]  = 24'hdc9cd0;
    ntsc_palette[47]  = 24'hecb0e0;

    ntsc_palette[48]  = 24'h480078; // Mauve
    ntsc_palette[49]  = 24'h602090;
    ntsc_palette[50]  = 24'h783ca4;
    ntsc_palette[51]  = 24'h8c58b8;
    ntsc_palette[52]  = 24'ha070cc;
    ntsc_palette[53]  = 24'hb484dc;
    ntsc_palette[54]  = 24'hc49cec;
    ntsc_palette[55]  = 24'hd4b0fc;

    ntsc_palette[56]  = 24'h140084; // Lilac
    ntsc_palette[57]  = 24'h302098;
    ntsc_palette[58]  = 24'h4c3cac;
    ntsc_palette[59]  = 24'h6858c0;
    ntsc_palette[60]  = 24'h7c70d0;
    ntsc_palette[61]  = 24'h9488e0;
    ntsc_palette[62]  = 24'ha8a0ec;
    ntsc_palette[63]  = 24'hbcb4fc;

    ntsc_palette[64]  = 24'h000088; // Blue
    ntsc_palette[65]  = 24'h1c209c;
    ntsc_palette[66]  = 24'h3440b0;
    ntsc_palette[67]  = 24'h505cc0;
    ntsc_palette[68]  = 24'h6874d0;
    ntsc_palette[69]  = 24'h7c8ce0;
    ntsc_palette[70]  = 24'h90a4ec;
    ntsc_palette[71]  = 24'ha4b8fc;

    ntsc_palette[72]  = 24'h00187c; // Blue
    ntsc_palette[73]  = 24'h1c3890;
    ntsc_palette[74]  = 24'h3854a8;
    ntsc_palette[75]  = 24'h5070bc;
    ntsc_palette[76]  = 24'h6888cc;
    ntsc_palette[77]  = 24'h7c9cdc;
    ntsc_palette[78]  = 24'h90b4ec;
    ntsc_palette[79]  = 24'ha4c8fc;

    ntsc_palette[80]  = 24'h002c5c; // Light Blue
    ntsc_palette[81]  = 24'h1c4c78;
    ntsc_palette[82]  = 24'h386890;
    ntsc_palette[83]  = 24'h5084ac;
    ntsc_palette[84]  = 24'h689cc0;
    ntsc_palette[85]  = 24'h7cb4d4;
    ntsc_palette[86]  = 24'h90cce8;
    ntsc_palette[87]  = 24'ha4e0fc;

    ntsc_palette[88]  = 24'h003c2c; // Turquoise
    ntsc_palette[89]  = 24'h1c5c48;
    ntsc_palette[90]  = 24'h387c64;
    ntsc_palette[91]  = 24'h509c80;
    ntsc_palette[92]  = 24'h68b494;
    ntsc_palette[93]  = 24'h7cd0ac;
    ntsc_palette[94]  = 24'h90e4c0;
    ntsc_palette[95]  = 24'ha4fcd4;

    ntsc_palette[96]  = 24'h003c00; // Green
    ntsc_palette[97]  = 24'h205c20;
    ntsc_palette[98]  = 24'h407c40;
    ntsc_palette[99]  = 24'h5c9c5c;
    ntsc_palette[100] = 24'h74b474;
    ntsc_palette[101] = 24'h8cd08c;
    ntsc_palette[102] = 24'ha4e4a4;
    ntsc_palette[103] = 24'hb8fcb8;

    ntsc_palette[104] = 24'h143800; // Light Green
    ntsc_palette[105] = 24'h345c1c;
    ntsc_palette[106] = 24'h507c38;
    ntsc_palette[107] = 24'h6c9850;
    ntsc_palette[108] = 24'h84b468;
    ntsc_palette[109] = 24'h9ccc7c;
    ntsc_palette[110] = 24'hb4e490;
    ntsc_palette[111] = 24'hc8fca4;

    ntsc_palette[112] = 24'h2c3000; // Muddy Green
    ntsc_palette[113] = 24'h4c501c;
    ntsc_palette[114] = 24'h687034;
    ntsc_palette[115] = 24'h848c4c;
    ntsc_palette[116] = 24'h9ca864;
    ntsc_palette[117] = 24'hb4c078;
    ntsc_palette[118] = 24'hccd488;
    ntsc_palette[119] = 24'he0ec9c;

    ntsc_palette[120] = 24'h442800; // Brown
    ntsc_palette[121] = 24'h644818;
    ntsc_palette[122] = 24'h846830;
    ntsc_palette[123] = 24'ha08444;
    ntsc_palette[124] = 24'hb89c58;
    ntsc_palette[125] = 24'hd0b46c;
    ntsc_palette[126] = 24'he8cc7c;
    ntsc_palette[127] = 24'hfce08c;
  end

  reg [23:0] pal_palette [0:127];

  initial begin
    pal_palette[0]   = 24'h000000; // White
    pal_palette[1]   = 24'h282828;
    pal_palette[2]   = 24'h505050;
    pal_palette[3]   = 24'h747474;
    pal_palette[4]   = 24'h949494;
    pal_palette[5]   = 24'hb4b4b4;
    pal_palette[6]   = 24'hd0d0d0;
    pal_palette[7]   = 24'hececec;

    pal_palette[8]   = 24'h444400;
    pal_palette[9]   = 24'h282828;
    pal_palette[10]  = 24'h505050;
    pal_palette[11]  = 24'h747474;
    pal_palette[12]  = 24'h949494;
    pal_palette[13]  = 24'hb4b4b4;
    pal_palette[14]  = 24'hd0d0d0;
    pal_palette[15]  = 24'hececec;

    pal_palette[16]  = 24'h805800;
    pal_palette[17]  = 24'h947020;
    pal_palette[18]  = 24'ha8843c;
    pal_palette[19]  = 24'hbc9c58;
    pal_palette[20]  = 24'hccac70;
    pal_palette[21]  = 24'hdcc084;
    pal_palette[22]  = 24'hecd09c;
    pal_palette[23]  = 24'hfce0b0;

    pal_palette[24]  = 24'h445c00;
    pal_palette[25]  = 24'h5c7820;
    pal_palette[26]  = 24'h74903c;
    pal_palette[27]  = 24'h8cac58;
    pal_palette[28]  = 24'ha0c070;
    pal_palette[29]  = 24'hb0d484;
    pal_palette[30]  = 24'hc4e89c;
    pal_palette[31]  = 24'hd4fcb0;

    pal_palette[32]  = 24'h703400;
    pal_palette[33]  = 24'h885020;
    pal_palette[34]  = 24'ha0683c;
    pal_palette[35]  = 24'hb48458;
    pal_palette[36]  = 24'hc89870;
    pal_palette[37]  = 24'hdcac84;
    pal_palette[38]  = 24'hecc09c;
    pal_palette[39]  = 24'hfcd4b0;

    pal_palette[40]  = 24'h006414;
    pal_palette[41]  = 24'h208034;
    pal_palette[42]  = 24'h3c9850;
    pal_palette[43]  = 24'h58b06c;
    pal_palette[44]  = 24'h70c484;
    pal_palette[45]  = 24'h84d89c;
    pal_palette[46]  = 24'h9ce8b4;
    pal_palette[47]  = 24'hb0fcc8;

    pal_palette[48]  = 24'h700014;
    pal_palette[49]  = 24'h882034;
    pal_palette[50]  = 24'ha03c50;
    pal_palette[51]  = 24'hb4586c;
    pal_palette[52]  = 24'hc87084;
    pal_palette[53]  = 24'hdc849c;
    pal_palette[54]  = 24'hec9cb4;
    pal_palette[55]  = 24'hfcb0c8;

    pal_palette[56]  = 24'h005c5c;
    pal_palette[57]  = 24'h207474;
    pal_palette[58]  = 24'h3c8c8c;
    pal_palette[59]  = 24'h58a4a4;
    pal_palette[60]  = 24'h70b8b8;
    pal_palette[61]  = 24'h84c8c8;
    pal_palette[62]  = 24'h9cdcdc;
    pal_palette[63]  = 24'hb0ecec;

    pal_palette[64]  = 24'h70005c;
    pal_palette[65]  = 24'h842074;
    pal_palette[66]  = 24'h943c88;
    pal_palette[67]  = 24'ha8589c;
    pal_palette[68]  = 24'hb470b0;
    pal_palette[69]  = 24'hc484c0;
    pal_palette[70]  = 24'hd09cd0;
    pal_palette[71]  = 24'he0b0e0;

    pal_palette[72]  = 24'h003c70;
    pal_palette[73]  = 24'h1c5888;
    pal_palette[74]  = 24'h3874a0;
    pal_palette[75]  = 24'h508cb4;
    pal_palette[76]  = 24'h68a4c8;
    pal_palette[77]  = 24'h7cb8dc;
    pal_palette[78]  = 24'h90ccec;
    pal_palette[79]  = 24'ha4e0fc;

    pal_palette[80]  = 24'h580070;
    pal_palette[81]  = 24'h6c2088;
    pal_palette[82]  = 24'h803ca0;
    pal_palette[83]  = 24'h9458b4;
    pal_palette[84]  = 24'ha470c8;
    pal_palette[85]  = 24'hb484dc;
    pal_palette[86]  = 24'hc49cec;
    pal_palette[87]  = 24'hd4b0fc;

    pal_palette[88]  = 24'h002070;
    pal_palette[89]  = 24'h1c3c88;
    pal_palette[90]  = 24'h3858a0;
    pal_palette[91]  = 24'h507484;
    pal_palette[92]  = 24'h6888c8;
    pal_palette[93]  = 24'h7ca0dc;
    pal_palette[94]  = 24'h90b4ec;
    pal_palette[95]  = 24'ha4c8fc;

    pal_palette[96]  = 24'h3c0080;
    pal_palette[97]  = 24'h542094;
    pal_palette[98]  = 24'h6c3ca8;
    pal_palette[99]  = 24'h8058bc;
    pal_palette[100] = 24'h9470cc;
    pal_palette[101] = 24'ha884dc;
    pal_palette[102] = 24'hb89cec;
    pal_palette[103] = 24'hc8b0fc;

    pal_palette[104] = 24'h000088;
    pal_palette[105] = 24'h20209c;
    pal_palette[106] = 24'h3c3cb0;
    pal_palette[107] = 24'h5858c0;
    pal_palette[108] = 24'h7070d0;
    pal_palette[109] = 24'h8484e0;
    pal_palette[110] = 24'h9c9cec;
    pal_palette[111] = 24'hb0b0fc;

    pal_palette[112] = 24'h000000;
    pal_palette[113] = 24'h282828;
    pal_palette[114] = 24'h505050;
    pal_palette[115] = 24'h747474;
    pal_palette[116] = 24'h949494;
    pal_palette[117] = 24'hb4b4b4;
    pal_palette[118] = 24'hd0d0d0;
    pal_palette[119] = 24'hececec;

    pal_palette[120] = 24'h000000;
    pal_palette[121] = 24'h282828;
    pal_palette[122] = 24'h505050;
    pal_palette[123] = 24'h747474;
    pal_palette[124] = 24'h949494;
    pal_palette[125] = 24'hb4b4b4;
    pal_palette[126] = 24'hd0d0d0;
    pal_palette[127] = 24'hececec;
  end

  reg [9:0] hc = 0;
  reg [9:0] vc = 0;

  // Set horizontal and vertical counters, and process interrupts
  always @(posedge clk) begin
    if (reset) begin
      hc <= 0;
      vc <= 0;
    end else if (hc == HT - 1) begin
      hc <= 0;
      if (vc == VT - 1) vc <= 0;
      else vc <= vc + 1;
    end else hc <= hc + 1;
  end

  assign vga_hs = !(hc >= HA + HFP && hc < HA + HFP + HS);
  assign vga_vs = !(vc >= VA + VFP && vc < VA + VFP + VS);
  assign vga_de = !(hc >= HA || vc >= VA);

  wire [7:0] x = hc[9:2] - HB2;
  wire [7:0] y = vc[9:1] - VB2;

  wire h_border = (hc < HB || hc >= (HA - HB));
  wire v_border = (vc < VB || vc >= VA - VB);
  wire border = h_border || v_border;

  reg [23:0] pixels;

  // Read video memory
  always @(posedge clk) begin
    vga_addr <= x < 160 ? y * 160 + x + 1 : (y + 1) * 160;
    pixels <= pal ? pal_palette[vga_data] : ntsc_palette[vga_data];
  end

  wire [23:0] col = border ? 0 : pixels;

  wire [7:0] red = col[23:16];
  wire [7:0] green = col[15:8];
  wire [7:0] blue = col[7:0];

  assign vga_r = !vga_de ? 8'b0 : red;
  assign vga_g = !vga_de ? 8'b0 : green;
  assign vga_b = !vga_de ? 8'b0 : blue;

endmodule

