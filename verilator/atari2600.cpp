#include <stdio.h>
// #include <SDL.h>
#include <SDL2/SDL.h>
#include <verilated.h>
#include "Vtop.h"

// screen dimensions including overscan areas for debugging
const int H_RES = 800;
const int V_RES = 525;
const int TOTAL_RES = H_RES*V_RES;

typedef struct Pixel {  // for SDL texture
    uint8_t a;  // transparency
    uint8_t b;  // blue
    uint8_t g;  // green
    uint8_t r;  // red
} Pixel;

int main(int argc, char* argv[]) {
    Verilated::commandArgs(argc, argv);

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("SDL init failed.\n");
        return 1;
    }

    Pixel screenbuffer[TOTAL_RES];

    SDL_Window*   sdl_window   = NULL;
    SDL_Renderer* sdl_renderer = NULL;
    SDL_Texture*  sdl_texture  = NULL;

    sdl_window = SDL_CreateWindow("Square", SDL_WINDOWPOS_CENTERED,
        SDL_WINDOWPOS_CENTERED, H_RES, V_RES, SDL_WINDOW_SHOWN);
    if (!sdl_window) {
        printf("Window creation failed: %s\n", SDL_GetError());
        return 1;
    }

    sdl_renderer = SDL_CreateRenderer(sdl_window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!sdl_renderer) {
        printf("Renderer creation failed: %s\n", SDL_GetError());
        return 1;
    }

    sdl_texture = SDL_CreateTexture(sdl_renderer, SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_TARGET, H_RES, V_RES);
    if (!sdl_texture) {
        printf("Texture creation failed: %s\n", SDL_GetError());
        return 1;
    }

    // reference SDL keyboard state array: https://wiki.libsdl.org/SDL_GetKeyboardState
    const Uint8 *keyb_state = SDL_GetKeyboardState(NULL);

    printf("Simulation running. Press 'Q' in simulation window to quit.\n\n");

    // initialize Verilog module
    Vtop* top = new Vtop;

    // // reset
    top->reset = 1;
    top->clk_pixel = 0;
    top->eval();
    top->clk_pixel = 1;
    top->eval();
    top->reset = 0;
    top->clk_pixel = 0;
    top->eval();

    // initialize frame rate
    uint64_t start_ticks = SDL_GetPerformanceCounter();
    uint64_t frame_count = 0;


    for (int i = 0; i < TOTAL_RES; ++i) {
        Pixel& p = screenbuffer[i];
        p.a = p.b = p.g = p.r = 0xFF;
    }

    // main loop
    int screenbuffer_write_index = 0;
    while (1) {
        // // cycle the clock
        top->clk_pixel = 1;
        top->eval();
        top->clk_pixel = 0;
        top->eval();

        // update events and window once per VSYNC (or on overflow)
        const bool vsync_just_started = (top->vsync && screenbuffer_write_index > 0);
        if (vsync_just_started || screenbuffer_write_index > TOTAL_RES)
        {
            // check for quit event
            SDL_Event e;
            if (SDL_PollEvent(&e)) {
                if (e.type == SDL_QUIT) {
                    break;
                }
            }
            if (keyb_state[SDL_SCANCODE_Q]) break;  // quit if user presses 'Q'

            top->btn_fire   = keyb_state[SDL_SCANCODE_SPACE];
            top->btn_up     = keyb_state[SDL_SCANCODE_UP];
            top->btn_down   = keyb_state[SDL_SCANCODE_DOWN];
            top->btn_left   = keyb_state[SDL_SCANCODE_LEFT];
            top->btn_right  = keyb_state[SDL_SCANCODE_RIGHT];
            top->btn_select = keyb_state[SDL_SCANCODE_RETURN];
            top->btn_reset  = keyb_state[SDL_SCANCODE_SPACE];

            SDL_UpdateTexture(sdl_texture, NULL, screenbuffer, H_RES*sizeof(Pixel));
            SDL_RenderClear(sdl_renderer);
            SDL_RenderCopy(sdl_renderer, sdl_texture, NULL, NULL);
            SDL_RenderPresent(sdl_renderer);
            frame_count++;
        }

        if (top->vsync || screenbuffer_write_index > TOTAL_RES) {
            // during VSYNC - don't write pixels, but reset writing pointer to 0
            screenbuffer_write_index = 0;
        } else if (screenbuffer_write_index < TOTAL_RES) {
            Pixel& p = screenbuffer[screenbuffer_write_index++];
            p.b = top->b;
            p.g = top->g;
            p.r = top->r;
            p.a = 0xFF;
        }        
    }

    // calculate frame rate
    uint64_t end_ticks = SDL_GetPerformanceCounter();
    double duration = ((double)(end_ticks-start_ticks))/SDL_GetPerformanceFrequency();
    double fps = (double)frame_count/duration;
    printf("Frames per second: %.1f\n", fps);

    top->final();  // simulation done

    SDL_DestroyTexture(sdl_texture);
    SDL_DestroyRenderer(sdl_renderer);
    SDL_DestroyWindow(sdl_window);
    SDL_Quit();
    return 0;
}