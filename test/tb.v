`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/


module rom_2600_0 (
`ifdef GL_TEST
  input wire VPWR,
  input wire VGND,
`endif
  input  wire [11:0] addr,
  output wire [ 7:0] q
);
  assign q = {8{&addr}};
endmodule

module rom_2600_1 (
`ifdef GL_TEST
  input wire VPWR,
  input wire VGND,
`endif
  input  wire [11:0] addr,
  output wire [ 7:0] q
);
  assign q = {8{&addr}};
endmodule

module rom_2600_2 (
`ifdef GL_TEST
  input wire VPWR,
  input wire VGND,
`endif
  input  wire [11:0] addr,
  output wire [ 7:0] q
);
  assign q = {8{&addr}};
endmodule

module rom_2600_3 (
`ifdef GL_TEST
  input wire VPWR,
  input wire VGND,
`endif
  input  wire [11:0] addr,
  output wire [ 7:0] q
);
  assign q = {8{&addr}};
endmodule

module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
`ifdef GL_TEST
    $dumpvars(1, tb, qspi_rom_emu);
`else
    $dumpvars(0, tb);
`endif
    #1;
  end

`ifdef GL_TEST
  wire TIA_stall_cpu      = user_project.\atari2600.stall_cpu ;
  wire TIA_valid_read_cmd = user_project.\atari2600.tia.valid_read_cmd ;
  wire TIA_enabl          = user_project.\atari2600.tia.enabl ;
  wire TIA_enam0          = user_project.\atari2600.tia.enam0 ;
  wire TIA_enam1          = user_project.\atari2600.tia.enam1 ;

  wire [5:0] CPU_state = {  user_project.\atari2600.cpu.state[5] ,
                            user_project.\atari2600.cpu.state[4] ,
                            user_project.\atari2600.cpu.state[3] ,
                            user_project.\atari2600.cpu.state[2] ,
                            user_project.\atari2600.cpu.state[1] ,
                            user_project.\atari2600.cpu.state[0] };
  wire CPU_store = user_project.\atari2600.cpu.store ;
  wire CPU_N     = user_project.\atari2600.cpu.N ;
  wire CPU_V     = user_project.\atari2600.cpu.V ;
  wire CPU_D     = user_project.\atari2600.cpu.D ;
  wire CPU_I     = user_project.\atari2600.cpu.I ;
  wire CPU_Z     = user_project.\atari2600.cpu.Z ;
  wire CPU_C     = user_project.\atari2600.cpu.C ;

  wire [1:0] CPU_src_reg = {user_project.\atari2600.cpu.src_reg[1] ,
                            user_project.\atari2600.cpu.src_reg[0] };
  wire [1:0] CPU_dst_reg = {user_project.\atari2600.cpu.dst_reg[1] ,
                            user_project.\atari2600.cpu.dst_reg[0] };

  wire CPU_plp      = user_project.\atari2600.cpu.plp ;
  wire CPU_load_reg = user_project.\atari2600.cpu.load_reg ;
  wire CPU_alu_HC   = user_project.\atari2600.cpu.ALU.HC ;
  wire CPU_alu_CO   = user_project.\atari2600.cpu.ALU.CO ;
  wire CPU_adj_bcd  = user_project.\atari2600.cpu.adj_bcd ;
  wire CPU_adc_sbc  = user_project.\atari2600.cpu.adc_sbc ;
  wire CPU_adc_bcd  = user_project.\atari2600.cpu.adc_bcd ;

  wire [15:0] PC = { user_project.\atari2600.cpu.PC[15] ,
                     user_project.\atari2600.cpu.PC[14] ,
                     user_project.\atari2600.cpu.PC[13] ,
                     user_project.\atari2600.cpu.PC[12] ,
                     user_project.\atari2600.cpu.PC[11] ,
                     user_project.\atari2600.cpu.PC[10] ,
                     user_project.\atari2600.cpu.PC[9] ,
                     user_project.\atari2600.cpu.PC[8] ,
                     user_project.\atari2600.cpu.PC[7] ,
                     user_project.\atari2600.cpu.PC[6] ,
                     user_project.\atari2600.cpu.PC[5] ,
                     user_project.\atari2600.cpu.PC[4] ,
                     user_project.\atari2600.cpu.PC[3] ,
                     user_project.\atari2600.cpu.PC[2] ,
                     user_project.\atari2600.cpu.PC[1] ,
                     user_project.\atari2600.cpu.PC[0] };

  wire [15:0] ABr ={ user_project.\atari2600.address_bus_r[12] * 4'b1111,
                     user_project.\atari2600.address_bus_r[11] ,
                     user_project.\atari2600.address_bus_r[10] ,
                     user_project.\atari2600.address_bus_r[9] ,
                     user_project.\atari2600.address_bus_r[8] ,
                     user_project.\atari2600.address_bus_r[7] ,
                     user_project.\atari2600.address_bus_r[6] ,
                     user_project.\atari2600.address_bus_r[5] ,
                     user_project.\atari2600.address_bus_r[4] ,
                     user_project.\atari2600.address_bus_r[3] ,
                     user_project.\atari2600.address_bus_r[2] ,
                     user_project.\atari2600.address_bus_r[1] ,
                     user_project.\atari2600.address_bus_r[0] };

  wire [ 7:0] ADD ={ user_project.\atari2600.cpu.ADD[7] ,
                     user_project.\atari2600.cpu.ADD[6] ,
                     user_project.\atari2600.cpu.ADD[5] ,
                     user_project.\atari2600.cpu.ADD[4] ,
                     user_project.\atari2600.cpu.ADD[3] ,
                     user_project.\atari2600.cpu.ADD[2] ,
                     user_project.\atari2600.cpu.ADD[1] ,
                     user_project.\atari2600.cpu.ADD[0] };

  wire [ 7:0] DO = { user_project.\atari2600.cpu.DO[7] ,
                     user_project.\atari2600.cpu.DO[6] ,
                     user_project.\atari2600.cpu.DO[5] ,
                     user_project.\atari2600.cpu.DO[4] ,
                     user_project.\atari2600.cpu.DO[3] ,
                     user_project.\atari2600.cpu.DO[2] ,
                     user_project.\atari2600.cpu.DO[1] ,
                     user_project.\atari2600.cpu.DO[0] };
  wire [ 7:0] DI = { user_project.\atari2600.cpu.DI[7] ,
                     user_project.\atari2600.cpu.DI[6] ,
                     user_project.\atari2600.cpu.DI[5] ,
                     user_project.\atari2600.cpu.DI[4] ,
                     user_project.\atari2600.cpu.DI[3] ,
                     user_project.\atari2600.cpu.DI[2] ,
                     user_project.\atari2600.cpu.DI[1] ,
                     user_project.\atari2600.cpu.DI[0] };

  // SEL_A    = 2'd0,
  // SEL_S    = 2'd1,
  // SEL_X    = 2'd2, 
  // SEL_Y    = 2'd3;
  wire [ 7:0] REG_A = { user_project.\atari2600.cpu.AXYS[0][7] ,
                        user_project.\atari2600.cpu.AXYS[0][6] ,
                        user_project.\atari2600.cpu.AXYS[0][5] ,
                        user_project.\atari2600.cpu.AXYS[0][4] ,
                        user_project.\atari2600.cpu.AXYS[0][3] ,
                        user_project.\atari2600.cpu.AXYS[0][2] ,
                        user_project.\atari2600.cpu.AXYS[0][1] ,
                        user_project.\atari2600.cpu.AXYS[0][0] };
  wire [ 7:0] REG_S = { user_project.\atari2600.cpu.AXYS[1][7] ,
                        user_project.\atari2600.cpu.AXYS[1][6] ,
                        user_project.\atari2600.cpu.AXYS[1][5] ,
                        user_project.\atari2600.cpu.AXYS[1][4] ,
                        user_project.\atari2600.cpu.AXYS[1][3] ,
                        user_project.\atari2600.cpu.AXYS[1][2] ,
                        user_project.\atari2600.cpu.AXYS[1][1] ,
                        user_project.\atari2600.cpu.AXYS[1][0] };
  wire [ 7:0] REG_X = { user_project.\atari2600.cpu.AXYS[2][7] ,
                        user_project.\atari2600.cpu.AXYS[2][6] ,
                        user_project.\atari2600.cpu.AXYS[2][5] ,
                        user_project.\atari2600.cpu.AXYS[2][4] ,
                        user_project.\atari2600.cpu.AXYS[2][3] ,
                        user_project.\atari2600.cpu.AXYS[2][2] ,
                        user_project.\atari2600.cpu.AXYS[2][1] ,
                        user_project.\atari2600.cpu.AXYS[2][0] };
  wire [ 7:0] REG_Y = { user_project.\atari2600.cpu.AXYS[3][7] ,
                        user_project.\atari2600.cpu.AXYS[3][6] ,
                        user_project.\atari2600.cpu.AXYS[3][5] ,
                        user_project.\atari2600.cpu.AXYS[3][4] ,
                        user_project.\atari2600.cpu.AXYS[3][3] ,
                        user_project.\atari2600.cpu.AXYS[3][2] ,
                        user_project.\atari2600.cpu.AXYS[3][1] ,
                        user_project.\atari2600.cpu.AXYS[3][0] };

  wire qspi_restart    = user_project.spi_restart ;
  wire qspi_data_ready = user_project.\flash_rom.data_ready ;
  wire qspi_stall_read = user_project.\flash_rom.stall_read ;
  wire [ 2:0] qspi_state = { 
                     user_project.\flash_rom.fsm_state[2] ,
                     user_project.\flash_rom.fsm_state[1] ,
                     user_project.\flash_rom.fsm_state[0] };
  wire [23:0] qspi_addr = { 
                     user_project.\flash_rom.addr[23] ,
                     user_project.\flash_rom.addr[22] ,
                     user_project.\flash_rom.addr[21] ,
                     user_project.\flash_rom.addr[20] ,
                     user_project.\flash_rom.addr[19] ,
                     user_project.\flash_rom.addr[18] ,
                     user_project.\flash_rom.addr[17] ,
                     user_project.\flash_rom.addr[16] ,

                     user_project.\flash_rom.addr[15] ,
                     user_project.\flash_rom.addr[14] ,
                     user_project.\flash_rom.addr[13] ,
                     user_project.\flash_rom.addr[12] ,
                     user_project.\flash_rom.addr[11] ,
                     user_project.\flash_rom.addr[10] ,
                     user_project.\flash_rom.addr[9] ,
                     user_project.\flash_rom.addr[8] ,
                     user_project.\flash_rom.addr[7] ,
                     user_project.\flash_rom.addr[6] ,
                     user_project.\flash_rom.addr[5] ,
                     user_project.\flash_rom.addr[4] ,
                     user_project.\flash_rom.addr[3] ,
                     user_project.\flash_rom.addr[2] ,
                     user_project.\flash_rom.addr[1] ,
                     user_project.\flash_rom.addr[0] };

`endif

  qspi_rom_emu qspi_rom_emu(
    .clk        (clk),
    .reset      (~rst_n),
    .sclk       ( uio_out[3]),
    .select     ( uio_out[0]),
    .cmd_addr_in({uio_out[5:4], uio_out[2:1]}),
    .data_out   ({ uio_in[5:4], uio_in [2:1]}));

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  // Replace tt_um_example with your module name:
  tt_um_rejunity_atari2600 user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

endmodule
