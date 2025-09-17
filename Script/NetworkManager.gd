# NetworkManager.gd
extends Node

const DEFAULT_PORT = 7777
const DEFAULT_IP = "127.0.0.1" # Use localhost for easy testing

var players = {}
var current_turn_id = 0

func _ready():
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

func start_or_join():
	# First, try to join an existing game
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_IP, DEFAULT_PORT)
	if error != OK:
		print("Could not create client.")
		return

	multiplayer.multiplayer_peer = peer
	print("Attempting to join game...")

func create_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT)
	multiplayer.multiplayer_peer = peer
	print("No game found. Created a new server.")

	# The host is player 1
	players[1] = {"name": "Host", "stats": []}
	# Go to the prep menu immediately
	get_tree().change_scene_to_file("res://Scene/Prep_menu.tscn")

func connected_to_server():
	print("Successfully joined game!")
	# We joined a server, so we can go to the prep menu
	get_tree().change_scene_to_file("res://Scene/Prep_menu.tscn")

func connection_failed():
	print("Connection failed. Assuming host role.")
	# If we can't connect, it means no server exists. So, we become the server.
	create_server()

func player_connected(id: int):
	print("Player %s connected." % id)
	if multiplayer.is_server():
		for player_id in players:
			rpc_id(id, "register_player", players[player_id])
		rpc("register_player", {"name": "Player %s" % id, "stats": []}, id)

func player_disconnected(id: int):
	print("Player %s disconnected." % id)
	players.erase(id)
	rpc("player_left", id)

@rpc("any_peer", "call_local")
func register_player(player_info: Dictionary, id: int):
	players[id] = player_info
	print("Registered player %s: %s" % [id, player_info.name])

@rpc("any_peer", "call_local")
func player_left(id: int):
	players.erase(id)
	print("Player %s left the game." % id)
