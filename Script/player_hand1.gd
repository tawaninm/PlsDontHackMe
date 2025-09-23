extends Node2D 

@export var player_index: int = 0
@export var hand_y_position: int = 800

const HAND_MARGIN := 100
const CARD_WIDTH := 120

var player_hand: Array = []
var center_screen_x: float
var screen_width: float
var gm: Node = null

func set_gm(game_manager: Node) -> void:
	gm = game_manager

func _ready() -> void:
	var visible = get_viewport().get_visible_rect()
	screen_width = visible.size.x
	center_screen_x = screen_width / 2

func add_card_to_hand(card: Node) -> void:
	player_hand.append(card)
	card.z_index = 1
	if card.has_method("set_card_owner"):
		card.set_card_owner(player_index)
	elif card.has("owner_index"):
		card.set("owner_index", player_index)

	card.position = Vector2(center_screen_x, hand_y_position + 300)
	add_child(card)
	update_hand_position()

func update_hand_position() -> void:
	var hand_size = player_hand.size()
	if hand_size == 0:
		return
	var available_width = screen_width - (HAND_MARGIN * 2)
	var max_spacing = CARD_WIDTH
	var spacing = min(available_width / (hand_size - 1), max_spacing) if hand_size > 1 else 0
	var total_width = (hand_size - 1) * spacing
	var start_x = center_screen_x - total_width / 2
	for i in range(hand_size):
		var card = player_hand[i]
		if not card:
			continue
		var target_pos = Vector2(start_x + spacing * i, hand_y_position)
		animate_card_to_position(card, target_pos)

func animate_card_to_position(card: Node, new_position: Vector2) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func remove_card_from_hand(card: Node) -> void:
	if card in player_hand:
		player_hand.erase(card)
		if card.get_parent() == self:
			remove_child(card)
		card.queue_free()
		update_hand_position()

func get_hand_size() -> int:
	return player_hand.size()

func get_card_nodes() -> Array:
	return player_hand.duplicate()
