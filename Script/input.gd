extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4

var card_manager_reference
var deck_reference
var gm: Node = null

func set_gm(game_manager: Node) -> void:
	gm = game_manager

func _ready() -> void:
	card_manager_reference = $"../CardManager"
	deck_reference = $"../Board/Draw"

	if not gm:
		var root = get_tree().get_current_scene()
		if root and root.has_method("register_scene_nodes"):
			gm = root

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pos = get_global_mouse_position()
		if gm:
			gm.card_clicked_from_input_at_position(pos, event.button_index)

func raycast_at_cursor():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)

	if result.size() > 0:
		var collider = result[0].collider
		if collider is Node:
			if deck_reference and collider.get_parent() == deck_reference:
				deck_reference.emit_signal("draw_requested")
				return
			elif collider.collision_mask & COLLISION_MASK_CARD != 0:
				var card_found = collider.get_parent()
				if card_found and card_manager_reference and card_manager_reference.has_method("on_card_pressed"):
					card_manager_reference.on_card_pressed(card_found)
