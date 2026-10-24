extends Weapon
## Nebbia Tossica → Eclissi della Peste: aura continua intorno al giocatore.

var radius := 60.0


func _ready() -> void:
	z_index = -1


func tick(_delta: float) -> void:
	radius = (65.0 + 12.0 * int(level >= 2) + 12.0 * int(level >= 4) + 15.0 * int(level >= 7)) * area() * (1.8 if evolved else 1.0)
	if level >= 5 or evolved:
		for e in game().query(player.position, radius):
			if e.position.distance_to(player.position) < radius:
				e.slow = 0.15


func fire() -> float:
	var base := 4.0 + 2.5 * int(level >= 3) + 3.0 * int(level >= 6) + 3.0 * int(level >= 8)
	var damage := dmg(base * (1.6 if evolved else 1.0))
	for e in game().query(player.position, radius + 30.0):
		if e.position.distance_to(player.position) < radius + e.radius:
			e.take_damage(damage, e.position - player.position, 25.0)
	return 0.5


func on_kill(e: Enemy) -> void:
	# Eclissi: chi muore dentro la nube esplode e infetta i vicini
	if evolved and e.position.distance_to(player.position) < radius:
		game().effects.delayed_blast(e.position, 0.25, 50.0 * area(), dmg(8.0), Color(0.6, 0.1, 0.9))


func _draw() -> void:
	var c1 := Color.from_hsv(fmod(color().h + t * 0.05, 1.0), 0.8, 0.9)
	if evolved:
		draw_circle(Vector2.ZERO, radius, Color(0.08, 0.0, 0.12, 0.45))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color.from_hsv(fmod(t * 0.3, 1.0), 0.9, 1.0, 0.7), 4.0)
	else:
		draw_circle(Vector2.ZERO, radius, Color(c1, 0.12))
	for i in 7:
		var a := t * 0.6 + i * TAU / 7.0
		var r := radius * (0.55 + 0.25 * sin(t * 1.3 + i))
		draw_circle(Vector2(cos(a), sin(a)) * r, radius * 0.28, Color(c1, 0.07))
	draw_arc(Vector2.ZERO, radius, t, t + TAU * 0.8, 48, Color(c1, 0.35), 2.0)
