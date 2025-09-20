# res://Scripts/GameManager.gd
extends Node

# =============================
# --- CONFIG / BALANCE KNOBS ---
# =============================
const MAX_HAND_SIZE := 15
const MAX_INTEGRITY := 100
const STARTING_INTEGRITY := 100
const STARTING_BANDWIDTH := 0
const STARTING_PACKETLOSS := 0
const MAX_BANDWIDTH := 20
const MIN_PACKETLOSS := 0

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
	var integrity = 0
	var bandwidth = 0
	var packetloss = 0
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

const CARD_SCENE := preload("res://Scene/card.tscn")  # make sure path matches your project

# -----------------------------
# Helper: try to obtain Prep values robustly
func _get_prep_values() -> Dictionary:
	var result := {
		"hp": STARTING_INTEGRITY,
		"bw": STARTING_BANDWIDTH,
		"pl": STARTING_PACKETLOSS
	}

	# 1) Preferred: autoload singleton
	if Engine.has_singleton("PrepToGameManager"):
		var prep = Engine.get_singleton("PrepToGameManager")
		if prep:
			var hp_val = prep.get("p1_integrity")
			var bw_val = prep.get("p1_bandwidth")
			var pl_val = prep.get("p1_packetloss")
			
			if hp_val != null:
				result.hp = int(hp_val)
			if bw_val != null:
				result.bw = int(bw_val)
			if pl_val != null:
				result.pl = int(pl_val)

		print("GameManager: read PrepToGameManager singleton -> HP:%d BW:%d PL:%d" % [result.hp, result.bw, result.pl])
		return result

	# 2) Fallback: node instance placed under the scene root
	var root = get_tree().root
	if root and root.has_node("PrepToGameManager"):
		var prep_node = root.get_node("PrepToGameManager")
		if prep_node:
			var hp_val = prep_node.get("p1_integrity")
			var bw_val = prep_node.get("p1_bandwidth")
			var pl_val = prep_node.get("p1_packetloss")

			if hp_val != null:
				result.hp = int(hp_val)
			if bw_val != null:
				result.bw = int(bw_val)
			if pl_val != null:
				result.pl = int(pl_val)

		print("GameManager: read PrepToGameManager scene node -> HP:%d BW:%d PL:%d" % [result.hp, result.bw, result.pl])
		return result

	# 3) Nothing found -> defaults
	push_warning("GameManager: PrepToGameManager not found; using defaults.")
	return result



# =============================
# --- SCENE CONNECTIONS ---
# =============================
func register_scene_nodes(cm: Node, hands: Array, d: Node, ui: Array, tc: Node) -> void:
	card_manager = cm
	player_hands = hands
	deck = d
	ui_nodes = ui
	turn_controls = tc

	# connect deck draw
	if deck and deck.has_signal("draw_requested"):
		if not deck.is_connected("draw_requested", Callable(self, "_on_deck_draw_requested")):
			deck.connect("draw_requested", Callable(self, "_on_deck_draw_requested"))

func _on_deck_draw_requested() -> void:
	player_draw_card(current_player_index)

func start_game() -> void:
	# Initialize players if not already
	if players.is_empty():
		players = [
			Player.new(true),
			Player.new(false),
			Player.new(false)
		]
		var prep_stats = _get_prep_values()
		players[0].integrity = prep_stats.hp
		players[0].bandwidth = prep_stats.bw
		players[0].packetloss = prep_stats.pl

	if players.is_empty():
		push_error("GameManager: No players defined after setup!")
		return

	current_player_index = 0
	print("Game started with %d players" % players.size())


# =============================
# --- TURN SYSTEM ---
# =============================
func start_turn() -> void:
	var player = players[current_player_index]

	if player.skip_turns > 0:
		player.skip_turns -= 1
		print("Player %d skips turn. Remaining skips: %d" % [current_player_index + 1, player.skip_turns])
		end_turn()
		return

	# Count CorruptedScript cards in hand (stacks)
	var corrupted_count = 0
	for card in player.hand:
		if card.has_method("get_card_data"):
			var data = card.get_card_data()
			if data.get("name") == "CorruptedScript":
				corrupted_count += 1

	if corrupted_count > 0:
		var loss = 2 * corrupted_count
		player.integrity = max(0, player.integrity - loss)
		print("CorruptedScript: Player %d loses %d integrity (%d in hand)" %
			[current_player_index + 1, loss, corrupted_count])

	if player.is_human:
		if turn_controls:
			turn_controls.show()
	else:
		player_skip_turn(current_player_index)



