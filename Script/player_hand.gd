extends Node2D

const HAND_Y_POSITION = 500
const HAND_MARGIN = 100

var player_hand = []
var center_screen_x
var screen_width

func _ready() -> void:
	screen_width = get_viewport().size.x
	center_screen_x = screen_width / 2

func add_card_to_hand(card):
	player_hand.insert(0, card)
	update_hand_position()

func update_hand_position():
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.starting_position = new_position
		animate_card_to_position(card, new_position)

func calculate_card_position(index):
	var available_width = screen_width - (HAND_MARGIN * 2)
	var spacing = 0.0
	if player_hand.size() > 1:
		spacing = available_width / (player_hand.size() - 1)
	var x_offset = HAND_MARGIN + index * spacing
	return x_offset

func animate_card_to_position(card, new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.2)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		card.queue_free()
		update_hand_position()
