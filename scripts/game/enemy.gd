class_name Enemy
extends Node2D
## Un nemico: insegue il giocatore, si separa dagli altri, fa danno al contatto.

var type := "lumaca"
var hp := 10.0
var max_hp := 10.0
var speed := 50.0
var radius := 12.0
var damage := 5.0
var xp_value := 1
var base_color := Color.WHITE
var texture: Texture2D
var dead := false
var slow := 0.0
var hit_cooldowns := {} # id sorgente -> tempo residuo (per armi a contatto)
var _knock := Vector2.ZERO
var _flash := 0.0
var _phase := randf() * TAU
var _t := 0.0


func setup(t: String, elapsed: float) -> void:
	type = t
	var d: Dictionary = Data.ENEMIES[t]
	var hp_mul := 1.0 + elapsed / 120.0 if t == "boss" else 1.0 + elapsed / 75.0
	max_hp = d["hp"] * hp_mul
	hp = max_hp
	speed = d["speed"] * randf_range(0.9, 1.1)
	radius = d["radius"]
	damage = d["damage"] * (1.0 + elapsed / 300.0)
	xp_value = d["xp"]
	base_color = d["color"]
	texture = Data.sprite_for("nemico_" + t)


func _process(delta: float) -> void:
	if dead:
		return
	_t += delta
	var g := Game.current
	var to_player := g.player.position - position
	var dist := to_player.length()
	var dir := to_player / maxf(dist, 0.001)
	var spd := speed * (0.5 if slow > 0.0 else 1.0)
	var vel := dir * spd + _knock
	if type == "zanzara":
		_phase += delta * 6.0
		vel += Vector2(cos(_phase), sin(_phase * 1.3)) * 40.0
	position += vel * delta
	_knock *= pow(0.02, delta)
	_flash -= delta
	slow -= delta
	for k in hit_cooldowns.keys():
		hit_cooldowns[k] -= delta
	# separazione dagli altri nemici
	for o in g.query(position, radius * 2.0):
		if o == self:
			continue
		var off: Vector2 = position - o.position
		var rr: float = radius + o.radius
		var d2 := off.length_squared()
		if d2 > 0.0 and d2 < rr * rr:
			var dl := sqrt(d2)
			var w := 0.0 if type == "boss" else (2.0 if o.type == "boss" else 1.0)
			position += off / dl * (rr - dl) * 0.25 * w
	# contatto con il giocatore
	if dist < radius + g.player.radius:
		g.player.take_damage(damage)
	# troppo lontano: torna vicino al giocatore
	if dist > 1600.0 and type != "boss":
		position = g.offscreen_point()
	queue_redraw()


## Danno con spinta. source/cooldown servono alle armi che colpiscono a contatto continuo.
func take_damage(amount: float, knock_dir: Vector2 = Vector2.ZERO, knock: float = 0.0, source: String = "", cooldown: float = 0.0) -> bool:
	if dead:
		return false
	if source != "":
		if hit_cooldowns.get(source, 0.0) > 0.0:
			return false
		hit_cooldowns[source] = cooldown
	hp -= amount
	_flash = 0.08
	if knock > 0.0 and type != "boss" and knock_dir != Vector2.ZERO:
		_knock += knock_dir.normalized() * knock
	var g := Game.current
	g.effects.text(position + Vector2(randf_range(-6, 6), -radius), str(int(round(amount))), Color.from_hsv(fmod(g.elapsed * 0.25 + position.x * 0.001, 1.0), 0.6, 1.0))
	if hp <= 0.0:
		die()
	return true


func die() -> void:
	if dead:
		return
	dead = true
	Game.current.on_enemy_killed(self)
	queue_free()


func _draw() -> void:
	var g := Game.current
	var look_dir := (g.player.position - position).normalized()
	if texture:
		var s := radius * 2.6
		var fx := -1.0 if look_dir.x < 0.0 else 1.0
		draw_texture_rect(texture, Rect2(Vector2(-s * 0.5 * fx, -s * 0.5), Vector2(s * fx, s)), false, Color(3, 3, 3) if _flash > 0.0 else Color.WHITE)
	else:
		Art.draw_enemy(self, type, Vector2.ZERO, radius, base_color, _t, look_dir, _flash > 0.0, _phase)
	if type == "boss":
		draw_rect(Rect2(-radius, -radius - 20, radius * 2.0, 6), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-radius, -radius - 20, radius * 2.0 * maxf(0.0, hp / max_hp), 6), Color(1.0, 0.25, 0.5))
