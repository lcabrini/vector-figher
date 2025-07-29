package main

import "core:math"
import rl "vendor:raylib"

Ship :: struct {
    pos: rl.Vector2,
    v: rl.Vector2,
    a: f32,
}

main :: proc() {
    rl.SetTraceLogLevel(.ERROR)
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(1024, 768, "Vector Fighter")
    rl.SetTargetFPS(60)

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        rl.EndDrawing()
    }

    rl.CloseWindow()
}
