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

ShipTile :: struct {}
EmptyTile :: struct {}
LandTile :: struct {}
NWTriangleTile :: struct {}
NETriangleTile :: struct {}
SWTriangleTile :: struct {}
SETriangleTile :: struct {}

TopCannonTile :: struct {
    angle: f32,
}

BottomCannonTile :: struct {
    angle: f32,
}

Tile :: union {
    EmptyTile,
    ShipTile,
    LandTile,
    NWTriangleTile,
    NETriangleTile,
    SWTriangleTile,
    SETriangleTile,
    TopCannonTile,
    BottomCannonTile,
}

TitleScreen :: struct {}

LevelEditor :: struct {
    toolbox: [25][2]Tile,
    current_tool: Tile,
    level_map: [][]Tile,
    camera: rl.Camera2D,
    ship_placed: bool,
    active_tile: [2]i32,
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
    level_editor.level_map = make([][]Tile, MAP_HEIGHT)
    for y in 0..<MAP_HEIGHT {
        level_editor.level_map[y] = make([]Tile, MAP_WIDTH)
    }

    init_toolbox(&level_editor)
    level_editor.current_tool = EmptyTile{}
    level_editor.camera = rl.Camera2D{}
    level_editor.camera.zoom = 1
    level_editor.camera.offset = {0, 0}
    level_editor.camera.target = {0, 0}
    for y in 0..<MAP_HEIGHT {
        for x in 0..<MAP_WIDTH {
            level_editor.level_map[y][x] = EmptyTile{}
        }
    }

    game_state: GameState = level_editor

    for !rl.WindowShouldClose() {
        switch &s in game_state {
        case TitleScreen:
        case LevelEditor:
            {
                mp := rl.GetMousePosition()
                if mp.x <= f32(settings.screen_width-TOOL_SIZE*2+4) {
                    cell_x := i32(level_editor.camera.target.x + mp.x) / (CELL_SIZE+1)
                    cell_y := i32(level_editor.camera.target.y + mp.y) / (CELL_SIZE+1)
                    level_editor.active_tile = {cell_x, cell_y}
                }
            }

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

            if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
                mp := rl.GetMousePosition()
                if mp.x > f32(settings.screen_width-TOOL_SIZE*2+4) {
                    select_tool(&level_editor, &settings)
                } else {
                    cell_x := int(level_editor.camera.target.x + mp.x) / (CELL_SIZE+1)
                    cell_y := int(level_editor.camera.target.y + mp.y) / (CELL_SIZE+1)
                    switch tile in level_editor.current_tool {
                    case ShipTile:
                    case TopCannonTile:
                        level_editor.level_map[cell_y][cell_x] = TopCannonTile{}
                    case BottomCannonTile:
                        level_editor.level_map[cell_y][cell_x] = BottomCannonTile{}
                    case EmptyTile: level_editor.level_map[cell_y][cell_x] = level_editor.current_tool
                    case LandTile: level_editor.level_map[cell_y][cell_x] = level_editor.current_tool
                    case NWTriangleTile: level_editor.level_map[cell_y][cell_x] = level_editor.current_tool
                    case NETriangleTile: level_editor.level_map[cell_y][cell_x] = level_editor.current_tool
                    case SWTriangleTile: level_editor.level_map[cell_y][cell_x] = level_editor.current_tool
                    case SETriangleTile: level_editor.level_map[cell_y][cell_x] = level_editor.current_tool
                    }
                }
            }

            if rl.IsMouseButtonDown(rl.MouseButton.RIGHT) {
                mp := rl.GetMousePosition()
                if mp.x <= f32(settings.screen_width-TOOL_SIZE*2+4) {
                    cell_x := int(level_editor.camera.offset.x + mp.x / CELL_SIZE)
                    cell_y := int(level_editor.camera.offset.y + mp.y / CELL_SIZE)
                    level_editor.level_map[cell_y][cell_x] = EmptyTile{}
                }
            }
        case Game:
        }

        switch &s in game_state {
        case TitleScreen:
        case LevelEditor:
            for y in 0..<MAP_HEIGHT do for x in 0..<MAP_WIDTH {
                #partial switch &tile in level_editor.level_map[y][x] {
                    case TopCannonTile:
                        ox := level_editor.camera.target.x
                        oy := level_editor.camera.target.y
                        mp := rl.GetMousePosition() + {ox, oy}
                        cx := f32(MARGIN+x*CELL_SIZE) + CELL_SIZE/2
                        cy := f32(MARGIN+y*CELL_SIZE) + CELL_SIZE/4
                        tile.angle = math.atan2(mp.y-cy, mp.x-cx)
                        if tile.angle < 0 do tile.angle = cx < mp.x ? 0 : math.PI
                    case BottomCannonTile:
                        ox := level_editor.camera.target.x
                        oy := level_editor.camera.target.y
                        mp := rl.GetMousePosition() + {ox, oy}
                        cx := f32(MARGIN+x*CELL_SIZE) + CELL_SIZE/2
                        cy := f32(MARGIN+y*CELL_SIZE) + 3*CELL_SIZE/4
                        tile.angle = math.atan2(cy-mp.y, mp.x-cx)
                        if tile.angle < 0 do tile.angle = cx < mp.x ? 0 : math.PI
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
    for y in 0..<i32(MAP_HEIGHT) do for x in 0..<i32(MAP_WIDTH) {
        switch &tile in editor.level_map[y][x] {
        case ShipTile:
        case EmptyTile:
        case LandTile:
            rl.DrawRectangle(MARGIN+x*CELL_SIZE, MARGIN+y*CELL_SIZE, CELL_SIZE, CELL_SIZE, rl.RED)
        case NWTriangleTile:
            x1 := f32(MARGIN+x*CELL_SIZE)
            y1 := f32(MARGIN+y*CELL_SIZE)
            x2 := x1
            y2 := y1+CELL_SIZE
            x3 := x1+CELL_SIZE
            y3 := y1
            rl.DrawTriangle({x1, y1}, {x2, y2}, {x3, y3}, rl.RED)
        case NETriangleTile:
            x1 := f32(MARGIN+x*CELL_SIZE)
            y1 := f32(MARGIN+y*CELL_SIZE)
            x2 := x1+CELL_SIZE
            y2 := y1+CELL_SIZE
            x3 := x1+CELL_SIZE
            y3 := y1
            rl.DrawTriangle({x1, y1}, {x2, y2}, {x3, y3}, rl.RED)
        case SWTriangleTile:
            x1 := f32(MARGIN+x*CELL_SIZE)
            y1 := f32(MARGIN+y*CELL_SIZE)
            x2 := x1
            y2 := y1+CELL_SIZE
            x3 := x1+CELL_SIZE
            y3 := y2
            rl.DrawTriangle({x1, y1}, {x2, y2}, {x3, y3}, rl.RED)
        case SETriangleTile:
            x1 := f32(MARGIN+x*CELL_SIZE) + CELL_SIZE
            y1 := f32(MARGIN+y*CELL_SIZE)
            x2 := x1-CELL_SIZE
            y2 := y1+CELL_SIZE
            x3 := x1
            y3 := y2
            rl.DrawTriangle({x1, y1}, {x2, y2}, {x3, y3}, rl.RED)
        case TopCannonTile:
            rx := f32(MARGIN+x*CELL_SIZE) + CELL_SIZE/4
            ry := f32(MARGIN+y*CELL_SIZE)
            rw := f32(CELL_SIZE/2)
            rh := f32(CELL_SIZE/4)
            rl.DrawRectangleRec({rx, ry, rw, rh}, rl.BLUE)
            cx := f32(MARGIN+x*CELL_SIZE) + CELL_SIZE/2
            cy := f32(MARGIN+y*CELL_SIZE) + CELL_SIZE/4
            rl.DrawCircleV({cx, cy}, CELL_SIZE/4, rl.BLUE)
            ct := editor.level_map[y][x].(TopCannonTile)
            dx := cx + (CELL_SIZE/2 - 5) * math.cos(tile.angle)
            dy := cy + (CELL_SIZE/2 - 5) * math.sin(tile.angle)
            rl.DrawLineEx({cx, cy}, {dx, dy}, 3, rl.BLUE)
        case BottomCannonTile:
            rx := f32(MARGIN+x*CELL_SIZE) + CELL_SIZE/4
            ry := f32(MARGIN+y*CELL_SIZE) + 3*CELL_SIZE/4
            rw := f32(CELL_SIZE/2)
            rh := f32(CELL_SIZE/4)
            rl.DrawRectangleRec({rx, ry, rw, rh}, rl.BLUE)
            cx := f32(MARGIN+x*CELL_SIZE) + CELL_SIZE/2
            cy := f32(MARGIN+y*CELL_SIZE) + 3*CELL_SIZE/4
            rl.DrawCircleV({cx, cy}, CELL_SIZE/4, rl.BLUE)
            ct := editor.level_map[y][x].(BottomCannonTile)
            lx := cx + (CELL_SIZE/2 - 5) * math.cos(tile.angle)
            ly := cy - (CELL_SIZE/2 - 5) * math.sin(tile.angle)
            rl.DrawLineEx({cx, cy}, {lx, ly}, 3, rl.BLUE)
        }
    }

    rl.DrawRectangleLines(MARGIN+editor.active_tile.x*CELL_SIZE, MARGIN+editor.active_tile.y*CELL_SIZE, CELL_SIZE, CELL_SIZE, rl.YELLOW)
}

draw_editor_toolbox :: proc(editor: ^LevelEditor, settings: ^Settings) {
    w := settings.screen_width
    h := settings.screen_height
    rl.DrawRectangleLines(settings.screen_width-TOOL_SIZE*2, 0, TOOL_SIZE*2, settings.screen_height-1, rl.WHITE)
    rl.DrawRectangle(w-TOOL_SIZE*2, 1, TOOL_SIZE*2-1, h-2, rl.BLUE)
    rl.DrawLine(w-TOOL_SIZE, 0, w-TOOL_SIZE, h-1, rl.WHITE)
    for y: i32 = 0; y < settings.screen_height; y += TOOL_SIZE {
        rl.DrawLine(w-TOOL_SIZE*2, y, w-1, y, rl.WHITE)
    }

    for y in 0..<i32(25) do for x in 0..<i32(2) {
        if editor.toolbox[y][x] == editor.current_tool {
            rl.DrawRectangle(w-TOOL_SIZE*(2-x), y*TOOL_SIZE, TOOL_SIZE-1, TOOL_SIZE-1, rl.ORANGE)
            break
        }
    }

    rl.DrawRectangle(w-TOOL_SIZE+3, 4, TOOL_SIZE-7, TOOL_SIZE-7, rl.WHITE)
    x1: f32 = f32(w) - TOOL_SIZE*2 + 3
    y1: f32 = TOOL_SIZE+4
    x2: f32 = x1
    y2: f32 = y1+TOOL_SIZE-8
    x3: f32 = f32(w) - TOOL_SIZE - 4
    y3: f32 = y1
    rl.DrawTriangle({x1, y1}, {x2, y2}, {x3, y3}, rl.WHITE)
    x1 = f32(w) - TOOL_SIZE+4
    y1 = TOOL_SIZE+4
    x2 = f32(w) - 4
    y2 = y1 + TOOL_SIZE-8
    x3 = x2
    y3 = y1
    rl.DrawTriangle({x1, y1}, {x2, y2}, {x3, y3}, rl.WHITE)
    x1 = f32(w) - TOOL_SIZE*2 + 3
    y1 = 2*TOOL_SIZE+4
    x2 = x1
    y2 = y1+TOOL_SIZE-8
    x3 = x1 + TOOL_SIZE - 8
    y3 = y2
    rl.DrawTriangle({x1, y1}, {x2, y2}, {x3, y3}, rl.WHITE)
    x1 = f32(w) - 4
    y1 = 2*TOOL_SIZE+4
    x2 = f32(w) - TOOL_SIZE+4
    y2 = y1+TOOL_SIZE-8
    x3 = x1
    y3 = y2
    rl.DrawTriangle({x1, y1}, {x2, y2}, {x3, y3}, rl.WHITE)
    // Top cannon
    x1 = f32(w) - TOOL_SIZE*2 + 3
    y1 = 3*TOOL_SIZE + 4
    w1: f32 = TOOL_SIZE - 8
    h1: f32 = TOOL_SIZE / 3
    rl.DrawRectangleRec({x1, y1, w1, h1}, rl.WHITE)
    x1 = x1 + w1 / 2
    y1 = y1 + h1
    r1 := f32(TOOL_SIZE/3)
    rl.DrawCircleV({x1, y1}, r1, rl.WHITE)
    rl.DrawLineV({x1, y1}, {x1+10, y1+10}, rl.WHITE)
    // Bottom cannon
    x1 = f32(w) - TOOL_SIZE + 4 + TOOL_SIZE/3
    y1 = 3*TOOL_SIZE + 8 + TOOL_SIZE/3
    rl.DrawCircleV({x1, y1}, r1, rl.WHITE)
    rl.DrawLineV({x1, y1}, {x1-10, y1-10}, rl.WHITE)
    x1 -= TOOL_SIZE/3 + 1
    rl.DrawRectangleRec({x1, y1, w1, h1}, rl.WHITE)
}

select_tool :: proc(editor: ^LevelEditor, settings: ^Settings) {
    mp := rl.GetMousePosition()
    x := 1 - (settings.screen_width - i32(mp.x)) / TOOL_SIZE
    y := i32(mp.y) / TOOL_SIZE
    editor.current_tool = editor.toolbox[y][x]
}

init_toolbox :: proc(editor: ^LevelEditor) {
    editor.toolbox[0][0] = EmptyTile{}
    editor.toolbox[0][1] = LandTile{}
    editor.toolbox[1][0] = NWTriangleTile{}
    editor.toolbox[1][1] = NETriangleTile{}
    editor.toolbox[2][0] = SWTriangleTile{}
    editor.toolbox[2][1] = SETriangleTile{}
    editor.toolbox[3][0] = TopCannonTile{}
    editor.toolbox[3][1] = BottomCannonTile{}
}
