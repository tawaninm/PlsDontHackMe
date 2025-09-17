# res://Scripts/Card.gd
extends Node2D

@export var card_type: String = ""
var owner_index: int = -1
var card_data: Dictionary = {}

func _ready() -> void:
	# connect Area2D input_event (if present)
	if has_node("Area2D"):
		var a = $Area2D
		if not a.is_connected("input_event", Callable(self, "_on_input_event")):
			a.connect("input_event", Callable(self, "_on_input_event"))

	# add to "Card" group so other scripts can detect it
	if not is_in_group("Card"):
		add_to_group("Card")

	# if card_data already set, update visuals
	_update_visuals()

# Set card data (dictionary), e.g. { "name":"Cat", "cost": 3 }
func set_card_data(data: Dictionary) -> void:
	card_data = data.duplicate(true)
	card_type = card_data.get("name", card_data.get("card_type", card_type))
	if card_data.has("owner_index"):
		owner_index = card_data.owner_index
	_update_visuals()

func get_card_data() -> Dictionary:
	return card_data

func set_card_owner(idx: int) -> void:
	owner_index = idx

func get_card_owner() -> int:
	return owner_index

func _update_visuals() -> void:
	# set sprite/label if nodes exist
	var tex_path = "res://Asset/CARDS/%s.png" % card_type
	if has_node("Area2D/CardImage") and ResourceLoader.exists(tex_path):
		$Area2D/CardImage.texture = load(tex_path)
	if has_node("Label"):
		$Label.text = card_type

# Input handler (left = use, right = throw)
func _on_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		var player_index = GameManager.current_player_index
		var player = GameManager.players[player_index]

		if event.button_index == MOUSE_BUTTON_LEFT:
			if GameManager.can_use_card(player, card_data):
				GameManager.use_card(player_index, self)
			else:
				print("Not enough bandwidth to play:", card_type)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if GameManager.can_throw_card(player):
				GameManager.throw_card(player_index, self)
			else:
				print("Not enough bandwidth to throw:", card_type)
