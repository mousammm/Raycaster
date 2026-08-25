#include <SDL2/SDL.h>
#include <math.h>
#include <stdbool.h>

#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480
#define MAP_WIDTH 8
#define MAP_HEIGHT 8
#define PI 3.1415926535f

int worldMap[MAP_HEIGHT][MAP_WIDTH] = {
    {1,1,1,1,1,1,1,1},
    {1,0,0,0,0,0,0,1},
    {1,0,1,1,0,1,0,1},
    {1,0,0,0,0,0,0,1},
    {1,0,0,0,0,1,0,1},
    {1,0,1,0,0,0,0,1},
    {1,0,0,0,0,0,0,1},
    {1,1,1,1,1,1,1,1}
};

int main(/*int argc, char* argv[]*/) {
    SDL_Init(SDL_INIT_VIDEO);
    SDL_Window* window = SDL_CreateWindow("Simple DDA Raycaster", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH, SCREEN_HEIGHT, 0);
    SDL_Renderer* renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

    // Player variables
    float posX = 3.5f, posY = 3.5f;  // Start position
    float dirX = -1.0f, dirY = 0.0f; // Direction vector
    float planeX = 0.0f, planeY = 0.66f; // Camera plane (determines FOV)

    bool running = true;
    Uint32 lastTime = SDL_GetTicks();

    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT) running = false;
            else if (event.type == SDL_KEYDOWN) { // key is pressed
              switch (event.key.keysym.sym) {
                case SDLK_ESCAPE:
                  running = false;
                  break;
              }
            }
        }

        Uint32 time = SDL_GetTicks();
        float frameTime = (time - lastTime) / 1000.0f;
        lastTime = time;

        float moveSpeed = frameTime * 4.0f; 
        float rotSpeed = frameTime * 3.0f;  

        const Uint8* state = SDL_GetKeyboardState(NULL);
        if (state[SDL_SCANCODE_W]) {
            if (worldMap[(int)posY][(int)(posX + dirX * moveSpeed)] == 0) posX += dirX * moveSpeed;
            if (worldMap[(int)(posY + dirY * moveSpeed)][(int)posX] == 0) posY += dirY * moveSpeed;
        }
        if (state[SDL_SCANCODE_S]) {
            if (worldMap[(int)posY][(int)(posX - dirX * moveSpeed)] == 0) posX -= dirX * moveSpeed;
            if (worldMap[(int)(posY - dirY * moveSpeed)][(int)posX] == 0) posY -= dirY * moveSpeed;
        }
        if (state[SDL_SCANCODE_D]) { // Rotate right
            float oldDirX = dirX;
            dirX = dirX * cosf(-rotSpeed) - dirY * sinf(-rotSpeed);
            dirY = oldDirX * sinf(-rotSpeed) + dirY * cosf(-rotSpeed);
            float oldPlaneX = planeX;
            planeX = planeX * cosf(-rotSpeed) - planeY * sinf(-rotSpeed);
            planeY = oldPlaneX * sinf(-rotSpeed) + planeY * cosf(-rotSpeed);
        }
        if (state[SDL_SCANCODE_A]) { // Rotate left
            float oldDirX = dirX;
            dirX = dirX * cosf(rotSpeed) - dirY * sinf(rotSpeed);
            dirY = oldDirX * sinf(rotSpeed) + dirY * cosf(rotSpeed);
            float oldPlaneX = planeX;
            planeX = planeX * cosf(rotSpeed) - planeY * sinf(rotSpeed);
            planeY = oldPlaneX * sinf(rotSpeed) + planeY * cosf(rotSpeed);
        }

        // background
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        // Raycasting loop
        for (int x = 0; x < SCREEN_WIDTH; x++) {
            // Calculate ray position and direction
            float cameraX = 2.0f * (float)x / (float)SCREEN_WIDTH - 1.0f;
            float rayDirX = dirX + planeX * cameraX;
            float rayDirY = dirY + planeY * cameraX;

            // Which grid cell we are in
            int mapX = (int)posX;
            int mapY = (int)posY;

            // Length of ray from one grid line to next
            float deltaDistX = (rayDirX == 0) ? 1e30f : fabsf(1.0f / rayDirX);
            float deltaDistY = (rayDirY == 0) ? 1e30f : fabsf(1.0f / rayDirY);

            float sideDistX, sideDistY;
            int stepX, stepY;
            int hit = 0; 
            int side; // 0 for X-side, 1 for Y-side

            // Calculate step and initial sideDist
            if (rayDirX < 0) {
                stepX = -1;
                sideDistX = (posX - mapX) * deltaDistX;
            } else {
                stepX = 1;
                sideDistX = (mapX + 1.0f - posX) * deltaDistX;
            }
            if (rayDirY < 0) {
                stepY = -1;
                sideDistY = (posY - mapY) * deltaDistY;
            } else {
                stepY = 1;
                sideDistY = (mapY + 1.0f - posY) * deltaDistY;
            }

            // Perform DDA
            while (hit == 0) {
                if (sideDistX < sideDistY) {
                    sideDistX += deltaDistX;
                    mapX += stepX;
                    side = 0;
                } else {
                    sideDistY += deltaDistY;
                    mapY += stepY;
                    side = 1;
                }
                if (worldMap[mapY][mapX] > 0) hit = 1;
            }

            // Calculate distance projected on camera direction (prevents fisheye)
            float perpWallDist;
            if (side == 0) perpWallDist = (sideDistX - deltaDistX);
            else           perpWallDist = (sideDistY - deltaDistY);

            // Calculate height of line to draw on screen
            int lineHeight = (int)(SCREEN_HEIGHT / perpWallDist);

            // Calculate lowest and highest pixel to fill in current stripe
            int drawStart = -lineHeight / 2 + SCREEN_HEIGHT / 2;
            if (drawStart < 0) drawStart = 0;
            int drawEnd = lineHeight / 2 + SCREEN_HEIGHT / 2;
            if (drawEnd >= SCREEN_HEIGHT) drawEnd = SCREEN_HEIGHT - 1;

            // Give walls different colors based on orientation
            if (side == 1) {
                SDL_SetRenderDrawColor(renderer, 150, 0, 0, 255); // Darker red for Y walls
            } else {
                SDL_SetRenderDrawColor(renderer, 200, 0, 0, 255); // Brighter red for X walls
            }

            // Draw the vertical wall stripe
            SDL_RenderDrawLine(renderer, x, drawStart, x, drawEnd);
        }

        SDL_RenderPresent(renderer);
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
