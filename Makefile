
default: run

CLASSES_DIR = ./include

DUT = memory.v

files = $(CLASSES_DIR)/Transaction.sv \
	$(CLASSES_DIR)/Generator.sv \
	$(CLASSES_DIR)/Driver.sv	\
	$(CLASSES_DIR)/Monitor.sv	\
	$(CLASSES_DIR)/Scoreboard.sv \
	$(DUT) \
	$(CLASSES_DIR)/Test.sv \
	./Testbench.sv

run:
	rm -rf work
	vlog.exe -sv $(files)
	vsim.exe -batch testbench 
