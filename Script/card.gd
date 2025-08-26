extends Node2D

signal hovered
signal hovered_off

var starting_position

func _ready() -> void:
	# all cards must be a child of CardManager or this will error
	get_parent().connect_card_signals(self)

func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)

func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
