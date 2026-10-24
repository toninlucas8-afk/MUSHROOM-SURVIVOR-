class_name StoryPopup
extends Control
## Riquadro per testi di trama, frammenti di memoria e pausa.

signal closed

var _title: Label
var _body: Label
var _button: Button


func _ready() -> void:
	visible = false
	var v := UiStyle.overlay(self)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.box())
	panel.custom_minimum_size = Vector2(640, 0)
	v.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 16)
	panel.add_child(inner)
	_title = UiStyle.label("", 34, Color(1.0, 0.55, 0.9))
	inner.add_child(_title)
	_body = UiStyle.label("", 19, Color(1, 1, 1, 0.92))
	_body.custom_minimum_size = Vector2(600, 0)
	inner.add_child(_body)
	_button = UiStyle.button("OK")
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.pressed.connect(close)
	inner.add_child(_button)


func show_text(title: String, body: String, button_text: String) -> void:
	_title.text = title
	_body.text = body
	_button.text = button_text
	visible = true
	_button.grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		close()
