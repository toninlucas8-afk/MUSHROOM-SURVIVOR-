class_name Weapon
extends Node2D
## Base delle armi. Ogni arma è figlia del giocatore: disegna in coordinate locali (centrate sul fungo)
## e crea proiettili nel mondo. Le sottoclassi implementano fire() e, se serve, tick()/draw.

var id := ""
var level := 1
var evolved := false
var player: Player
var timer := 0.3
var t := 0.0


func evolve() -> void:
	evolved = true
	_on_evolve()


func _on_evolve() -> void:
	pass


## Danno con potenza del giocatore e sinergia del personaggio (+20% sull'arma iniziale).
func dmg(base: float) -> float:
	var m := player.might
	if Data.CHARACTERS[player.char_id]["signature"] == id:
		m *= 1.2
	return base * m


func cd(base: float) -> float:
	return maxf(0.08, base * player.cooldown)


func area() -> float:
	return player.area


func color() -> Color:
	return Data.WEAPONS[id]["color"]


func game() -> Game:
	return Game.current


func _process(delta: float) -> void:
	t += delta
	tick(delta)
	timer -= delta
	if timer <= 0.0:
		timer = fire()
	queue_redraw()


## Chiamata ogni frame (armi continue). Di default non fa nulla.
func tick(_delta: float) -> void:
	pass


## Attacco periodico: restituisce i secondi fino al prossimo.
func fire() -> float:
	return 1.0


func on_kill(_e: Enemy) -> void:
	pass


func shoot(dir: Vector2, speed: float, damage: float, radius: float, pierce: int, life: float, col: Color, shape: String = "orb") -> Projectile:
	var p := Projectile.new()
	p.position = player.position
	p.velocity = dir.normalized() * speed
	p.damage = damage
	p.radius = radius
	p.pierce = pierce
	p.life = life
	p.color = col
	p.shape = shape
	game().projectiles_layer.add_child(p)
	return p
