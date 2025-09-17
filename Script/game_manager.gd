extends Node

# =============================
# --- CONFIG / BALANCE KNOBS ---
# =============================

const MAX_HAND_SIZE := 15
const STARTING_INTEGRITY := 100
const STARTING_BANDWIDTH := 0
const STARTING_PACKETLOSS := 0
const MAX_BANDWIDTH := 20

const DRAW_BANDWIDTH_GAIN := 2
const DRAW_PACKETLOSS_REDUCE := 10

const USE_PACKETLOSS_GAIN := 15

const THROW_PACKETLOSS_REDUCE := 20
const THROW_BANDWIDTH_COST := 4

const SKIP_BANDWIDTH_GAIN := 2

var turn_count: int = 0

func get_card_cost(name: String) -> int:
	match name:
		"Cat":
			return 3
		"CorruptedScript":
			return 2
		"VirusAttack":
			return 5
		"Overclock":
			return 4
		_:
			return 1


# =============================
# --- PLAYER STATE ---
# =============================

class Player:
	var integrity: int
	var bandwidth: int
	var packetloss: int
	var skip_turns: int
	var hand: Array
	var status_effects: Array
	var is_human: bool

	func _init(human: bool = false) -> void:
		integrity = STARTING_INTEGRITY
		bandwidth = STARTING_BANDWIDTH
		packetloss = STARTING_PACKETLOSS
		skip_turns = 0
		hand = []
		status_effects = []
		is_human = human

# =============================
# --- GAME STATE ---
# =============================

var players: Array = []
var current_player_index: int = 0

var card_manager: Node = null
var player_hands: Array = []
var deck: Node = null
var ui_nodes: Array = []
var turn_controls: Node = null

func _ready() -> void:
	# 3 players: 1 human, 2 AI
	players = [
		Player.new(true),
		Player.new(false),
		Player.new(false)
	]
	current_player_index = 0
	print("GameManager ready with 3 players")

# =============================
# --- SCENE CONNECTIONS ---
# =============================

func register_scene_nodes(cm: Node, hands: Array, d: Node, ui: Array, tc: Node) -> void:
	card_manager = cm
	player_hands = hands
	deck = d
	ui_nodes = ui
	turn_controls = tc

	# Connect deck draw signal
	if deck and deck.has_signal("draw_requested"):
		if not deck.is_connected("draw_requested", Callable(self, "_on_deck_draw_requested")):
			deck.connect("draw_requested", Callable(self, "_on_deck_draw_requested"))

func _on_deck_draw_requested() -> void:
	player_draw_card(current_player_index)

func start_game() -> void:
	if players.is_empty():
		push_error("GameManager: No players defined!")
		return
	current_player_index = 0
	turn_count = 1
	update_ui()
	start_turn()

# =============================
# --- TURN SYSTEM ---
# =============================

func start_turn() -> void:
	var player = players[current_player_index]

	# Skip turns if needed
	if player.skip_turns > 0:
		player.skip_turns -= 1
		print("Player", current_player_index + 1, "skips turn. Remaining skips:", player.skip_turns)
		end_turn()
		return

	# Passive corruption effect
	if "corrupted" in player.status_effects:
		player.integrity -= 2
		print("CorruptedScript: Player", current_player_index + 1, "loses 2 integrity")

	# Show controls for human
	if player.is_human:
		if turn_controls:
			turn_controls.show()
	else:
		# Simple AI: skip turn
		player_skip_turn(current_player_index)

	update_ui()

func end_turn() -> void:
	if turn_controls:
		turn_controls.hide()

	current_player_index = (current_player_index + 1) % players.size()
	start_turn()

# =============================
# --- CARD INTERACTION ---
# =============================

