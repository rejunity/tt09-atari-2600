TOP = icebreaker
#TOP = video

all: $(TOP).rpt $(TOP).bin

%.json: %.v
	yosys -p 'synth_ice40 -top top -json $@' $<

icebreaker.json: icebreaker.v ../src/tt_um_rejunity_atari2600.v ../src/atari2600.v ../src/vga_hvsync_generator.v ../src/palette_24bpp.v ../src/qspi_flash.v ../src/6502.v ../src/ALU.v ../src/TIA.v ../src/PIA.v ../test/qspi_rom_emu.v
	yosys -p "read_verilog $^; synth_ice40 -top top -json $@; ltp"

%.asc: %.json icebreaker.pcf
	nextpnr-ice40 --up5k --package sg48 --freq 12 --asc $@ --pcf icebreaker.pcf --json $<

%.bin: %.asc
	icepack -s $< $@

%.rpt: %.asc
	icetime -d up5k -mtr $@ $<

%_tb: %_tb.v %.v
	iverilog -o $@ $^

%_tb.vcd: %_tb
	vvp -N $< +vcd=$@

%_syn.v: %.json
	yosys -p 'read_json $^; write_verilog $@'

%_syntb: %_tb.v %_syn.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_syntb.vcd: %_syntb
	vvp -N $< +vcd=$@

prog: $(TOP).bin
	iceprog $<

sudo-prog: $(TOP).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -f $(TOP).json $(TOP).asc $(TOP).rpt $(TOP).bin
	rm -f $(TOP)_tb $(TOP)_tb.vcd $(TOP)_syn.v $(TOP)_syntb $(TOP)_syntb.vcd

.SECONDARY:
.PHONY: all prog clean
