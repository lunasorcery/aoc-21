ROMS = \
	build/day01.gba \
	build/day02.gba \
	build/day03.gba \
	build/day04.gba \
	build/day05.gba \
	build/day06.gba \
	build/day07.gba \
	build/day08.gba \
	build/day09.gba \
	build/day10.gba \
	build/day11.gba \

all: $(ROMS)

build/%.gba: build/%.elf
	$(DEVKITARM)/bin/arm-none-eabi-objcopy \
		$^ -O binary $@
	$(DEVKITPRO)/tools/bin/gbafix \
		-t"aoc21-$*" \
		-c"AC21" \
		-p \
		$@

build/%.elf: build/%.o
	$(DEVKITARM)/bin/arm-none-eabi-ld \
		$^ -o $@ \
		-Ttext 8000000 \
		-Map=build/$*.map

build/%.o: %.s %-data.s crt0.s common.s
	@mkdir -p build/
	$(DEVKITARM)/bin/arm-none-eabi-as \
		-c $*.s -o $@ \
		-mthumb -mthumb-interwork \
		-mcpu=arm7tdmi

clean:
	rm -rf build/

.PHONY: all clean