func card_clicked_from_input_at_position(pos: Vector2, button_index: int) -> void:
	var space_state = get_tree().root.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collision_mask = 1  # Adjust to match your card mask
	var result = space_state.intersect_point(params)

	if result.is_empty():
		return

	var collider = result[0].collider
	if collider == null:
		return

	var card_node = collider.get_parent()
	if card_node == null or not card_node.has_method("get_card_data"):
		return

	var player = players[current_player_index]
	var card_data = card_node.get_card_data()

	if button_index == MOUSE_BUTTON_LEFT:
		_try_use_card(player, card_data, card_node)
	elif button_index == MOUSE_BUTTON_RIGHT:
		_try_throw_card(player, card_data, card_node)

func _try_use_card(player: Player, card_data: Dictionary, card_node: Node) -> void:
	var cost = card_data.get("cost", 0)

	if player.bandwidth < cost:
		print("Not enough bandwidth!")
		return

	player.bandwidth -= cost
	player.packetloss += USE_PACKETLOSS_GAIN

	# Apply effect from CardData.gd
	if Engine.has_singleton("CardData"):
		CardData.apply_effect(self, player, card_data)
	else:
		push_error("CardData not autoloaded!")

	# Remove card
	if card_data in player.hand:
		player.hand.erase(card_data)
	if card_node:
		card_node.queue_free()

	update_ui()
	end_turn()

func _try_throw_card(player: Player, card_data: Dictionary, card_node: Node) -> void:
	if player.bandwidth < THROW_BANDWIDTH_COST:
		print("Not enough bandwidth to throw card!")
		return

	player.bandwidth -= THROW_BANDWIDTH_COST
	player.packetloss = max(player.packetloss - THROW_PACKETLOSS_REDUCE, 0)

	# Remove card
	if card_data in player.hand:
		player.hand.erase(card_data)
	if card_node:
		card_node.queue_free()

	print("Player threw away", card_data.get("name", "Unknown Card"))
	update_ui()
	end_turn()

# =============================
# --- ACTIONS ---
# =============================

const CARD_SCENE := preload("res://Scene/card.tscn")

func player_draw_card(player_index: int) -> void:
	if player_index < 0 or player_index >= players.size():
		push_error("Invalid player index: " + str(player_index))
		return

	var player = players[player_index]
	if player.hand.size() >= MAX_HAND_SIZE:
		print("Player", player_index + 1, "cannot draw: hand full")
		return

	# --- Pick random card ---
	var card_types = ["Cat", "CorruptedScript", "VirusAttack", "Overclock"]
	var name = card_types[randi() % card_types.size()]

	var card_data := {
		"name": name,
		"cost": get_card_cost(name),
	}

	# --- Instance card node ---
	var card_node = CARD_SCENE.instantiate()
	if card_node.has_method("set_card_data"):
		card_node.set_card_data(card_data)

	# --- Store card_node directly ---
	player.hand.append(card_node)

	# --- Add to player's visual hand ---
	if player_index < player_hands.size():
		var hand_node = player_hands[player_index]
		if hand_node:
			var offset_x = 120 * hand_node.get_child_count()
			card_node.position = Vector2(offset_x, 0)
			hand_node.add_child(card_node)
			print("Card", name, "added to Player", player_index + 1, "hand.")
	else:
		push_error("No hand node for player " + str(player_index))

	# --- Adjust stats ---
	player.bandwidth = min(player.bandwidth + DRAW_BANDWIDTH_GAIN, MAX_BANDWIDTH)
	player.packetloss = max(0, player.packetloss - DRAW_PACKETLOSS_REDUCE)

	print("Player", player_index + 1, "drew", name)
	update_ui()
	end_turn()





func player_skip_turn(player_index: int) -> void:
	var player = players[player_index]
	player.bandwidth += SKIP_BANDWIDTH_GAIN
	print("Player", player_index + 1, "skips turn, +2 bandwidth")
	update_ui()
	end_turn()

# =============================
# --- UI (stub) ---
# =============================

func update_ui() -> void:
	for i in range(players.size()):
		var p = players[i]
		print("Player", i + 1, " | HP:", p.integrity, " BW:", p.bandwidth, " PL:", p.packetloss, " Hand:", p.hand.size())
