`default_nettype none

// all build targets except the tapeout GDS job
// potentially can use emulation instead of macro ROMs
// GDS job uses real macro ROMs
`ifdef SIM
`define MACRO_ROM_EMU
`elsif FPGA
`define MACRO_ROM_EMU
`elsif SYNTH
`define MACRO_ROM_EMU
`endif

`ifdef MACRO_ROM_EMU

module rom_2600_0 (
`ifdef GL_TEST
  input wire VPWR,
  input wire VGND,
`endif
  input  wire [11:0] addr,
  output wire [ 7:0] q
);
  reg [7:0] rom [4095:0]; assign q = rom[addr];
  initial begin
    $readmemh("../roms/rom_macro_0.mem", rom, 0, 4095);
  end
endmodule

module rom_2600_1 (
`ifdef GL_TEST
  input wire VPWR,
  input wire VGND,
`endif
  input  wire [11:0] addr,
  output wire [ 7:0] q
);
  reg [7:0] rom [4095:0]; assign q = rom[addr];
  initial begin
    $readmemh("../roms/rom_macro_1.mem", rom, 0, 4095);
  end
endmodule

module rom_2600_2 (
`ifdef GL_TEST
  input wire VPWR,
  input wire VGND,
`endif
  input  wire [11:0] addr,
  output wire [ 7:0] q
);
  reg [7:0] rom [4095:0]; assign q = rom[addr];
  initial begin
    $readmemh("../roms/rom_macro_2.mem", rom, 0, 4095);
  end
endmodule

module rom_2600_3 (
`ifdef GL_TEST
  input wire VPWR,
  input wire VGND,
`endif
  input  wire [11:0] addr,
  output wire [ 7:0] q
);
  reg [7:0] rom [4095:0]; assign q = rom[addr];
  initial begin
    $readmemh("../roms/rom_macro_3.mem", rom, 0, 4095);
  end
endmodule

`endif