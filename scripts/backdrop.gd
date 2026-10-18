extends Node2D

const BG := Color("#111925")
const PANEL := Color("#1A2939")
const GRID := Color("#233245")
const LIGHT := Color("#42675D")

func _ready() -> void:
	z_index = -10

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), BG)

	for x in range(0, 960, 48):
		draw_line(Vector2(x, 0), Vector2(x, 440), GRID, 1.0)
	
	for y in range(0, 440, 48):
		draw_line(Vector2(0, y), Vector2(960, y), GRID, 1.0)

	for i in range(5):
		var x: float = 85.0 + i * 175.0

		draw_rect(Rect2(x, 95, 95, 130), PANEL)

		draw_rect(Rect2(x + 12, 110, 70, 40), Color("#0B161B"))

		draw_rect(Rect2(x + 18, 118, 45, 3), LIGHT)

		draw_circle(Vector2(x + 22, 174), 3.0, LIGHT)

	draw_line(Vector2(0, 45), Vector2(960, 45), Color("#425B67"), 5.0)
