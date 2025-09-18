# res://Scripts/GameManager.gd
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
		"Cat": return 3
		"CorruptedScript": return 2
		"VirusAttack": return 5
		"Overclock": return 4
		_: return 1

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

	func _init(human: bool = false, hp: int = STARTING_INTEGRITY, bw: int = STARTING_BANDWIDTH, pl: int = STARTING_PACKETLOSS) -> void:
		integrity = hp
		bandwidth = bw
		packetloss = pl
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

const CARD_SCENE := preload("res://Scene/card.tscn")  # ensure this path is correct

# -----------------------------
# reliable autoload check helper
func _get_prep_node() -> Node:
	var root = get_tree().root
	if root.has_node("PrepToGameManager"):
		return root.get_node("PrepToGameManager")
	return null


func _ready() -> void:
	var prep_node = _get_prep_node()
	var p1_hp := STARTING_INTEGRITY
	var p1_bw := STARTING_BANDWIDTH
	var p1_pl := STARTING_PACKETLOSS

	if prep_node:
		p1_hp = prep_node.p1_integrity
		p1_bw = prep_node.p1_bandwidth
		p1_pl = prep_node.p1_packetloss
		print("GameManager: Loaded from PrepToGameManager -> HP:%d BW:%d PL:%d" % [p1_hp, p1_bw, p1_pl])
	else:
		push_warning("PrepToGameManager autoload not found; using defaults.")

	players = [
		Player.new(true, p1_hp, p1_bw, p1_pl),
		Player.new(false),
		Player.new(false)
	]

	current_player_index = 0
	print("GameManager ready with %d players" % players.size())
	update_ui()
	# Note: the scene that instantiates GameManager must call register_scene_nodes(...) afterwards
	# (somewhere in your main scene script) so player_hands, deck, etc. are linked.

# =============================
# --- SCENE CONNECTIONS ---
# =============================
func register_scene_nodes(cm: Node, hands: Array, d: Node, ui: Array, tc: Node) -> void:
	card_manager = cm
	player_hands = hands
	deck = d
	ui_nodes = ui
	turn_controls = tc

	# Connect deck draw signal if present
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

	# Skip turns
	if player.skip_turns > 0:
		player.skip_turns -= 1
		print("Player %d skips turn. Remaining skips: %d" % [current_player_index + 1, player.skip_turns])
		end_turn()
		return

	# Passive corruption effect
	if "corrupted" in player.status_effects:
		player.integrity = max(0, player.integrity - 2)
		print("CorruptedScript: Player %d loses 2 integrity" % [current_player_index + 1])

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
# --- CARD INTERACTION (input) ---
# =============================
func card_clicked_from_input_at_position(pos: Vector2, button_index: int) -> void:
	# Raycast at world pos
	var space_state = get_tree().root.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collision_mask = 1  # adjust match your card mask
	var result = space_state.intersect_point(params)

	if result.is_empty():
		return

	var collider = result[0].collider
	if not collider:
		return

	var card_node = collider.get_parent()
	if not card_node or not card_node.has_method("get_card_data"):
		return

	# Use index-based flow so we can remove from correct player's hand
	if button_index == MOUSE_BUTTON_LEFT:
		_try_use_card_by_node(current_player_index, card_node)
	elif button_index == MOUSE_BUTTON_RIGHT:
		_try_throw_card_by_node(current_player_index, card_node)

# new: uses card_node consistently (player.hand stores nodes)
func _try_use_card_by_node(player_index: int, card_node: Node) -> void:
	if player_index < 0 or player_index >= players.size():
		return
	var player = players[player_index]
	var data : Dictionary = card_node.get_card_data()
	var cost = data.get("cost", 0)

	if player.bandwidth < cost:
		print("Not enough bandwidth to use '%s' (cost %d)" % [data.get("name","?"), cost])
		return

	# spend cost and packetloss
	player.bandwidth = max(0, player.bandwidth - cost)
	player.packetloss = min(100, player.packetloss + USE_PACKETLOSS_GAIN)

	# apply effect via CardData (if autoloaded)
	if get_tree().has_node("/root/CardData"):
		var cd = get_tree().get_node("/root/CardData")
		cd.apply_effect(self, player, data)
	elif Engine.has_singleton("CardData"):
		CardData.apply_effect(self, player, data)
	else:
		push_warning("CardData singleton not found. Card effect skipped.")

	# remove from logical hand (card_node stored there)
	if card_node in player.hand:
		player.hand.erase(card_node)

	# remove visually through PlayerHand (if connected)
	if player_index < player_hands.size():
		var hand_node = player_hands[player_index]
		if hand_node and hand_node.has_method("remove_card_from_hand"):
			hand_node.remove_card_from_hand(card_node)
		else:
			card_node.queue_free()
	else:
		card_node.queue_free()

	print("Player %d played '%s' (cost %d). BW:%d PL:%d" % [player_index + 1, data.get("name","?"), cost, player.bandwidth, player.packetloss])

	update_ui()
	end_turn()

