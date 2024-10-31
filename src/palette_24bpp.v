// TODO: make into palette ROM
// Original source from: https://github.com/lawrie/ulx3s_atari_2600/blob/main/src/video/video.v

`default_nettype none

module palette(
  input   [3:0] hue,
  input   [3:0] lum,
  output [23:0] rgb_24bpp
);

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
    ntsc_palette[20]  = 24'hbc8c4d; // D. Beer color vaue tiny bit differs: hBC8C4C
    ntsc_palette[21]  = 24'hcca05c;
    ntsc_palette[22]  = 24'hdcb468;
    ntsc_palette[23]  = 24'hecc878;

    ntsc_palette[24]  = 24'h841800; // Red
    ntsc_palette[25]  = 24'h983418;
    ntsc_palette[26]  = 24'hac5030;
    ntsc_palette[27]  = 24'hc06848;
    ntsc_palette[28]  = 24'hd0805c;
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
    ntsc_palette[66]  = 24'h3840b0;
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

  assign rgb_24bpp = ntsc_palette[{hue, lum[3:1]}];
endmodule

