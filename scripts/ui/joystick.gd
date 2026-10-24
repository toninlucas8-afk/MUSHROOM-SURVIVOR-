class_name Joystick
extends Control
## Joystick virtuale: appare dove tocchi lo schermo (metà sinistra o ovunque fuori dai pulsanti).

const RADIUS := 70.0

var vector := Vector2.ZERO
var _active := false
var _index := -1
var _origin := Vector2.ZERO
var _pos := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_active = true
			_index = event.index
			_origin = event.position
			_pos = event.position
		elif not event.pressed and event.index == _index:
			_active = false
			vector = Vector2.ZERO
		queue_redraw()
	elif event is InputEventScreenDrag and _active and event.index == _index:
		_pos = event.position
		var d := _pos - _origin
		vector = d.limit_length(RADIUS) / RADIUS if d.length() > 8.0 else Vector2.ZERO
		queue_redraw()


func _process(_delta: float) -> void:
	if get_tree().paused and _active:
		_active = false
		vector = Vector2.ZERO
		queue_redraw()


func _draw() -> void:
	if not _active:
		return
	var tr := get_global_transform_with_canvas().affine_inverse()
	var o := tr * _origin
	var knob := o + (_pos - _origin).limit_length(RADIUS)
	draw_arc(o, RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(knob, 28.0, Color(1, 1, 1, 0.4))