func end_turn() -> void:
	if turn_controls:
		turn_controls.hide()
	current_player_index = (current_player_index + 1) % players.size()
	start_turn()

# =============================
# --- CARD INTERACTION (input) ---
# =============================
func card_clicked_from_input_at_position(pos: Vector2, button_index: int) -> void:
	var space_state = get_tree().root.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collide_with_areas = true
	params.collision_mask = 1
	var result = space_state.intersect_point(params)
	if result.is_empty():
		return
	var collider = result[0].collider
	if not collider:
		return
	var card_node = collider.get_parent()
	if not card_node or not card_node.has_method("get_card_data"):
		return

	if button_index == MOUSE_BUTTON_LEFT:
		var data = card_node.get_card_data()
		if data.get("name") == "CorruptedScript":
			print("CorruptedScript is a passive curse and cannot be used.")
			return
		else:_try_use_card(current_player_index, card_node)




# operate on node references (player.hand stores nodes)
func _try_use_card(player_index: int, card_node: Node) -> void:
	if player_index < 0 or player_index >= players.size():
		return
	var player = players[player_index]
	var data : Dictionary = card_node.get_card_data()

	# Block passive curse cards
	var name = data.get("name", "")
	if name == "CorruptedScript":
		print("'%s' is a passive curse card and cannot be played." % name)
		return

	var cost = data.get("cost", 0)
	if player.bandwidth < cost:
		print("Not enough bandwidth to use '%s' (cost %d)" % [name, cost])
		return


	player.bandwidth = max(0, player.bandwidth - cost)
	player.packetloss = min(100, player.packetloss + USE_PACKETLOSS_GAIN)

	# apply effect (CardData autoload or node)
	if Engine.has_singleton("CardData"):
		CardData.apply_effect(self, player, data)
	elif get_tree().root.has_node("CardData"):
		get_tree().root.get_node("CardData").apply_effect(self, player, data)

	# remove from logical hand and visual
	if card_node in player.hand:
		player.hand.erase(card_node)
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

func _try_throw_card(player_index: int, card_node: Node) -> void:
	if player_index < 0 or player_index >= players.size():
		return
	var player = players[player_index]
	if player.bandwidth < THROW_BANDWIDTH_COST:
		print("Not enough bandwidth to throw a card (need %d)" % THROW_BANDWIDTH_COST)
		return

	player.bandwidth = max(0, player.bandwidth - THROW_BANDWIDTH_COST)
	player.packetloss = max(0, player.packetloss - THROW_PACKETLOSS_REDUCE)

	if card_node in player.hand:
		player.hand.erase(card_node)

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

	var card_types = ["Cat", "CorruptedScript", "VirusAttack", "Overclock"]
	var name = card_types[randi() % card_types.size()]

	var data := {
		"name": name,
		"cost": get_card_cost(name),
	}

	var card_node = CARD_SCENE.instantiate()
	if card_node.has_method("set_card_data"):
		card_node.set_card_data(data)
	else:
		card_node.set("card_type", name)

	player.hand.append(card_node)

	if player_index < player_hands.size():
		var hand_node = player_hands[player_index]
		if hand_node and hand_node.has_method("add_card_to_hand"):
			hand_node.add_card_to_hand(card_node)
			print("Card '%s' added to Player %d hand via PlayerHand." % [name, player_index + 1])
		else:
			if hand_node:
				hand_node.add_child(card_node)
			else:
				add_child(card_node)
			print("Card '%s' added to scene for Player %d (fallback path)." % [name, player_index + 1])
	else:
		add_child(card_node)
		print("Card '%s' added to root for Player %d (no PlayerHand node assigned)." % [name, player_index + 1])

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
	for i in range(players.size()):
		var p = players[i]
		print("Player %d | HP: %d | BW: %d | PL: %d | Hand: %d" % [i + 1, p.integrity, p.bandwidth, p.packetloss, p.hand.size()])

# =============================
# --- COMPATIBILITY WRAPPERS ---
# =============================

# Check if a player has enough BW to play a card
func can_use_card(player: Player, data: Dictionary) -> bool:
	return player.bandwidth >= data.get("cost", 0)

# Use a card (wrapper for _try_use_card)
func use_card(player_index: int, card_node: Node) -> void:
	_try_use_card(player_index, card_node)

# Check if a player has enough BW to throw a card
func can_throw_card(player: Player) -> bool:
	return player.bandwidth >= THROW_BANDWIDTH_COST

# Throw a card (wrapper for _try_throw_card)
func throw_card(player_index: int, card_node: Node) -> void:
	_try_throw_card(player_index, card_node)
