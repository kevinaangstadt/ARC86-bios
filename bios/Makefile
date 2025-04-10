progs = bios

assembly := $(wildcard *.asm)


# conditionally set the ram and rom sizes
ifdef RAM_SIZE
	ram_size := -dRAM_SIZE=$(RAM_SIZE)
endif

ifdef ROM_SIZE
	rom_size := -dROM_SIZE=$(ROM_SIZE)
endif

# https://stackoverflow.com/a/23324703
mkfile_path := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
util_path := $(mkfile_path)/../util

all: $(addsuffix .bin, $(progs))

%.bin: $(assembly)
	nasm -Wall $(ram_size) $(rom_size) -f bin $< -o $@ -l $(basename $@).lst
	python3 $(util_path)/crc_calc.py $@ > $(basename $@).crc
	printf $$(python3 $(util_path)/crc_calc.py -l -n $@ | cut -dx -f2 | sed 's/../\\x&/g') >> $@
	

clean:
	rm -f *.bin *.lst *.crc

%.upload: %.bin
	minipro -p AT28C64B -uP -w $<

# Phony target to handle the upload command
upload: $(addsuffix .upload, $(filter-out upload, $(basename $(MAKECMDGOALS))))

# Prevent make from interpreting the goals as file names
%:
    @:

.PHONY: clean upload