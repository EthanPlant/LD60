class_name CamcorderHUD
extends Control

@export var display_font: Font

const BG := Color("#091521")
const PANEL := Color(0.025, 0.065, 0.105, 91)
const BORDER := Color("#395565")
const CYAN := Color("#7DDDE8")
const CREAM := Color("#E8E4D4")
const MUTED := Color("#A5BAC6")
const GREEN := Color("#91DFBF")
const AMBER := Color("#DFBA72")
const RED := Color("#F07171")

const SEGMENTS := 24

var recorder: TapeRecorder
var level_title: String = ""
var level_hint: String = ""

var notice: String = ""
var notice_timer: float = 0.0
var notice_danger: bool = false

var blink_time: float = 0.0
var showing_ending: bool = false

func _process(delta: float) -> void:
    blink_time += delta

    if notice_timer > 0.0:
        notice_timer = maxf(notice_timer - delta, 0.0)

    queue_redraw()

func _draw() -> void:
    if showing_ending:
        draw_ending()
        return

    draw_viewfinder()
    draw_recorder_panel()
    draw_tape_panel()
    draw_footer()

    if notice_timer > 0.0:
        draw_notice()

func begin_level(title: String, hint: String, tape_recorder: TapeRecorder) -> void:
    level_title = title
    level_hint = hint
    recorder = tape_recorder

    showing_ending = false
    notice = ""
    notice_timer = 0.0

    queue_redraw()

func show_feedback(message: String, danger: bool = false) -> void:
    notice = message
    notice_danger = danger
    notice_timer = 1.5

func show_ending() -> void:
    recorder = null
    showing_ending = true
    notice_timer = 0.0
    queue_redraw()

func draw_viewfinder() -> void:
    var w: float = size.x
    var h: float = size.y

    draw_corner(Vector2(30, 166), 1.0, 1.0)
    draw_corner(Vector2(w - 30, 166), -1.0, 1.0)
    draw_corner(Vector2(30, h - 112), 1.0, -1.0)
    draw_corner(Vector2(w - 30, h - 112), -1.0, -1.0)

    var centre := Vector2(w * 0.5, h * 0.5)

    var faint := Color(0.5, 0.85, 0.85, 0.2)
    draw_line(centre + Vector2(-12, 0), centre + Vector2(12, 0), faint)
    draw_line(centre + Vector2(0, -12), centre + Vector2(0, 12), faint)

func draw_recorder_panel() -> void:
    panel(Rect2(20, 20, 344, 124))

    text("LD60 / REWIND TO SURVIVE", 38, 45, 13, CYAN)

    text(level_title, 38, 83, 21, CREAM, 305)

    if not is_instance_valid(recorder):
        return

    var state_label: String = "STOP"
    var state_colour: Color = MUTED
    var elapsed: float = 0.0

    match recorder.state:
        TapeRecorder.State.RECORDING:
            state_label = "REC"
            state_colour = RED
            elapsed = recorder.get_recorded_seconds()

        TapeRecorder.State.REWINDING:
            state_label = "REW"
            state_colour = AMBER

        TapeRecorder.State.PLAYING:
            state_label = "PLAY"
            state_colour = GREEN

            if is_instance_valid(recorder.ghost):
                elapsed = float(recorder.ghost.frame_index) / float(Engine.physics_ticks_per_second)

    var blink_visible: bool = true

    if recorder.state == TapeRecorder.State.RECORDING:
        blink_visible = fmod(blink_time, 0.9) < 0.55

    if blink_visible:
        draw_circle(Vector2(45, 114), 4.5, state_colour)
    
    text(state_label, 59, 121, 16, state_colour)
    
    var timestamp: String = "%05.2f / %05.2f" % [ elapsed, TapeRecorder.MAX_SECONDS ]
    text(timestamp, 137, 121, 15, CREAM, 206)

