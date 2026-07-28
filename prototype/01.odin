package main
// Basic Raycaster with STEPING
// Fish Eye Fix

import "core:math"
import rl "vendor:raylib"

WIDTH      :: 640
HEIGHT     :: 480
HALF_HEIGHT:: HEIGHT / 2

MOVE_SPEED :: 7.0
ROT_SPEED  :: 5.0
STEP_SIZE  :: 0.05

FOV_RAD    :: 60.0 * (math.PI / 180.0)
HALF_FOV   :: FOV_RAD / 2.0

MAP_W, MAP_H :: 8, 8
MAP := [MAP_W * MAP_H]i32{
    1,1,1,1,1,1,1,1,
    1,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,1,
    1,0,0,1,0,0,0,1,
    1,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,1,
    1,1,1,1,1,1,1,1,
}

PX, PY, PA : f32 = 2.0, 2.0, 0.0

main :: proc() {
    rl.InitWindow(WIDTH, HEIGHT, "Raycaster");
    rl.SetTargetFPS(100);

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        
        if rl.IsKeyDown(.A) do PA -= ROT_SPEED * dt
        if rl.IsKeyDown(.D) do PA += ROT_SPEED * dt
        if rl.IsKeyDown(.W) { PX += math.cos(PA) * MOVE_SPEED * dt; PY += math.sin(PA) * MOVE_SPEED * dt }
        if rl.IsKeyDown(.S) { PX -= math.cos(PA) * MOVE_SPEED * dt; PY -= math.sin(PA) * MOVE_SPEED * dt }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        for x: i32 = 0; x < WIDTH; x += 1 {
            angle := (PA - HALF_FOV) + (f32(x) / f32(WIDTH)) * FOV_RAD
            dist: f32 = 0.0

            for MAP[i32(PY + math.sin(angle) * dist) * MAP_W + i32(PX + math.cos(angle) * dist)] == 0 {
                dist += STEP_SIZE
            }

            h := i32(f32(HEIGHT) / dist) // fish eye
            // h := i32(f32(HEIGHT) / (dist * math.cos(angle - PA))) // fish eye fix
            if h > HEIGHT do h = HEIGHT
            
            rl.DrawLine(x, HALF_HEIGHT - h/2, x, HALF_HEIGHT + h/2, rl.RED)
        }

        // map START
        rl.DrawRectangle(0, 0, MAP_W*MAP_H, MAP_W*MAP_H, {00,00,0xFF,0xFF})
        for y in 0..<MAP_H {
            for x in 0..<MAP_W {
                if MAP[y*MAP_W + x] == 1 {
                    rl.DrawRectangle(i32(x*8), i32(y*8), 8, 8, {00,0xd3,00,0x70})
                }
            }
        }
        rl.DrawRectangle(i32(PX*8), i32(PY*8), 3, 3, rl.BLACK)
        // map END

        rl.EndDrawing()
    }
    rl.CloseWindow();
}
