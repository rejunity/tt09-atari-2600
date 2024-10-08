TOP = top
MAIN_CPP = atari2600.cpp
EXEC_NAME = a2600

# verilator -Wno-CASEINCOMPLETE -Wno-CASEX -Wno-CASEOVERLAP -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-PINMISSING
#            -O3 --x-assign fast --x-initial fast --noassert -I../src
#            -cc top.v tt_um_rejunity_atari2600.v TIA.v PIA.v 6502.v ALU.v vga_hvsync_generator.v palette_24bpp.v --exe -o a2600.mk
#			  -CFLAGS `sdl2-config --cflags` -LDFLAGS "-L/opt/local/lib -lSDL2"

#  make -C ./obj_dir -f Vtop.mk

#  ./obj_dir/a2600

VFLAGS = -O3 --x-assign fast --x-initial fast --noassert
WFLAGS = -Wno-CASEINCOMPLETE -Wno-CASEX -Wno-CASEOVERLAP -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-PINMISSING
SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

SRC_DIR = $(PWD)/../src
PROJECT_SOURCES += tt_um_rejunity_atari2600.v vga_hvsync_generator.v
PROJECT_SOURCES += 6502.v ALU.v TIA.v PIA.v
PROJECT_SOURCES += palette_24bpp.v

a2600: V${TOP}.mk
	make -C ./obj_dir -f V${TOP}.mk

V${TOP}.mk: ${MAIN_CPP}
	verilator ${VFLAGS} ${WFLAGS} -I${SRC_DIR} \
		-cc  ${TOP}.v ${PROJECT_SOURCES}  --exe $< -o ${EXEC_NAME} \
		-CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}"

#all:

clean:
	rm -rf ./obj_dir

.PHONY: all clean

