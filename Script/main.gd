extends Node2D

# =============================
# --- CONFIG / BALANCE KNOBS ---
# =============================
const MAX_HAND_SIZE := 15
const MAX_INTEGRITY := 100
const STARTING_INTEGRITY := 100
const STARTING_BANDWIDTH := 0
const STARTING_PACKETLOSS := 0
const MAX_BANDWIDTH := 20
const MAX_PACKETLOSS := 100
const MIN_PACKETLOSS := 0

const DRAW_BANDWIDTH_GAIN := 2
const DRAW_PACKETLOSS_REDUCE := 10
const USE_PACKETLOSS_GAIN := 15
const THROW_PACKETLOSS_REDUCE := 20
const THROW_BANDWIDTH_COST := 4
const SKIP_BANDWIDTH_GAIN := 2

const CARD_SCENE := preload("res://Scene/card.tscn")

# ----------------------------
# Per-player simple variables (kept in sync with players[])
# ----------------------------
var player1_integrity := STARTING_INTEGRITY
var player1_bandwidth := STARTING_BANDWIDTH
var player1_packetloss := STARTING_PACKETLOSS
var player1_skip_turns := 0

var player2_integrity := STARTING_INTEGRITY
var player2_bandwidth := STARTING_BANDWIDTH
var player2_packetloss := STARTING_PACKETLOSS
var player2_skip_turns := 0

var player3_integrity := STARTING_INTEGRITY
var player3_bandwidth := STARTING_BANDWIDTH
var player3_packetloss := STARTING_PACKETLOSS
var player3_skip_turns := 0

# scene node references (members only; assigned in _ready)
var card_manager: Node = null
var player_hands: Array = []
var deck: Node = null
var ui_nodes: Array = []
var turn_controls: Node = null

# Keep the original Player class & players array for compatibility
var players: Array = []
var current_player_index: int = 0
var turn_count: int = 0

# ----------------------------
# Player class (kept for compatibility)
# ----------------------------
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

# ----------------------------
# Prep values helper
# ----------------------------
func _get_prep_values() -> Dictionary:
	var result := {
		"hp": STARTING_INTEGRITY,
		"bw": STARTING_BANDWIDTH,
		"pl": STARTING_PACKETLOSS
	}

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

	var root = get_tree().get_current_scene()
	if root and root.has_node("PrepToGameManager"):
		var prep_node = root.get_node("PrepToGameManager")
		if prep_node:
			var hp_val2 = prep_node.get("p1_integrity")
			var bw_val2 = prep_node.get("p1_bandwidth")
			var pl_val2 = prep_node.get("p1_packetloss")
			if hp_val2 != null:
				result.hp = int(hp_val2)
			if bw_val2 != null:
				result.bw = int(bw_val2)
			if pl_val2 != null:
				result.pl = int(pl_val2)
		print("GameManager: read PrepToGameManager scene node -> HP:%d BW:%d PL:%d" % [result.hp, result.bw, result.pl])
		return result

	push_warning("GameManager: PrepToGameManager not found; using defaults.")
	return result

# ----------------------------
# Scene wiring
# ----------------------------
func register_scene_nodes(cm_node: Node, hands_arr: Array, d_node: Node, ui_arr: Array, tc_node: Node) -> void:
	card_manager = cm_node
	player_hands = hands_arr
	deck = d_node
	ui_nodes = ui_arr
	turn_controls = tc_node

	# connect deck draw signal if present
	if deck and deck.has_signal("draw_requested"):
		if not deck.is_connected("draw_requested", Callable(self, "_on_deck_draw_requested")):
			deck.connect("draw_requested", Callable(self, "_on_deck_draw_requested"))

	# inject gm to nodes that accept it
	if card_manager and card_manager.has_method("set_gm"):
		card_manager.set_gm(self)
	if turn_controls and turn_controls.has_method("set_gm"):
		turn_controls.set_gm(self)
	if deck and deck.has_method("set_gm"):
		deck.set_gm(self)
	for i in range(player_hands.size()):
		var hn = player_hands[i]
		if hn and hn.has_method("set_gm"):
			hn.set_gm(self)
	for u in ui_nodes:
		if u and u.has_method("set_gm"):
			u.set_gm(self)

