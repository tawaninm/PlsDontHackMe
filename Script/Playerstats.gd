# res://Scripts/PlayerStats.gd
extends Control

@onready var health_label = $"../../../TurnControls/HBoxContainer/HealthLabel1"
@onready var bandwidth_label = $"../../../TurnControls/HBoxContainer/BandwidthLabel1"
@onready var packetloss_label = $"../../../TurnControls/HBoxContainer/PacketlossLabel1"

func update_ui(player_dict: Dictionary) -> void:
	if not player_dict:
		return
	health_label.bbcode_enabled = true
	bandwidth_label.bbcode_enabled = true
	packetloss_label.bbcode_enabled = true

	health_label.bbcode_text = "[color=#e5b931]%d[/color]" % player_dict.integrity if player_dict.has("integrity") else "[color=#e5b931]0[/color]"
	bandwidth_label.bbcode_text = "[color=#e5b931]%d[/color]" % player_dict.bandwidth if player_dict.has("bandwidth") else "[color=#e5b931]0[/color]"
	packetloss_label.bbcode_text = "[color=#e5b931]%d%%[/color]" % player_dict.packetloss if player_dict.has("packetloss") else "[color=#e5b931]0%[/color]"
