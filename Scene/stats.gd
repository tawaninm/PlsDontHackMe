# PlayerStats.gd
class_name PlayerStats
extends Node

var player_name: String
var stats = {
	"integrity": 0,
	"bandwidth": 0,
	"packetloss_percentage": 0,
}

func initialize_stats(player_num: int) -> void:
	match player_num:
		1:
			player_name = "Player 1"
			stats["integrity"] = 100
			stats["bandwidth"] = 20
			stats["packetloss_percentage"] = 0
		2:
			player_name = "Player 2"
			stats["integrity"] = 100
			stats["bandwidth"] = 20
			stats["packetloss_percentage"] = 0
		3:
			player_name = "Player 3"
			stats["integrity"] = 100
			stats["bandwidth"] = 20
			stats["packetloss_percentage"] = 0
		4:
			player_name = "Player 4"
			stats["integrity"] = 100
			stats["bandwidth"] = 20
			stats["packetloss_percentage"] = 0
