package main

// sliding collision

import "core:math"
import rl "vendor:raylib"

WIDTH      :: 640
HEIGHT     :: 480
HALF_HEIGHT:: HEIGHT / 2

MOVE_SPEED :: 3.0
ROT_SPEED  :: 2.0

FOV_RAD    :: 60.0 * (math.PI / 180.0)
HALF_FOV   :: FOV_RAD / 2.0

MAP_W, MAP_H :: 8, 8
MAP := [MAP_W * MAP_H]i32{
    1,1,1,1,1,1,1,1,
    1,0,0,1,0,0,0,1,
    1,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,1,
    1,0,0,0,0,0,0,1,
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

        BUFFER : f32 : 0.2 

        if rl.IsKeyDown(.W) { 
            move_x := math.cos(PA) * MOVE_SPEED * dt
            move_y := math.sin(PA) * MOVE_SPEED * dt

            // Calculate a slight forward buffer in the direction of movement
            buffer_x := (move_x > 0) ? BUFFER : -BUFFER
            buffer_y := (move_y > 0) ? BUFFER : -BUFFER

            // Slide on X-axis: only move X if the future X tile is empty space (0)
            if MAP[i32(PY) * MAP_W + i32(PX + move_x + buffer_x)] == 0 {
                PX += move_x
            }
            // Slide on Y-axis: only move Y if the future Y tile is empty space (0)
            if MAP[i32(PY + move_y + buffer_y) * MAP_W + i32(PX)] == 0 {
                PY += move_y
            }
        }
        
        if rl.IsKeyDown(.S) { 
            move_x := math.cos(PA) * MOVE_SPEED * dt
            move_y := math.sin(PA) * MOVE_SPEED * dt

            // Moving backward means the buffer points opposite to your gaze direction
            buffer_x := (move_x > 0) ? -BUFFER : BUFFER
            buffer_y := (move_y > 0) ? -BUFFER : BUFFER

            // Slide on X-axis backward
            if MAP[i32(PY) * MAP_W + i32(PX - move_x + buffer_x)] == 0 {
                PX -= move_x
            }
            // Slide on Y-axis backward
            if MAP[i32(PY - move_y + buffer_y) * MAP_W + i32(PX)] == 0 {
                PY -= move_y
            }
        }
        // -----------------------------


        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        for x: i32 = 0; x < WIDTH; x += 1 {
            angle := (PA - HALF_FOV) + (f32(x) / f32(WIDTH)) * FOV_RAD
            
            // Ray direction vectors
            ray_dir_x := math.cos(angle)
            ray_dir_y := math.sin(angle)

            // Distance the ray has to travel to go from 1 vertical/horizontal grid line to the next
            // Handled carefully to prevent division-by-zero if running parallel to an axis
            delta_dist_x := (ray_dir_x == 0) ? 1e30 : math.abs(1.0 / ray_dir_x)
            delta_dist_y := (ray_dir_y == 0) ? 1e30 : math.abs(1.0 / ray_dir_y)

            // Length of ray from current position to next grid line
            side_dist_x: f32 = 0.0
            side_dist_y: f32 = 0.0

            // What direction to step in the map grid (-1 or +1)
            step_x: i32 = 0
            step_y: i32 = 0

            // Current integer square of the map the player is in
            map_x := i32(PX)
            map_y := i32(PY)

            // Calculate step and initial side_dist
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

            // The DDA Jump Loop
            side_hit: i32 = 0 // 0 for vertical wall (X-axis grid line), 1 for horizontal wall (Y-axis grid line)
            for MAP[map_y * MAP_W + map_x] == 0 {
                // Jump to the next closest grid line (either X line or Y line)
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

            // Calculate the perfect perpendicular distance to the wall (automatically fixes fish-eye!)
            perp_wall_dist: f32 = 0.0
            if side_hit == 0 {
                perp_wall_dist = side_dist_x - delta_dist_x
            } else {
                perp_wall_dist = side_dist_y - delta_dist_y
            }
            if perp_wall_dist < 0.01 do perp_wall_dist = 0.01

            // draw the walls
            h := i32(f32(HEIGHT) / perp_wall_dist)
            wall_color := (side_hit == 1) ? rl.Color{80, 0, 0, 255} : rl.RED
            rl.DrawLine(x, HALF_HEIGHT - h/2, x, HALF_HEIGHT + h/2, wall_color)
        }

        rl.EndDrawing()
    }
    rl.CloseWindow()
}
