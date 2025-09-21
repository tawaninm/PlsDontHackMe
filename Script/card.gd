extends Node2D

@export var card_type: String = ""
var owner_index: int = -1
var card_data: Dictionary = {}
var gm: Node = null

func set_gm(game_manager: Node) -> void:
	gm = game_manager

func _ready() -> void:
	if has_node("Area2D"):
		var a = $Area2D
		if not a.is_connected("input_event", Callable(self, "_on_input_event")):
			a.connect("input_event", Callable(self, "_on_input_event"))

	if not is_in_group("Card"):
		add_to_group("Card")

	_update_visuals()

func set_card_data(data: Dictionary) -> void:
	card_data = data.duplicate(true)
	card_type = card_data.get("name", card_data.get("card_type", card_type))
	if card_data.has("owner_index"):
		owner_index = int(card_data["owner_index"])
	_update_visuals()

func get_card_data() -> Dictionary:
	return card_data

func set_card_owner(idx: int) -> void:
	owner_index = idx

func get_card_owner() -> int:
	return owner_index

func _update_visuals() -> void:
	var tex_path = "res://Asset/CARDS/%s.png" % card_type
	if has_node("Area2D/CardImage") and ResourceLoader.exists(tex_path):
		$Area2D/CardImage.texture = load(tex_path)
	if has_node("Label"):
		$Label.text = card_type

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if not gm:
		var root = get_tree().get_current_scene()
		if root and root.has_node("GameManager"):
			gm = root.get_node("GameManager")
	# if still no gm, just try top-level scene (best-effort fallback)
	if not gm:
		var root2 = get_tree().get_current_scene()
		if root2:
			gm = root2

	if not gm:
		return

	if event is InputEventMouseButton and event.pressed:
		var player_index = gm.current_player_index
		var player = gm.players[player_index]

		if event.button_index == MOUSE_BUTTON_LEFT:
			if gm.can_use_card(player, card_data):
				gm.use_card(player_index, self)
			else:
				print("Not enough bandwidth to play:", card_type)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if gm.can_throw_card(player):
				gm.throw_card(player_index, self)
			else:
				print("Not enough bandwidth to throw:", card_type)
