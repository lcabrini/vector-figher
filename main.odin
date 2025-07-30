package main

import "core:math"
import rl "vendor:raylib"

CELL_SIZE :: 20
MAP_WIDTH :: 1000
MAP_HEIGHT :: 1000

Ship :: struct {
    pos: rl.Vector2,
    v: rl.Vector2,
    a: f32,
}

TitleScreen :: struct {}

LevelEditor :: struct {}

Game :: struct {}

GameState :: union {
    TitleScreen,
    LevelEditor,
    Game,
}

main :: proc() {
    rl.SetTraceLogLevel(.ERROR)
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(1024, 768, "Vector Fighter")
    rl.SetTargetFPS(60)

    game_state: GameState = LevelEditor{}

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        switch &s in game_state {
        case TitleScreen:
        case LevelEditor:
            draw_editor_grid()
        case Game:
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

draw_editor_grid :: proc() {
    for y in 0..<i32(100) {
        rl.DrawLine(10, 10+y*CELL_SIZE, 10+MAP_WIDTH*CELL_SIZE, 10+y*CELL_SIZE, rl.GRAY)
    }

    for x in 0..<i32(100) {
        rl.DrawLine(10+x*CELL_SIZE, 10, 10+x*CELL_SIZE, 10+MAP_HEIGHT*CELL_SIZE, rl.GRAY)
    }
}
