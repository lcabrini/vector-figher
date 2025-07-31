package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

CELL_SIZE :: 64
MAP_WIDTH :: 400
MAP_HEIGHT :: 200
MARGIN :: 10
TOOL_SIZE :: 30

Settings :: struct {
    screen_width: i32,
    screen_height: i32,
}

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
    camera: rl.Camera2D,
}

Game :: struct {}

GameState :: union {
    TitleScreen,
    LevelEditor,
    Game,
}

main :: proc() {
    settings := Settings{
        screen_width = 1024,
        screen_height = 768,
    }

    rl.SetTraceLogLevel(.ERROR)
    rl.SetConfigFlags({.VSYNC_HINT})
    rl.InitWindow(settings.screen_width, settings.screen_height, "Vector Fighter")
    rl.SetTargetFPS(60)

    level_editor := LevelEditor{}
    level_editor.current_tile = EmptyTile{}
    level_editor.camera = rl.Camera2D{}
    level_editor.camera.zoom = 1
    level_editor.camera.offset = {0, 0}
    level_editor.camera.target = {0, 0}
    for y in 0..<MAP_HEIGHT {
        for x in 0..<MAP_WIDTH {
            level_editor.level_map[y][x] = EmptyTile{}
        }
    }

    // Temporary
    level_editor.level_map[2][3] = LandTile{}

    game_state: GameState = level_editor

    for !rl.WindowShouldClose() {
        switch &s in game_state {
        case TitleScreen:
        case LevelEditor:
            if rl.IsKeyDown(.UP) {
                level_editor.camera.offset.y -= 0.5
                level_editor.camera.target.y -= CELL_SIZE/2
            }

            if rl.IsKeyDown(.DOWN) {
                level_editor.camera.offset.y += 0.5
                level_editor.camera.target.y += CELL_SIZE/2
            }

            if rl.IsKeyDown(.LEFT) {
                level_editor.camera.offset.x -= 0.5
                level_editor.camera.target.x -= CELL_SIZE/2
            }

            if rl.IsKeyDown(.RIGHT) {
                level_editor.camera.offset.x += 0.5
                level_editor.camera.target.x += CELL_SIZE/2
            }

            if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
                mp := rl.GetMousePosition()
                if mp.x > f32(settings.screen_width-TOOL_SIZE*2+4) {
                    select_tool(&level_editor, &settings)
                } else {
                    cell_x := int(level_editor.camera.offset.x + mp.x / CELL_SIZE)
                    cell_y := int(level_editor.camera.offset.y + mp.y / CELL_SIZE)
                    level_editor.level_map[cell_y][cell_x] = level_editor.current_tile
                }
            }
        case Game:
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        switch &s in game_state {
        case TitleScreen:
        case LevelEditor:
            rl.BeginMode2D(level_editor.camera)
            draw_editor_grid()
            draw_editor_map(&level_editor)
            rl.EndMode2D()
            draw_editor_toolbox(&level_editor, &settings)
        case Game:
        }

        rl.EndDrawing()
    }

    rl.CloseWindow()
}

draw_editor_grid :: proc() {
    for y in 0..=i32(MAP_HEIGHT) {
        rl.DrawLine(MARGIN, MARGIN+y*CELL_SIZE, MARGIN+MAP_WIDTH*CELL_SIZE, MARGIN+y*CELL_SIZE, rl.GRAY)
    }

    for x in 0..=i32(MAP_WIDTH) {
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

draw_editor_toolbox :: proc(editor: ^LevelEditor, settings: ^Settings) {
    rl.DrawRectangleLines(settings.screen_width-TOOL_SIZE*2-4, 0, TOOL_SIZE*2+4, settings.screen_height-1, rl.WHITE )
    rl.DrawRectangle(settings.screen_width-TOOL_SIZE*2-3, 1, TOOL_SIZE*2+2, settings.screen_height-2, rl.BLUE)
    rl.DrawLine(settings.screen_width-TOOL_SIZE-2, 0, settings.screen_width-TOOL_SIZE-2, settings.screen_height, rl.WHITE)
    for y: i32 = 1; y < settings.screen_height-1; y += TOOL_SIZE {
        rl.DrawLine(settings.screen_width-TOOL_SIZE*2-3, y, settings.screen_width-1, y, rl.WHITE)
    }
}

select_tool :: proc(editor: ^LevelEditor, settings: ^Settings) {
    mp := rl.GetMousePosition()
    x := 1 - (settings.screen_width - i32(mp.x)) / TOOL_SIZE
    y := i32(mp.y) / TOOL_SIZE
    tool: [2]i32 = {x, y}

    switch tool {
        case {0, 0}: editor.current_tile = EmptyTile{}
        case {1, 0}: editor.current_tile = LandTile{}
    }
}
