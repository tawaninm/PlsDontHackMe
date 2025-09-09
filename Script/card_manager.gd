extends Node2D

const COLLISIONMASK_CARD = 1
const COLLISIONMASK_CARD_SLOT = 2

var card_being_dragged
var screen_size
var player_hand_reference
var last_hovered_card = null

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../Input".connect("left_mouse_button_clicked", on_left_click)

func _process(_delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(
			clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y)
		)
	else:
		var current_hovered_card = raycast_check_for_card()
		
		if current_hovered_card != last_hovered_card:
			if last_hovered_card:
				hightlight_card(last_hovered_card, false)
			
			if current_hovered_card:
				hightlight_card(current_hovered_card, true)
			
			last_hovered_card = current_hovered_card

func on_card_pressed(card):
	print("pressed %s" % card.name)
	player_hand_reference.remove_card_from_hand(card)

func on_left_click():
	print("clicked")

func hightlight_card(card, hovered):
	if card and card.name.begins_with("Card_"):
		if hovered:
			card.scale = Vector2(0.21, 0.21)
			card.z_index = 2
		else:
			card.scale = Vector2(0.2, 0.2)
			card.z_index = 1

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISIONMASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISIONMASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
