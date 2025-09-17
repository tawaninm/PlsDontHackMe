extends Node

# --- Global state ---
var is_host: bool = false
var game_started: bool = false
var player_stats: Dictionary = {}

# Multiplayer peer
var peer: ENetMultiplayerPeer

func _ready():
	print("[GameManager] Loaded. Waiting for Start button...")
	# Ensure autoloaded correctly
	if not multiplayer.multiplayer_peer:
		print("[GameManager] No network yet.")

# --- Start as Host ---
func start_host(port: int = 12345, max_players: int = 8) -> void:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, max_players)
	if err != OK:
		push_error("Failed to start server: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	print("[GameManager] Hosting on port %d" % port)

# --- Join a Host ---
func join_host(ip: String = "127.0.0.1", port: int = 12345) -> void:
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Failed to connect: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	is_host = false
	print("[GameManager] Joining host at %s:%d" % [ip, port])

# --- Remote function: receive stats from clients ---
@rpc("any_peer", "call_local")
func receive_player_stats(stats: Dictionary) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == 0: # Means this machine is host calling itself
		sender_id = 1
	player_stats[sender_id] = stats
	print("[GameManager] Received stats from peer %d: %s" % [sender_id, stats])


# --- Start the actual game ---
func start_game() -> void:
	if is_host:
		game_started = true
		rpc("sync_start_game")
		print("[GameManager] Host started the game.")

@rpc("authority", "call_local")
func sync_start_game() -> void:
	game_started = true
	print("[GameManager] Game has started for everyone!")
