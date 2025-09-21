extends Node

func apply_effect(game_manager, player, card_data: Dictionary) -> void:
	var name = card_data.get("name", "")

	match name:
		"Cat":
			player.skip_turns += 2
			print("Cat → Player skips 2 turns")
		"CorruptedScript":
			print("CorruptedScript added to hand (passive curse)")
		"VirusAttack":
			var target_index = (game_manager.current_player_index + 1) % game_manager.players.size()
			var target = game_manager.players[target_index]
			target.integrity = max(0, target.integrity - 5)
			print("VirusAttack → Player", target_index+1, "-5 integrity")
		"Overclock":
			player.bandwidth = min(player.bandwidth + 8, game_manager.MAX_BANDWIDTH)
			player.packetloss = min(100, player.packetloss + 40)
			print("Overclock → Player gains +8 bandwidth, +40 packetloss")
		_:
			print("Unknown card effect:", name)

	player.integrity = clamp(player.integrity, 0, game_manager.MAX_INTEGRITY)
	player.bandwidth = clamp(player.bandwidth, 0, game_manager.MAX_BANDWIDTH)
	player.packetloss = clamp(player.packetloss, game_manager.MIN_PACKETLOSS, 100)

	game_manager.update_ui()
