
PROJECT := root
DEVICE := 1k

SOURCES = $(PROJECT).v system.v spi.v bdcmotorchannel.v control.v tachcounter.v pwm8.v

.PHONY:	clean, wave, check, route

all:	check

# Synthesis
$(PROJECT).blif:	$(SOURCES)
	yosys -p "synth_ice40 -blif $(PROJECT).blif" $(SOURCES)

# Place and route	
$(PROJECT).text:	$(PROJECT).blif $(PROJECT).pcf
	arachne-pnr -d $(DEVICE) -p $(PROJECT).pcf $(PROJECT).blif -o $(PROJECT).text

# Binary Pack
$(PROJECT).bin:	$(PROJECT).text
	icepack $(PROJECT).text $(PROJECT).bin

dsn: testbench.v $(SOURCES)
	@-killall gtkwave 2>/dev/null
	iverilog -o dsn testbench.v $(SOURCES)
	
dump.vcd: dsn
	vvp dsn

route: $(PROJECT).bin

prog: $(PROJECT).bin
	sudo iceprog $(PROJECT).bin
	
wave: dump.vcd
	gtkwave dump.vcd &
	
check: dump.vcd
	-killall gtkwave 2>/dev/null
	
clean:
	-killall gtkwave 2>/dev/null
	-rm *.blif *.text *.bin dsn dump.vcd 2>/dev/null
	

