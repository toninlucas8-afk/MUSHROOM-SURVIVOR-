class_name UiStyle
## Stile comune dell'interfaccia (colori neon su viola scuro).

const BG := Color(0.07, 0.03, 0.12, 0.92)
const ACCENT := Color(1.0, 0.35, 0.8)


static func box(color: Color = BG, border: Color = ACCENT, radius: int = 18, border_w: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(16)
	s.shadow_color = Color(border, 0.35)
	s.shadow_size = 12
	return s


static func label(text: String, size: int = 20, color: Color = Color.WHITE, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", box(Color(0.35, 0.1, 0.55), Color.WHITE, 30, 3))
	b.add_theme_stylebox_override("hover", box(Color(0.55, 0.15, 0.75), Color.WHITE, 30, 3))
	b.add_theme_stylebox_override("pressed", box(Color(0.2, 0.05, 0.35), Color.WHITE, 30, 3))
	b.add_theme_stylebox_override("focus", box(Color(0.55, 0.15, 0.75), ACCENT, 30, 3))
	b.custom_minimum_size = Vector2(240, 64)
	return b


## Overlay a schermo intero con sfondo scuro e contenuto centrato.
static func overlay(parent: Control) -> VBoxContainer:
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.0, 0.05, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(v)
	return v
