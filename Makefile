ROMS = \
	build/day01.gba \
	build/day02.gba \
	build/day03.gba \

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
