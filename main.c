#define RGFW_IMPLEMENTATION
#include "RGFW.h"

#define WIDTH 640
#define HEIGHT 480

void drawPixel(u8* buffer, i32 bufferWidth, i32 x, i32 y, u8 color[4]) {
    if (x < 0 || x >= WIDTH || y < 0 || y >= HEIGHT) return;
    u32 index = ((u32)y * (4 * (u32)bufferWidth)) + (u32)x * 4;
    memcpy(&buffer[index], color, 4 * sizeof(u8));
}

int main(void) {
    RGFW_init("Raycaster", 0);
    RGFW_window* win = RGFW_createWindow("Raycaster", 0, 0, WIDTH, HEIGHT, RGFW_windowCenter | RGFW_windowNoResize /*| RGFW_windowTranslucent | RGFW_windowNoBorder*/ );
    RGFW_window_setExitKey(win, RGFW_keyEscape);

    u8* buffer = (u8*)RGFW_ALLOC((u32)(WIDTH * HEIGHT * 4));
    RGFW_surface* surface = RGFW_createSurface(buffer, WIDTH, HEIGHT, RGFW_formatRGBA8);

    u8 clearColor[4] = {0, 0, 0, 255};
    u8 pixelColor[4] = {0xFF, 0, 0, 255};

    while (RGFW_window_shouldClose(win) == RGFW_FALSE) {
        RGFW_pollEvents();

        memset(buffer, clearColor[0], (u32)WIDTH * (u32)HEIGHT * 4 * sizeof(u8));

        for (int i = 0; i < 300; i++) {
            drawPixel(buffer, WIDTH, 100 + i, 100 + i, pixelColor);
            drawPixel(buffer, WIDTH, HEIGHT - i, 100 + i, pixelColor);
        }

        RGFW_window_blitSurface(win, surface);
    }

    RGFW_surface_free(surface);
    RGFW_FREE(buffer);
    RGFW_window_close(win);
    RGFW_deinit();

    return 0;
}