func _on_deck_draw_requested() -> void:
	player_draw_card(current_player_index)

# ----------------------------
# Startup
# ----------------------------
func _ready() -> void:
	card_manager = $CardManager
	deck = $Board/Draw
	player_hands = [
		$PlayerHand,
		$PlayerHand2,
		$PlayerHand3
	]
	ui_nodes = [
		$CanvasLayer/UI/PlayerUI1,
		$CanvasLayer/UI/PlayerUI2,
		$CanvasLayer/UI/PlayerUI3
	]
	turn_controls = $TurnControls

	register_scene_nodes(card_manager, player_hands, deck, ui_nodes, turn_controls)
	start_game()

# ----------------------------
# Utility helpers (sync players[] <-> simple vars)
# ----------------------------
func _valid_player_index(i: int) -> bool:
	return i >= 0 and i < players.size()

func _sync_player_to_vars(i: int) -> void:
	if not _valid_player_index(i):
		return
	var p = players[i]
	match i:
		0:
			player1_integrity = p.integrity
			player1_bandwidth = p.bandwidth
			player1_packetloss = p.packetloss
			player1_skip_turns = p.skip_turns
		1:
			player2_integrity = p.integrity
			player2_bandwidth = p.bandwidth
			player2_packetloss = p.packetloss
			player2_skip_turns = p.skip_turns
		2:
			player3_integrity = p.integrity
			player3_bandwidth = p.bandwidth
			player3_packetloss = p.packetloss
			player3_skip_turns = p.skip_turns

func _sync_all_players_to_vars() -> void:
	for i in range(players.size()):
		_sync_player_to_vars(i)

func _add_integrity(i: int, amount: int) -> void:
	if not _valid_player_index(i):
		return
	players[i].integrity = clamp(players[i].integrity + amount, 0, MAX_INTEGRITY)
	_sync_player_to_vars(i)

func _add_bandwidth(i: int, amount: int) -> void:
	if not _valid_player_index(i):
		return
	players[i].bandwidth = clamp(players[i].bandwidth + amount, 0, MAX_BANDWIDTH)
	_sync_player_to_vars(i)

func _add_packetloss(i: int, amount: int) -> void:
	if not _valid_player_index(i):
		return
	players[i].packetloss = clamp(players[i].packetloss + amount, 0, MAX_PACKETLOSS)
	_sync_player_to_vars(i)

func _add_skip_turns(i: int, amount: int) -> void:
	if not _valid_player_index(i):
		return
	players[i].skip_turns = max(0, players[i].skip_turns + amount)
	_sync_player_to_vars(i)

func _get_integrity(i: int) -> int:
	if not _valid_player_index(i):
		return 0
	return players[i].integrity

func _get_bandwidth(i: int) -> int:
	if not _valid_player_index(i):
		return 0
	return players[i].bandwidth

func _get_packetloss(i: int) -> int:
	if not _valid_player_index(i):
		return 0
	return players[i].packetloss

func _get_skip_turns(i: int) -> int:
	if not _valid_player_index(i):
		return 0
	return players[i].skip_turns

func _get_player_hand(i: int) -> Array:
	if not _valid_player_index(i):
		return []
	return players[i].hand

# ----------------------------
# Card cost lookup
# ----------------------------
func get_card_cost(name: String) -> int:
	match name:
		"Cat": return 3
		"CorruptedScript": return 2
		"VirusAttack": return 5
		"Overclock": return 4
		_: return 1

# ----------------------------
# Game flow
# ----------------------------
func start_game() -> void:
	# Initialize players if empty
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

	# ensure simple vars reflect players[]
	_sync_all_players_to_vars()

	current_player_index = 0
	print("Game started with %d players" % players.size())
	start_turn()

