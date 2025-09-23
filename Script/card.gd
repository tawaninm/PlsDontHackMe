extends Node2D

@export var card_type: String = ""
var owner_index: int = -1
var card_data: Dictionary = {}
var gm: Node = null

func set_gm(game_manager: Node) -> void:
	gm = game_manager

func _ready() -> void:
	# Just make sure it belongs to the "Card" group
	if not is_in_group("Card"):
		add_to_group("Card")

	_update_visuals()

# --- DATA / OWNER ---
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

# --- VISUALS ---
func _update_visuals() -> void:
	var tex_path = "res://Asset/CARDS/%s.png" % card_type
	if has_node("Area2D/CardImage") and ResourceLoader.exists(tex_path):
		$Area2D/CardImage.texture = load(tex_path)

	if has_node("Label"):
		$Label.text = card_type
