filename = top
pcf_file = ../common/io.pcf

build:
	yosys -p "synth_ice40 -json $(filename).json -blif $(filename).blif" $(filename).v
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc --freq 24
	icepack $(filename).asc $(filename).bin

prog:
	iceprog -S $(filename).bin

prog_flash:
	iceprog $(filename).bin

clean:
	rm -rf $(filename).blif $(filename).asc $(filename).bin