func _try_throw_card_by_node(player_index: int, card_node: Node) -> void:
	if player_index < 0 or player_index >= players.size():
		return
	var player = players[player_index]

	if player.bandwidth < THROW_BANDWIDTH_COST:
		print("Not enough bandwidth to throw a card (need %d)" % THROW_BANDWIDTH_COST)
		return

	player.bandwidth = max(0, player.bandwidth - THROW_BANDWIDTH_COST)
	player.packetloss = max(0, player.packetloss - THROW_PACKETLOSS_REDUCE)

	# remove from logical hand
	if card_node in player.hand:
		player.hand.erase(card_node)

	# remove visually
	if player_index < player_hands.size():
		var hand_node = player_hands[player_index]
		if hand_node and hand_node.has_method("remove_card_from_hand"):
			hand_node.remove_card_from_hand(card_node)
		else:
			card_node.queue_free()
	else:
		card_node.queue_free()

	print("Player %d threw away '%s' (BW now %d, PL %d)" % [player_index + 1, card_node.get_card_data().get("name","?"), player.bandwidth, player.packetloss])

	update_ui()
	end_turn()

# =============================
# --- ACTIONS ---
# =============================
func player_draw_card(player_index: int) -> void:
	if player_index < 0 or player_index >= players.size():
		push_error("Invalid player index: " + str(player_index))
		return

	var player = players[player_index]
	if player.hand.size() >= MAX_HAND_SIZE:
		print("Player %d cannot draw: hand full" % [player_index + 1])
		return

	# pick random card
	var card_types = ["Cat", "CorruptedScript", "VirusAttack", "Overclock"]
	var name = card_types[randi() % card_types.size()]

	var data := {
		"name": name,
		"cost": get_card_cost(name),
	}

	# instance node
	var card_node = CARD_SCENE.instantiate()
	if card_node.has_method("set_card_data"):
		card_node.set_card_data(data)
	else:
		# minimal fallback
		card_node.set("card_type", name)

	# logical & visual hand
	player.hand.append(card_node)

	if player_index < player_hands.size():
		var hand_node = player_hands[player_index]
		if hand_node and hand_node.has_method("add_card_to_hand"):
			hand_node.add_card_to_hand(card_node)
			print("Card '%s' added to Player %d hand via PlayerHand." % [name, player_index + 1])
		else:
			# fallback: add to scene directly under hand_node or root
			if hand_node:
				hand_node.add_child(card_node)
			else:
				add_child(card_node)
			print("Card '%s' added to scene for Player %d (fallback path)." % [name, player_index + 1])
	else:
		# if no player hand node assigned, add to root (fallback)
		add_child(card_node)
		print("Card '%s' added to root for Player %d (no PlayerHand node assigned)." % [name, player_index + 1])

	# stats adjustments
	player.bandwidth = min(player.bandwidth + DRAW_BANDWIDTH_GAIN, MAX_BANDWIDTH)
	player.packetloss = max(0, player.packetloss - DRAW_PACKETLOSS_REDUCE)

	print(">>> Player %d drew %s (BW:%d PL:%d)" % [player_index + 1, name, player.bandwidth, player.packetloss])
	update_ui()
	end_turn()

func player_skip_turn(player_index: int) -> void:
	if player_index < 0 or player_index >= players.size():
		return
	var player = players[player_index]
	player.bandwidth = min(player.bandwidth + SKIP_BANDWIDTH_GAIN, MAX_BANDWIDTH)
	print(">>> Player %d skips their turn (+%d BW). BW=%d" % [player_index + 1, SKIP_BANDWIDTH_GAIN, player.bandwidth])
	update_ui()
	end_turn()

# =============================
# --- UI (stub) ---
# =============================
func update_ui() -> void:
	# This prints the current in-memory player stats (useful for debugging)
	for i in range(players.size()):
		var p = players[i]
		print("Player %d | HP: %d | BW: %d | PL: %d | Hand: %d" % [i + 1, p.integrity, p.bandwidth, p.packetloss, p.hand.size()])
