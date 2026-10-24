class_name Pickup
extends Node2D
## Oggetti a terra: cuore (cura), calamita (raccoglie tutto), memoria (frammento di trama).

var kind := "cuore"
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	var g := Game.current
	if position.distance_to(g.player.position) < g.player.radius + 18.0:
		g.collect_pickup(kind)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var b := sin(_t * 4.0) * 3.0
	match kind:
		"cuore":
			draw_circle(Vector2(-5, b - 3), 7.0, Color(1.0, 0.25, 0.4))
			draw_circle(Vector2(5, b - 3), 7.0, Color(1.0, 0.25, 0.4))
			draw_colored_polygon(PackedVector2Array([Vector2(-12, b - 1), Vector2(12, b - 1), Vector2(0, b + 12)]), Color(1.0, 0.25, 0.4))
		"calamita":
			draw_arc(Vector2(0, b), 10.0, PI, TAU, 16, Color(0.3, 0.7, 1.0), 6.0)
			draw_rect(Rect2(-13, b, 6, 8), Color(1, 1, 1))
			draw_rect(Rect2(7, b, 6, 8), Color(1, 1, 1))
		"memoria":
			var c := Color.from_hsv(fmod(_t * 0.3, 1.0), 0.6, 1.0)
			draw_circle(Vector2(0, b), 22.0 + sin(_t * 3.0) * 4.0, Color(c, 0.2))
			draw_colored_polygon(Art.ellipse(Vector2(0, b), 9.0, 13.0, 6), c)
			draw_circle(Vector2(0, b), 4.0, Color.WHITE)
