class_name Gem
extends Node2D
## Cristallo di esperienza: viene attirato dal giocatore quando entra nel raggio di raccolta.

var value := 1
var pulled := false
var _speed := 0.0
var _phase := randf() * TAU


func _process(delta: float) -> void:
	var g := Game.current
	var to_p := g.player.position - position
	var d2 := to_p.length_squared()
	if d2 < g.player.magnet * g.player.magnet:
		pulled = true
	if pulled:
		_speed += delta * 900.0
		var d := sqrt(d2)
		position += to_p / maxf(d, 0.001) * (380.0 + _speed) * delta
		if d < g.player.radius + 8.0:
			g.gain_xp(value)
			queue_free()
			return
	_phase += delta * 4.0
	queue_redraw()


func _draw() -> void:
	var s := 9.0 if value >= 20 else (7.0 if value >= 5 else 5.0)
	var col := Color(1.0, 0.25, 0.35) if value >= 20 else (Color(1.0, 0.85, 0.2) if value >= 5 else Color.from_hsv(fmod(Game.current.elapsed * 0.15 + 0.5, 1.0), 0.8, 1.0))
	var b := sin(_phase) * 2.0
	draw_circle(Vector2(0, b), s * 1.6, Color(col, 0.18))
	draw_colored_polygon(PackedVector2Array([Vector2(0, -s + b), Vector2(s * 0.7, b), Vector2(0, s + b), Vector2(-s * 0.7, b)]), col)