func draw_tape_panel() -> void:
    var x: float = size.x - 364.0
    panel(Rect2(x, 20, 344, 124))

    text("TAPE // VHS-C", x + 18, 44, 13, CYAN)

    var condition: String = "NO TAPE"
    var available: float = 0.0
    var playback_number: int = 0

    if is_instance_valid(recorder):
        condition = recorder.get_condition()
        available = recorder.get_usable_seconds()
        playback_number = recorder.playback_count

        if recorder.state == TapeRecorder.State.RECORDING:
            available = recorder.get_recorded_seconds()

        var condition_colour = GREEN
        match condition:
            "WORN":
                condition_colour = AMBER
            "DAMAGED", "BROKEN":
                condition_colour = RED
            "NO TAPE":
                condition_colour = MUTED

        text("TRACKING: " + condition, x + 18, 76, 18, condition_colour, 304)

        var ratio: float = clampf(available / TapeRecorder.MAX_SECONDS, 0.0, 1.0)

        var filled: int = roundi(float(SEGMENTS) * ratio)

        var bar_width: float = 305.0
        var step_width: float = bar_width / float(SEGMENTS)

        for i in range(SEGMENTS):
            var rect := Rect2(x + 18.0 + float(i) * step_width, 89.0, step_width - 3.0, 14.0)
            var segment_colour := Color("#344657")
            if i < filled:
                segment_colour = condition_colour

            draw_rect(rect, segment_colour)

        text("PLAY %02d/%02d" % [ playback_number, TapeRecorder.MAX_PLAYBACKS ], x + 18, 125, 12, MUTED)
        text("%.2fs AVAILABLE" % available, x + 175, 125, 12, MUTED, 150)

func draw_footer() -> void:
    var w: float = size.x
    var h: float = size.y

    panel(Rect2(20, h - 81, w - 40, 62))

    text("OBJECTIVE", 38, h - 58, 12, GREEN)

    text(level_hint, 135, h - 58, 13, CREAM, w - 175)

    var record_action: String = "RECORD"

    if is_instance_valid(recorder):
        match recorder.state:
            TapeRecorder.State.RECORDING:
                record_action = "STOP / REWIND"

            TapeRecorder.State.REWINDING:
                record_action = "REWINDING"

            TapeRecorder.State.PLAYING:
                if (recorder.tape_wear_enabled and recorder.playback_count >= TapeRecorder.MAX_PLAYBACKS):
                    record_action = "TAPE SPENT"
                else:
                    record_action = "REPLAY"

    text("R", 38, h - 30, 13, AMBER)
    text(record_action, 55, h - 30, 13, MUTED, 190)

    text("BACKSPACE", 292, h - 30, 13, AMBER)

    text("ERASE / RESET", 390, h - 30, 13, MUTED)

    text("SIGNAL", w - 116, h - 30, 12, GREEN)

    draw_circle(Vector2(w - 128, h - 35), 3.0, GREEN)


func draw_notice() -> void:
    var w: float = size.x

    var alpha: float = clampf(notice_timer / 0.35, 0.0, 1.0)

    var rect := Rect2(w * 0.5 - 310.0, 163.0, 620.0, 46.0)

    var background := Color(0.025, 0.065, 0.105, 0.87 * alpha)

    var accent: Color = RED if notice_danger else GREEN
    accent.a = alpha

    draw_rect(rect, background)
    draw_rect(rect, accent, false, 1.0)

    var text_color: Color = CREAM
    text_color.a = alpha

    text(notice, rect.position.x + 18.0, rect.position.y + 30.0, 18, text_color, rect.size.x - 36.0)


func draw_ending() -> void:
    var w: float = size.x
    var h: float = size.y

    draw_rect(Rect2(Vector2.ZERO, size), BG)

    var x: float = w * 0.5 - 275.0
    var y: float = h * 0.5 - 85.0

    draw_line(Vector2(x, y), Vector2(x + 550, y), GREEN, 2.0)

    text("TRANSMISSION COMPLETE", x, y - 18, 14, CYAN)

    text("SIGNAL RESTORED", x, y + 63, 38, CREAM, 550)

    text("ALL RECORDINGS ACCOUNTED FOR", x, y + 105, 15, GREEN)

    text("ENTER  /  RESTART SESSION", x, y + 185, 16, AMBER)


func font() -> Font:
    if display_font != null:
        return display_font

    return ThemeDB.fallback_font

func text(value: String, x: float, y: float, font_size: int, colour: Color, max_width: float = -1.0) -> void:
    draw_string(font(), Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, colour)

func panel(rect: Rect2) -> void:
    draw_rect(rect, PANEL)
    draw_rect(rect, BORDER, false, 1.0)
    draw_line(rect.position, rect.position + Vector2(85.0, 0.0), CYAN, 2.0)

func draw_corner(pos: Vector2, horizontal: float, vertical: float) -> void:
    var dim := Color(0.49, 0.86, 0.91, 0.35)

    draw_line(pos, pos + Vector2(19.0 * horizontal, 0.0), dim, 1.5)
    draw_line(pos, pos + Vector2(0.0, 19.0 * vertical), dim, 1.5)

