package main
// DDA
// Fish eye fix
// walls with Y-facing give a darker shader

import "core:math"
import rl "vendor:raylib"

WIDTH       :: 1000
HEIGHT      :: 1000
HALF_HEIGHT :: HEIGHT / 2

MOVE_SPEED  :: 3.0
ROT_SPEED   :: 2.0

FOV_RAD     :: 60.0 * (math.PI / 180.0)
HALF_FOV    :: FOV_RAD / 2.0

MAP_W, MAP_H :: 8, 8
MAP := [MAP_W * MAP_H]i32{
    1,1,1,1,1,1,1,1,
    1,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,1,
    1,0,0,1,1,0,0,1,
    1,0,0,1,1,0,0,1,
    1,0,0,0,0,0,0,1,
    1,0,0,0,0,1,0,1,
    1,1,1,1,1,1,1,1,
}

PX, PY, PA : f32 = 2.0, 2.0, 0.0

main :: proc() {
    rl.InitWindow(WIDTH, HEIGHT, "Raycaster")
    rl.SetTargetFPS(100)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        
        if rl.IsKeyDown(.A) do PA -= ROT_SPEED * dt
        if rl.IsKeyDown(.D) do PA += ROT_SPEED * dt
        if rl.IsKeyDown(.W) { PX += math.cos(PA) * MOVE_SPEED * dt; PY += math.sin(PA) * MOVE_SPEED * dt }
        if rl.IsKeyDown(.S) { PX -= math.cos(PA) * MOVE_SPEED * dt; PY -= math.sin(PA) * MOVE_SPEED * dt }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        // Render Ceiling and Floor backgrounds first
        rl.DrawRectangle(0, 0, WIDTH, HALF_HEIGHT, rl.Color{40, 40, 40, 255})
        rl.DrawRectangle(0, HALF_HEIGHT, WIDTH, HALF_HEIGHT, rl.Color{80, 80, 80, 255})

        for x: i32 = 0; x < WIDTH; x += 1 {
            angle := (PA - HALF_FOV) + (f32(x) / f32(WIDTH)) * FOV_RAD
            
            ray_dir_x := math.cos(angle)
            ray_dir_y := math.sin(angle)

            delta_dist_x := (ray_dir_x == 0) ? 1e30 : math.abs(1.0 / ray_dir_x)
            delta_dist_y := (ray_dir_y == 0) ? 1e30 : math.abs(1.0 / ray_dir_y)

            side_dist_x: f32 = 0.0
            side_dist_y: f32 = 0.0
            step_x: i32 = 0
            step_y: i32 = 0

            map_x := i32(PX)
            map_y := i32(PY)

            if ray_dir_x < 0 {
                step_x = -1
                side_dist_x = (PX - f32(map_x)) * delta_dist_x
            } else {
                step_x = 1
                side_dist_x = (f32(map_x) + 1.0 - PX) * delta_dist_x
            }

            if ray_dir_y < 0 {
                step_y = -1
                side_dist_y = (PY - f32(map_y)) * delta_dist_y
            } else {
                step_y = 1
                side_dist_y = (f32(map_y) + 1.0 - PY) * delta_dist_y
            }

            side_hit: i32 = 0 
            
            // Boundary checks added to prevent array out-of-bounds crashes
            for map_x >= 0 && map_x < MAP_W && map_y >= 0 && map_y < MAP_H && MAP[map_y * MAP_W + map_x] == 0 {
                if side_dist_x < side_dist_y {
                    side_dist_x += delta_dist_x
                    map_x += step_x
                    side_hit = 0
                } else {
                    side_dist_y += delta_dist_y
                    map_y += step_y
                    side_hit = 1
                }
            }

            perp_wall_dist: f32 = 0.0
            if side_hit == 0 {
                perp_wall_dist = side_dist_x - delta_dist_x
            } else {
                perp_wall_dist = side_dist_y - delta_dist_y
            }
            
            // FIX FISHEYE: Correct the distance using the relative angle to the player's view center
            perp_wall_dist *= math.cos(angle - PA)
            
            if perp_wall_dist < 0.01 do perp_wall_dist = 0.01

            h := i32(f32(HEIGHT) / perp_wall_dist)
            
            // Clamp rendering boundaries so lines don't wrap or cause glitches
            draw_start := HALF_HEIGHT - h / 2
            draw_end := HALF_HEIGHT + h / 2
            if draw_start < 0 do draw_start = 0
            if draw_end >= HEIGHT do draw_end = HEIGHT - 1

            wall_color := (side_hit == 1) ? rl.Color{150, 0, 0, 255} : rl.RED
            rl.DrawLine(x, draw_start, x, draw_end, wall_color)
        }

        rl.EndDrawing()
    }
    rl.CloseWindow()
}
