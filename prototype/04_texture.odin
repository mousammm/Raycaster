package main

import "core:math"
import rl "vendor:raylib"

WIDTH      :: 16*50
HEIGHT     ::  9*50
HALF_HEIGHT:: HEIGHT / 2

MOVE_SPEED :: 4.0
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

// --- TEXTURE CONSTANTS ---
TEX_W :: 8
TEX_H :: 8
// An 8x8 grid acting as our custom brick wall texture pattern
TEX_DATA := [TEX_W * TEX_H]i32{
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    1,1,0,0,1,1,0,0,
    0,0,1,1,0,0,1,1,
    0,0,1,1,0,0,1,1,
    0,0,1,1,0,0,1,1,
    0,0,1,1,0,0,1,1,
}

PX, PY, PA : f32 = 2.0, 2.0, 0.0

main :: proc() {
    rl.InitWindow(WIDTH, HEIGHT, "Raycaster Texture Test")
    rl.SetTargetFPS(100)

    for !rl.WindowShouldClose() {
        dt := rl.GetFrameTime()
        
        if rl.IsKeyDown(.A) do PA -= ROT_SPEED * dt
        if rl.IsKeyDown(.D) do PA += ROT_SPEED * dt
        
        BUFFER : f32 = 0.2 

        if rl.IsKeyDown(.W) { 
            move_x := math.cos(PA) * MOVE_SPEED * dt
            move_y := math.sin(PA) * MOVE_SPEED * dt
            buffer_x := (move_x > 0) ? BUFFER : -BUFFER
            buffer_y := (move_y > 0) ? BUFFER : -BUFFER
            if MAP[i32(PY) * MAP_W + i32(PX + move_x + buffer_x)] == 0 do PX += move_x
            if MAP[i32(PY + move_y + buffer_y) * MAP_W + i32(PX)] == 0 do PY += move_y
        }
        if rl.IsKeyDown(.S) { 
            move_x := math.cos(PA) * MOVE_SPEED * dt
            move_y := math.sin(PA) * MOVE_SPEED * dt
            buffer_x := (move_x > 0) ? -BUFFER : BUFFER
            buffer_y := (move_y > 0) ? -BUFFER : BUFFER
            if MAP[i32(PY) * MAP_W + i32(PX - move_x + buffer_x)] == 0 do PX -= move_x
            if MAP[i32(PY - move_y + buffer_y) * MAP_W + i32(PX)] == 0 do PY -= move_y
        }
        if rl.IsKeyDown(.E) {
            strafe_angle : f32 = PA + (math.PI / 2.0)
            move_x := math.cos(strafe_angle) * MOVE_SPEED * dt
            move_y := math.sin(strafe_angle) * MOVE_SPEED * dt
            buffer_x := (move_x > 0) ? BUFFER : -BUFFER
            buffer_y := (move_y > 0) ? BUFFER : -BUFFER
            if MAP[i32(PY) * MAP_W + i32(PX + move_x + buffer_x)] == 0 do PX += move_x
            if MAP[i32(PY + move_y + buffer_y) * MAP_W + i32(PX)] == 0 do PY += move_y
        }
        if rl.IsKeyDown(.Q) {
            strafe_angle : f32 = PA - (math.PI / 2.0)
            move_x := math.cos(strafe_angle) * MOVE_SPEED * dt
            move_y := math.sin(strafe_angle) * MOVE_SPEED * dt
            buffer_x := (move_x > 0) ? BUFFER : -BUFFER
            buffer_y := (move_y > 0) ? BUFFER : -BUFFER
            if MAP[i32(PY) * MAP_W + i32(PX + move_x + buffer_x)] == 0 do PX += move_x
            if MAP[i32(PY + move_y + buffer_y) * MAP_W + i32(PX)] == 0 do PY += move_y
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

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
            for MAP[map_y * MAP_W + map_x] == 0 {
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
            if perp_wall_dist < 0.01 do perp_wall_dist = 0.01 

            h := i32(f32(HEIGHT) / perp_wall_dist)

            // --- TEXTURE MAPPING LOGIC ---
            // Calculate where exactly the ray hit the wall block horizontally (0.0 to 1.0)
            wall_hit_x: f32 = 0.0
            if side_hit == 0 {
                wall_hit_x = PY + perp_wall_dist * ray_dir_y
            } else {
                wall_hit_x = PX + perp_wall_dist * ray_dir_x
            }
            wall_hit_x -= math.floor(wall_hit_x) // Keep only the decimal part

            // Convert that 0.0->1.0 percentage into an integer pixel column index on our texture
            tex_x := i32(wall_hit_x * f32(TEX_W))
            if side_hit == 0 && ray_dir_x > 0 do tex_x = TEX_W - 1 - tex_x
            if side_hit == 1 && ray_dir_y < 0 do tex_x = TEX_W - 1 - tex_x

            // Calculate screen bounds for drawing our vertical column slice
            draw_start := HALF_HEIGHT - h/2
            draw_end := HALF_HEIGHT + h/2

            // Instead of drawing 1 big solid line, we loop vertically from top to bottom
            // drawing small pixel segments that scale with the texture row coordinates!
            for y := draw_start; y < draw_end; y += 1 {
                // If the coordinate stretches past the monitor bounds, skip it
                if y < 0 || y >= HEIGHT do continue

                // Map current screen Y pixel position to its corresponding texture row Y coordinate
                d := y * 256 - HEIGHT * 128 + h * 128 // Fixed-point conversion value avoiding floating-point precision flaws
                tex_y := ((d * TEX_H) / h) / 256
                if tex_y < 0 do tex_y = 0
                if tex_y >= TEX_H do tex_y = TEX_H - 1

                // Fetch the brick pixel bit from the flat 1D texture array
                tex_pixel := TEX_DATA[tex_y * TEX_W + tex_x]

                // Choose color palette based on array bit value and shadow depth (side_hit)
                color := rl.BLACK
                if tex_pixel == 1 {
                    color = (side_hit == 1) ? rl.Color{20, 20, 20, 255} : rl.BLACK // Darker red vs normal red brick
                } else {
                    color = (side_hit == 1) ? rl.Color{255, 0, 0, 255} : rl.Color{100, 0, 0, 255} // Mortar lines
                }

                rl.DrawPixel(x, y, color)
            }
            // -----------------------------
        }

        // weapon code stays here before EndDrawing...
        rl.EndDrawing()
    }
    rl.CloseWindow()
}
