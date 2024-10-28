`default_nettype none

module qspi_rom_emu #(parameter ADDR_BITS = 24) (
  input wire clk,
  input wire select,
  input wire [3:0] cmd_addr_in,
  output reg [3:0] data_out
);
  parameter DATA_WIDTH_BYTES = 1;
  localparam CMD    = 8;
  localparam ADDR   = CMD   + ADDR_BITS/4;  // receive address -> read pointer
  localparam LOAD   = ADDR  + 3;            // load 2 bytes ahead: 1) 1st byte
  localparam LOAD2  = LOAD  + 1;            //                     2) 2nd byte
  localparam INCA   = LOAD2 + 1;            // advance read pointer by 2 bytes
  localparam DATA   = INCA  + 1;            // serve data

  reg [7:0] counter;
  reg [ADDR_BITS-1:0] addr;
  always @(posedge clk) begin
    if (select) begin
      counter <= 0;
    end else begin
      counter <= counter + 1;
      if      (counter <  CMD)  addr            <= 0;
      else if (counter < ADDR)  addr            <= {addr[ADDR_BITS-1-4:0], cmd_addr_in};
      else if (counter < LOAD)  data[15:8]      <= rom[addr[11:0]       ];
      else if (counter < LOAD2) data[7:0]       <= rom[addr[11:0] + 1'b1];
      else if (counter < INCA)  addr            <= addr + 2;
      else if (counter < DATA)  data_out        <= data[15-:4]; // 1st nibble
      else begin           
                                data_out        <= data[11-:4]; // 2nd nibble
                                // load next byte
                                data[15:8]      <= data[7:0];   
                                data[7:0]       <= rom[addr[11:0]];
                                addr            <= addr + 1;
                                counter         <= counter - 1;
      end
    end
  end

  reg [15:0] data;
  reg [7:0] rom [4095:0];
  initial begin
    $readmemh("../roms/rom.mem", rom, 0, 4095);
    // DEBUG: override reset vector
    // rom[12'hFFD] <= 8'hF0; rom[12'hFFC] <= 8'h00;
  end  
endmodule
