
extends Node

func _ready() -> void:
	var player1_name = "player1"
	var player1_integrity = 10
	var player1_bandwidth = 0
	var player1_packetloss = 100

	var player2_name = "player2"
	var player2_integrity = 10
	var player2_bandwidth = 0
	var player2_packetloss = 100

	var player3_name = "player3"
	var player3_integrity = 10
	var player3_bandwidth = 0
	var player3_packetloss = 100

	$"../Player1Health".text = str(player1_integrity)
