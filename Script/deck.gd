extends Node2D

signal draw_requested

var gm: Node = null

func set_gm(game_manager: Node) -> void:
	gm = game_manager

func _ready() -> void:
	if has_node("Area2D"):
		var a = $Area2D
		if not a.is_connected("input_event", Callable(self, "_on_Area2D_input_event")):
			a.connect("input_event", Callable(self, "_on_Area2D_input_event"))

func _on_Area2D_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("draw_requested")
