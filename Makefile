
PROJECT := system
DEVICE := 1k

SOURCES = $(PROJECT).v spi.v bdcmotorchannel.v control.v tachcounter.v pwm8.v

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
	-killall gtkwave
	iverilog -o dsn testbench.v $(SOURCES)
	
dump.vcd: dsn
	vvp dsn

route: $(PROJECT).bin
	
wave: dump.vcd
	gtkwave dump.vcd &
	
check: dump.vcd
	-killall gtkwave
	
clean:
	-killall gtkwave
	-rm *.blif *.text *.bin dsn dump.vcd
	

