extends Node2D

signal left_mouse_button_clicked

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4

var card_manager_reference
var deck_reference

func _ready() -> void:
	card_manager_reference = $"../CardManager"
	deck_reference = $"../Deck"

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		emit_signal("left_mouse_button_clicked")
		raycast_at_cursor()

func raycast_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var collider = result[0].collider
		if collider is Node:
			# Check deck first
			if collider.get_parent() == deck_reference:
				deck_reference.draw_card()
				return
			# Check card
			elif collider.collision_mask & COLLISION_MASK_CARD != 0:
				var card_found = collider.get_parent()
				if card_found:
					card_manager_reference.on_card_pressed(card_found)