func start_turn() -> void:
	if not _valid_player_index(current_player_index):
		return

	var player = players[current_player_index]

	# handle skip turns
	if _get_skip_turns(current_player_index) > 0:
		_add_skip_turns(current_player_index, -1)
		print("Player %d skips turn. Remaining skips: %d" % [current_player_index + 1, _get_skip_turns(current_player_index)])
		end_turn()
		return

	# corrupted card passive effect: lose 2 integrity per corrupted in hand
	var corrupted_count := 0
	for card in player.hand:
		if card and card.has_method("get_card_data"):
			var data = card.get_card_data()
			if data.get("name") == "CorruptedScript":
				corrupted_count += 1

	if corrupted_count > 0:
		var loss = 2 * corrupted_count
		_add_integrity(current_player_index, -loss)
		print("CorruptedScript: Player %d loses %d integrity (%d in hand)" %
			[current_player_index + 1, loss, corrupted_count])

	# show turn controls for human players
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

# ----------------------------
# Input -> card selection (left & right click)
# ----------------------------
func card_clicked_from_input_at_position(pos: Vector2, button_index: int) -> void:
	var space_state = get_world_2d().direct_space_state
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

	# Guard: ensure the card is in the current player's logical hand (prevents double-calls)
	if not _valid_player_index(current_player_index):
		return
	var player = players[current_player_index]
	if not (card_node in player.hand):
		# card not owned by player or already played/removed; ignore
		print("card_clicked: card not in player's hand, ignoring.")
		return

	if button_index == MOUSE_BUTTON_LEFT:
		var data = card_node.get_card_data()
		if data.get("name") == "CorruptedScript":
			print("CorruptedScript is a passive curse and cannot be used.")
			return
		_try_use_card(current_player_index, card_node)
	elif button_index == MOUSE_BUTTON_RIGHT:
		# Attempt to throw away (right click)
		if can_throw_card(player):
			_try_throw_card(current_player_index, card_node)
		else:
			print("Not enough bandwidth to throw a card.")

# ----------------------------
# Card usage (with guards and updated UI calls)
# ----------------------------
func _try_use_card(player_index: int, card_node: Node) -> void:
	if not _valid_player_index(player_index):
		return
	var player = players[player_index]
	var data : Dictionary = card_node.get_card_data()

	# Block passive curse cards
	var name = data.get("name", "")
	if name == "CorruptedScript":
		print("'%s' is a passive curse card and cannot be played." % name)
		return

	var cost = data.get("cost", 0)
	if _get_bandwidth(player_index) < cost:
		print("Not enough bandwidth to use '%s' (cost %d)" % [name, cost])
		return

	# --- Pay cost ---
	_add_bandwidth(player_index, -cost)
	_add_packetloss(player_index, USE_PACKETLOSS_GAIN)

	# --- Apply card effect ---
	# NOTE: keep passing the Player object for backwards compatibility
	if Engine.has_singleton("CardData"):
		CardData.apply_effect(self, player, data)
	elif get_tree().get_current_scene() and get_tree().get_current_scene().has_node("CardData"):
		get_tree().get_current_scene().get_node("CardData").apply_effect(self, player, data)

	# --- Remove card from logical hand + visual ---
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

	print("Player %d played '%s' (cost %d). BW:%d PL:%d" %
		[player_index + 1, data.get("name","?"), cost, _get_bandwidth(player_index), _get_packetloss(player_index)])

	# --- Always update UI after changes ---
	update_ui()
	end_turn()

func _try_throw_card(player_index: int, card_node: Node) -> void:
	if not _valid_player_index(player_index):
		return
	var player = players[player_index]
	if _get_bandwidth(player_index) < THROW_BANDWIDTH_COST:
		print("Not enough bandwidth to throw a card (need %d)" % THROW_BANDWIDTH_COST)
		return

	# --- Apply discard costs/benefits ---
	_add_bandwidth(player_index, -THROW_BANDWIDTH_COST)
	_add_packetloss(player_index, -THROW_PACKETLOSS_REDUCE)

	# --- Remove from hand (logical + visual) ---
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

	print("Player %d threw away '%s' (BW now %d, PL %d)" %
		[player_index + 1, card_node.get_card_data().get("name","?"),
		_get_bandwidth(player_index), _get_packetloss(player_index)])

	# --- Always update UI after changes ---
	update_ui()
	end_turn()

