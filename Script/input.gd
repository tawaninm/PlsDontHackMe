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
	# Forward all mouse-button presses (left/right) to the GM
	if event is InputEventMouseButton and event.pressed:
		# debug: uncomment while debugging
		# print("InputController _input: button", event.button_index, "pressed, pos:", get_global_mouse_position())

		var pos = get_global_mouse_position()
		if gm:
			# forward button index so GM can differentiate left/right
			gm.card_clicked_from_input_at_position(pos, event.button_index)

		# Optionally, handle deck draws by raycast here as well:
		# (keeps deck logic co-located; you can remove if deck uses Area2D input)
		var space_state = get_world_2d().direct_space_state
		var params = PhysicsPointQueryParameters2D.new()
		params.position = pos
		params.collide_with_areas = true
		params.collision_mask = COLLISION_MASK_DECK
		var result = space_state.intersect_point(params)
		if result.size() > 0:
			var collider = result[0].collider
			if deck_reference and collider.get_parent() == deck_reference:
				deck_reference.emit_signal("draw_requested")
				return
