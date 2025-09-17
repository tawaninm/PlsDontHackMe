# res://Scripts/CardData.gd
extends Node

func apply_effect(game_manager, player, card_data: Dictionary) -> void:
	var name = card_data.get("name", "")

	match name:
		"Cat":
			player.skip_turns += 2
			print("Cat → Player skips 2 turns")

		"CorruptedScript":
			if not card_data.has("status_applied"):
				card_data["status_applied"] = true
				if not player.has("effects"):
					player.effects = []
				player.effects.append({"type": "corrupted", "value": 2})
				print("CorruptedScript applied")

		"VirusAttack":
			var target_index = (game_manager.current_player_index + 1) % game_manager.players.size()
			var target = game_manager.players[target_index]
			target.integrity -= 5
			print("VirusAttack → Player", target_index+1, "-5 integrity")

		"Overclock":
			player.bandwidth = min(player.bandwidth + 8, game_manager.MAX_BANDWIDTH)
			player.packetloss += 30
			print("Overclock → Player gains +8 bandwidth, +30 packetloss")

		_:
			print("Unknown card effect:", name)

	# Clamp values to keep stats safe
	player.integrity = clamp(player.integrity, 0, game_manager.MAX_INTEGRITY)
	player.bandwidth = clamp(player.bandwidth, 0, game_manager.MAX_BANDWIDTH)
	player.packetloss = clamp(player.packetloss, game_manager.MIN_PACKETLOSS, 100)

	game_manager.update_ui()
