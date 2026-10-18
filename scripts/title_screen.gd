class_name TitleScreen
extends Control

signal start_requested

@export var display_font: Font

const BG := Color("#09131E")
const PANEL := Color("#142333")
const CREAM := Color("#F1DFBA")
const CYAN := Color("#7CE4E7")
const MUTED := Color("#7293A6")
const GREEN := Color("#8EE5A5")
const RED := Color("#D65B65")

var elapsed := 0.0
var starting := false

func show_screen() -> void:
    elapsed = 0.0
    starting = false
    show()
    queue_redraw()

func _process(delta: float) -> void:
    if not visible:
        return

    elapsed += delta
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if not visible or starting:
        return

    var activate := false

    if event is InputEventKey:
        var key := event as InputEventKey

        activate = key.pressed and not key.echo and key.keycode in [ KEY_ENTER, KEY_KP_ENTER, KEY_SPACE ]

    elif event is InputEventMouseButton:
        var mouse := event as InputEventMouseButton

        activate = mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT

    if activate:
        starting = true
        get_viewport().set_input_as_handled()
        start_requested.emit()

func _draw() -> void:
    var font: Font = display_font if display_font != null else ThemeDB.fallback_font
    var scale_factor := Vector2(size.x / 960.0, size.y / 540.0)

    draw_set_transform(Vector2.ZERO, 0.0, scale_factor)

    draw_rect(Rect2(0, 0, 960, 540), BG)

    for x in range(0, 961, 80):
        draw_line(Vector2(x, 0), Vector2(x, 540), Color(CYAN, 0.045), 1.0)

    for y in range(0, 541, 60):
        draw_line(Vector2(0, y), Vector2(960, y), Color(CYAN, 0.045), 1.0)

    corner(Vector2(32, 30), Vector2(1, 1))
    corner(Vector2(920, 30), Vector2(-1, 1))
    corner(Vector2(32, 510), Vector2(1, -1))
    corner(Vector2(928, 510), Vector2(-1, -1))

    label(font, "ARCHIVE / TAPE 0001", Vector2(54, 61), 21, MUTED)
    label(font, "VHS-C / LD60", Vector2(750, 61), 21, CYAN)

    if fmod(elapsed, 1.0) < 0.65:
        draw_circle(Vector2(882, 91), 5, RED)

    label(font, "SP", Vector2(897, 97), 16, CREAM)

    draw_line(Vector2(55, 107), Vector2(905, 107), Color(MUTED, 0.4), 1.0)
    
    centre(font, "REWIND", 207, 84, CREAM)
    centre(font, "TO SURVIVE", 280, 59, CYAN)

    centre(font, "RECORD. REWIND. SURVIVE.", 320, 18, MUTED)

    draw_performance()

    var progress := fmod(elapsed, 6.0) / 6.0
    for i in range(26):
        var active := float(i) / 26.0 <= progress

        draw_rect(Rect2(259 + i * 17, 417, 12, 9), CYAN if active else Color("#26394A"))

    if fmod(elapsed, 1.2) < 0.85:
        centre(font, "PRESS ENTER OR CLICK TO PLAY", 472, 23, GREEN)

    label(font, "48H COMPO", Vector2(55, 493), 16, GREEN)
    label(font, "SIGNAL FOUND", Vector2(798, 493), 16, GREEN)

    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func draw_performance() -> void:
    var cycle := fmod(elapsed, 5.0) / 5.0

    draw_rect(Rect2(300, 370, 360, 3), Color(MUTED, 0.6))

    for i in range(15):
        draw_rect(Rect2(330 + i * 20, 349, 7, 2), Color(CYAN, 0.25))

    var player_x := 330.0 + cycle * 280.0
    var player_jump: float = abs(sin(cycle * TAU * 2.0) * 13.0)

    draw_rect(Rect2(player_x, 342.0 - player_jump, 18, 28), CREAM)

    var ghost_cycle := fmod(cycle + 0.75, 1.0)
    var ghost_x := 330 + ghost_cycle * 280.0
    var ghost_jump: float = abs(sin(ghost_cycle * TAU * 2.0) * 13.0)
    draw_rect(Rect2(ghost_x, 342.0 - ghost_jump, 18, 28), Color(CYAN, 0.55))
    

func corner(origin: Vector2, dir: Vector2) -> void:
    draw_line(origin, origin + Vector2(dir.x * 25, 0), MUTED, 2.0)
    draw_line(origin, origin + Vector2(0, dir.y * 25), MUTED, 2.0)

func label(font: Font, value: String, pos: Vector2, font_size: int, colour: Color) -> void:
    draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)

func centre(font: Font, value: String, baseline: float, font_size: int, colour: Color) -> void:
    draw_string(font, Vector2(0, baseline), value, HORIZONTAL_ALIGNMENT_CENTER, 960, font_size, colour)
