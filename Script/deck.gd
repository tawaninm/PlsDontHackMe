extends Node2D

signal draw_requested

func _ready() -> void:
	# If this Deck has an Area2D child, connect its input_event
	if has_node("Area2D"):
		var a = $Area2D
		a.input_event.connect(_on_Area2D_input_event)

func _on_Area2D_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("draw_requested")
