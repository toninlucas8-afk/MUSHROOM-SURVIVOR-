class_name CharacterPreview
extends Control
## Anteprima animata di un personaggio (sprite se presente, altrimenti disegno a codice).

var char_id := "nyx"
var _t := 0.0
var _tex: Texture2D


func _ready() -> void:
	custom_minimum_size = Vector2(150, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tex = Data.sprite_for(char_id)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	draw_circle(c, size.x * 0.42, Color(Data.CHARACTERS[char_id]["cap"], 0.12))
	if _tex:
		var s := size.x * 0.9
		draw_texture_rect(_tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
	else:
		Art.draw_mushroom(self, c + Vector2(0, -6), size.x * 0.26, Data.CHARACTERS[char_id], _t, 1.0, false, sin(_t * 2.0) * 3.0)
