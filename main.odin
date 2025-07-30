package main

import "core:math"
import rl "vendor:raylib"

CELL_SIZE :: 64
MAP_WIDTH :: 400
MAP_HEIGHT :: 200
MARGIN :: 10

Ship :: struct {
    pos: rl.Vector2,
    v: rl.Vector2,
    a: f32,
}

EmptyTile :: struct {}

LandTile :: struct {}

Tile :: union {
    EmptyTile,
    LandTile,
}

TitleScreen :: struct {}

LevelEditor :: struct {
    current_tile: Tile,
    level_map: [MAP_HEIGHT][MAP_WIDTH]Tile,
}

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

    level_editor := LevelEditor{}
    level_editor.current_tile = EmptyTile{}
    for y in 0..<MAP_HEIGHT {
        for x in 0..<MAP_WIDTH {
            level_editor.level_map[y][x] = EmptyTile{}
        }
    }

    // Temporary
    level_editor.level_map[2][3] = LandTile{}

    game_state: GameState = level_editor

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        switch &s in game_state {
        case TitleScreen:
        case LevelEditor:
            draw_editor_grid()
            draw_editor_map(&level_editor)
        case Game:
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

draw_editor_grid :: proc() {
    for y in 0..<i32(100) {
        rl.DrawLine(MARGIN, MARGIN+y*CELL_SIZE, MARGIN+MAP_WIDTH*CELL_SIZE, MARGIN+y*CELL_SIZE, rl.GRAY)
    }

    for x in 0..<i32(100) {
        rl.DrawLine(MARGIN+x*CELL_SIZE, MARGIN, MARGIN+x*CELL_SIZE, MARGIN+MAP_HEIGHT*CELL_SIZE, rl.GRAY)
    }
}

draw_editor_map :: proc(editor: ^LevelEditor) {
    for y in 0..<i32(MAP_HEIGHT) {
        for x in 0..<i32(MAP_WIDTH) {
            switch tile in editor.level_map[y][x] {
            case EmptyTile:
            case LandTile:
                rl.DrawRectangle(MARGIN+x*CELL_SIZE, MARGIN+y*CELL_SIZE, CELL_SIZE, CELL_SIZE, rl.RED)
            }
        }
    }
}
