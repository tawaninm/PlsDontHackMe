extends Node2D

const COLLISIONMASK_CARD = 1
const COLLISIONMASK_CARD_SLOT = 2

var card_being_dragged
var screen_size
var is_hovering_on_card

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x),
			clamp(mouse_pos.y, 0, screen_size.y))

func _input(event) :
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT :
		if event.pressed:
			var card = raycast_check_for_card()
			if card :
				start_drag(card)
		else :
			if card_being_dragged:
				finish_drag()

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(0.2,0.2)

func finish_drag():
	print("Runing")
	card_being_dragged.scale = Vector2(0.21,0.21)
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		print("card slot found")
		#card dropped in empty card slot
		card_being_dragged.position = card_slot_found.position
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		card_slot_found.card_in_slot = true
	card_being_dragged = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_hovered_over_card(card) :
	if !is_hovering_on_card:
		is_hovering_on_card = true
	hightlight_card(card,true)

func on_hovered_off_card(card) :
	if !card_being_dragged:
		hightlight_card(card,false)
		# check if hovered off card straight on to another card
		var new_card_horvered = raycast_check_for_card()
		if new_card_horvered:
			hightlight_card(new_card_horvered,true)
		else :
			is_hovering_on_card = false

func hightlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(0.21,0.21)
		card.z_index = 2
	else :
		card.scale = Vector2(0.2,0.2)
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
		return get_card_with_hightest_z_index(result)
	return null

func get_card_with_hightest_z_index(card) :
	var highest_z_card = card[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1,card.size()):
		var current_card = card[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
