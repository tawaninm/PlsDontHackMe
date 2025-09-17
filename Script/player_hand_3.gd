extends Node2D

@export var player_index: int = 0
@export var hand_y_position: int = 800

const HAND_MARGIN := 100
const CARD_WIDTH := 66

var player_hand: Array = []
var center_screen_x: float
var screen_width: float

func _ready() -> void:
	screen_width = get_viewport().size.x
	center_screen_x = screen_width / 2

func add_card_to_hand(card: Node) -> void:
	player_hand.insert(0, card)
	card.z_index = 1
	# use the card's method if available (we renamed methods to avoid Node overrides)
	if card.has_method("set_card_owner"):
		card.set_card_owner(player_index)
	else:
		# fallback assign
		card.set("owner_index", player_index)
	update_hand_position()

func update_hand_position() -> void:
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), hand_y_position)
		var card = player_hand[i]
		
		if card:  # make sure the card exists
			# set a property or call a method depending on how your card script is structured
			if card.has_method("set_starting_position"):
				card.set_starting_position(new_position)
			else:
				card.set("position", new_position)  # fallback
		
			animate_card_to_position(card, new_position)


func calculate_card_position(index: int) -> float:
	var hand_size = player_hand.size()
	if hand_size == 0:
		return center_screen_x
	if hand_size == 1:
		return center_screen_x
	var available_width = screen_width - (HAND_MARGIN * 2)
	var max_spacing = CARD_WIDTH
	var spacing = min(available_width / (hand_size - 1), max_spacing)
	var total_width = (hand_size - 1) * spacing
	var start_x = center_screen_x - total_width / 2
	return start_x + index * spacing

func animate_card_to_position(card: Node, new_position: Vector2) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.18)

func remove_card_from_hand(card: Node) -> void:
	if card in player_hand:
		player_hand.erase(card)
		card.queue_free()
		update_hand_position()

# helpers
func get_hand_size() -> int:
	return player_hand.size()

func get_card_types() -> Array:
	var arr: Array = []
	for c in player_hand:
		arr.append(c.get_card_type())
	return arr

func get_card_nodes() -> Array:
	return player_hand.duplicate()
