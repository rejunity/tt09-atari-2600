TOP = top
MAIN_CPP = atari2600.cpp
EXEC_NAME = a2600

DFLAGS = -DSIM
VFLAGS = -O3 --x-assign fast --x-initial fast --noassert
WFLAGS = -Wno-CASEINCOMPLETE -Wno-CASEX -Wno-CASEOVERLAP -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-PINMISSING
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

SRC_DIR = $(PWD)/../src
PROJECT_SOURCES += tt_um_rejunity_atari2600.v atari2600.v vga_hvsync_generator.v qspi_flash.v
PROJECT_SOURCES += 6502.v ALU.v TIA.v PIA.v
PROJECT_SOURCES += palette_24bpp.v

SRC_TEST_UTILS_DIR = $(PWD)/../test
PROJECT_SOURCES += qspi_rom_emu.v

a2600: V${TOP}.mk
	make -C ./obj_dir -f V${TOP}.mk
	cp ./obj_dir/${EXEC_NAME} .

V${TOP}.mk: ${MAIN_CPP}
	verilator ${VFLAGS} ${WFLAGS} -I${SRC_DIR} -I${SRC_TEST_UTILS_DIR} \
		-top $(TOP) -cc  ${TOP}.v ${PROJECT_SOURCES}  --exe $< -o ${EXEC_NAME} \
		${DFLAGS} -CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

all:

clean:
	rm -rf ./obj_dir
	rm -f  ./${EXEC_NAME}

.PHONY: all clean