# ----------------------------
# Actions (draw / skip)
# ----------------------------
func player_draw_card(player_index: int) -> void:
	if not _valid_player_index(player_index):
		push_error("Invalid player index: " + str(player_index))
		return

	var player = players[player_index]
	if player.hand.size() >= MAX_HAND_SIZE:
		print("Player %d cannot draw: hand full" % [player_index + 1])
		return

	# --- Pick random card ---
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

	# --- Add visually ---
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

	# --- Draw rewards ---
	_add_bandwidth(player_index, DRAW_BANDWIDTH_GAIN)
	_add_packetloss(player_index, -DRAW_PACKETLOSS_REDUCE)

	print(">>> Player %d drew %s (BW:%d PL:%d)" % [player_index + 1, name, _get_bandwidth(player_index), _get_packetloss(player_index)])

	# --- Always update UI after changes ---
	update_ui()
	end_turn()


func player_skip_turn(player_index: int) -> void:
	if not _valid_player_index(player_index):
		return
	_add_bandwidth(player_index, SKIP_BANDWIDTH_GAIN)
	print(">>> Player %d skips their turn (+%d BW). BW=%d" % [player_index + 1, SKIP_BANDWIDTH_GAIN, _get_bandwidth(player_index)])
	update_ui()
	end_turn()

# ----------------------------
# UI updates
# ----------------------------
func update_ui() -> void:
	# --- Debug printout ---
	print("Player 1 | HP:%d BW:%d PL:%d" % [player1_integrity, player1_bandwidth, player1_packetloss])
	print("Player 2 | HP:%d BW:%d PL:%d" % [player2_integrity, player2_bandwidth, player2_packetloss])
	print("Player 3 | HP:%d BW:%d PL:%d" % [player3_integrity, player3_bandwidth, player3_packetloss])

	# --- Update UI panels if they exist ---
	if ui_nodes.size() > 0 and ui_nodes[0] and ui_nodes[0].has_method("set_gm"):
		ui_nodes[0].set_gm(self)
		ui_nodes[0].update_ui_for_player1()

	if ui_nodes.size() > 1 and ui_nodes[1] and ui_nodes[1].has_method("set_gm"):
		ui_nodes[1].set_gm(self)
		if ui_nodes[1].has_method("update_ui_for_player2"):
			ui_nodes[1].update_ui_for_player2()

	if ui_nodes.size() > 2 and ui_nodes[2] and ui_nodes[2].has_method("set_gm"):
		ui_nodes[2].set_gm(self)
		if ui_nodes[2].has_method("update_ui_for_player3"):
			ui_nodes[2].update_ui_for_player3()



# ----------------------------
# Compatibility wrappers
# ----------------------------
# can_use_card accepts either a Player object or an integer index (keeps compatibility)
func can_use_card(player_or_index, data: Dictionary) -> bool:
	var cost = data.get("cost", 0)
	if player_or_index is int:
		return _get_bandwidth(player_or_index) >= cost
	elif typeof(player_or_index) == TYPE_OBJECT:
		# assume it's a Player object
		return player_or_index.bandwidth >= cost
	elif typeof(player_or_index) == TYPE_DICTIONARY:
		return int(player_or_index.get("bandwidth", 0)) >= cost
	return false

func use_card(player_index: int, card_node: Node) -> void:
	_try_use_card(player_index, card_node)

func can_throw_card(player_or_index) -> bool:
	if player_or_index is int:
		return _get_bandwidth(player_or_index) >= THROW_BANDWIDTH_COST
	elif typeof(player_or_index) == TYPE_OBJECT:
		return player_or_index.bandwidth >= THROW_BANDWIDTH_COST
	elif typeof(player_or_index) == TYPE_DICTIONARY:
		return int(player_or_index.get("bandwidth", 0)) >= THROW_BANDWIDTH_COST
	return false

func throw_card(player_index: int, card_node: Node) -> void:
	_try_throw_card(player_index, card_node)
