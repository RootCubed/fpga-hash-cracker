SRC       := ./src
SRCS	  := $(filter-out $(SRC)/NSMBWHashCracker.sv, $(wildcard $(SRC)/*.sv))
TESTBENCH := $(SRC)/tb/HashTB.sv

all: simulate

lint:
	verilator --lint-only $(SRCS)

.PHONY: build
.PHONY: simulate

build:
	gcc complete_collisions.c -o complete_collisions

simulate:
	iverilog -g2012 -Wall -o $(TESTBENCH).vvp $(SRCS) $(TESTBENCH)
	cd ./src/data && vvp ../../$(TESTBENCH).vvp -n -fst 1> Testbench.log

gtkwave: simulate
	gtkwave $(SRC)/data/HashTB.fst $(SRC)/data/testbench_wave.gtkw --optimize

clean:
	rm -rf $(TESTBENCH).fst HashTB.vcd