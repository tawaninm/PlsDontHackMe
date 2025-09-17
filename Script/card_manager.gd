extends Node2D

const COLLISIONMASK_CARD = 1

var screen_size: Vector2
var last_hovered_card: Node = null

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _process(_delta: float) -> void:
	var current_hovered_card = raycast_check_for_card()
	if current_hovered_card != last_hovered_card:
		if last_hovered_card:
			highlight_card(last_hovered_card, false)
		if current_hovered_card:
			highlight_card(current_hovered_card, true)
		last_hovered_card = current_hovered_card

# Called by GameManager whenever it instantiates a new card
func register_card_instance(card_node: Node) -> void:
	if not card_node:
		return
	if not is_connected("card_played", Callable(self, "_on_card_played")):
		connect("card_played", Callable(self, "_on_card_played"))


# Handler when a card emits clicked
func _on_card_clicked(card_node: Node) -> void:
	# forward to GameManager for selection logic
	if Engine.has_singleton("GameManager"):
		# GameManager is expected to be an autoload
		GameManager.select_card(card_node)

func highlight_card(card: Node, hovered: bool) -> void:
	if not card:
		return
	if hovered:
		card.scale = Vector2(0.21, 0.21)
		card.z_index = 2
	else:
		card.scale = Vector2(0.2, 0.2)
		card.z_index = 1

func raycast_check_for_card() -> Node:
	var world = get_viewport().get_world_2d()
	if not world:
		return null
	var space_state = world.direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = get_global_mouse_position()
	params.collide_with_areas = true
	params.collision_mask = COLLISIONMASK_CARD
	var result = space_state.intersect_point(params)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards: Array) -> Node:
	var highest_z_card: Node = cards[0].collider.get_parent()
	var highest_z_index: int = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card: Node = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	# only allow hover if card owner matches current player (so human doesn't hover others' cards)
	if highest_z_card and highest_z_card.has_method("get_card_owner"):
		if highest_z_card.get_card_owner() == GameManager.current_player_index:
			return highest_z_card
	return null
