class_name Projectile
extends Node2D
## Proiettile generico usato da più armi (spore, cristalli, colpi dei famigli).

var velocity := Vector2.ZERO
var damage := 10.0
var radius := 6.0
var pierce := 1
var life := 1.5
var color := Color.WHITE
var shape := "orb" # orb | crystal
var homing := 0.0
var explode_radius := 0.0
var boomerang := false
var knock := 60.0
var _hit := {}
var _age := 0.0


func _ready() -> void:
	var g := Game.current
	if g.player.char_id == "myco":
		homing = maxf(homing, 4.0) # sinergia di Myco: spore auto-guidate


func _process(delta: float) -> void:
	_age += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var g := Game.current
	if homing > 0.0:
		var t: Array = g.nearest(position, 320.0, 1)
		if t.size() > 0:
			var want: Vector2 = (t[0].position - position).normalized() * velocity.length()
			velocity = velocity.lerp(want, minf(1.0, homing * delta))
	if boomerang and _age > 0.45:
		var back := (g.player.position - position)
		velocity = velocity.lerp(back.normalized() * 520.0, minf(1.0, 4.0 * delta))
		if back.length() < 20.0 and _age > 0.8:
			queue_free()
			return
	position += velocity * delta
	for e in g.query(position, radius + 50.0):
		if _hit.has(e.get_instance_id()):
			continue
		if position.distance_to(e.position) < radius + e.radius:
			_hit[e.get_instance_id()] = true
			e.take_damage(damage, velocity, knock)
			if explode_radius > 0.0:
				g.hit_area(position, explode_radius, damage * 0.6, 30.0, color)
			pierce -= 1
			if pierce <= 0:
				queue_free()
				return
	queue_redraw()


func _draw() -> void:
	var c := Color.from_hsv(fmod(color.h + _age * 0.6, 1.0), color.s, 1.0)
	draw_circle(Vector2.ZERO, radius * 2.0, Color(c, 0.35))
	if shape == "crystal":
		var a := velocity.angle()
		draw_colored_polygon(PackedVector2Array([
			Vector2(cos(a), sin(a)) * radius * 1.9,
			Vector2(cos(a + 2.4), sin(a + 2.4)) * radius,
			Vector2(cos(a - 2.4), sin(a - 2.4)) * radius,
		]), c.lightened(0.4))
	else:
		draw_circle(Vector2.ZERO, radius, c.lightened(0.5))
