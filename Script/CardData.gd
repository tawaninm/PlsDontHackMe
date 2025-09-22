extends Node

func apply_effect(game_manager, player, card_data: Dictionary, player_index: int) -> void:
	var name = card_data.get("name", "")

	match name:
		"Cat":
			player.skip_turns += 2
			print("Cat → Player skips 2 turns")

		"CorruptedScript":
			print("CorruptedScript added to hand (passive curse)")

		"VirusAttack":
			var target_index = (player_index + 1) % game_manager.players.size()
			var target = game_manager.players[target_index]
			target.integrity = max(0, target.integrity - 5)
			print("VirusAttack → Player %d -5 integrity" % (target_index + 1))
			game_manager._sync_player_to_vars(target_index)

		"Overclock":
			player.bandwidth = min(player.bandwidth + 8, game_manager.MAX_BANDWIDTH)
			player.packetloss = min(player.packetloss + 40, 100)
			print("Overclock → Player gains +8 BW, +40 PL")

	# Clamp + sync
	player.integrity = clamp(player.integrity, 0, game_manager.MAX_INTEGRITY)
	player.bandwidth = clamp(player.bandwidth, 0, game_manager.MAX_BANDWIDTH)
	player.packetloss = clamp(player.packetloss, game_manager.MIN_PACKETLOSS, 100)
	game_manager._sync_player_to_vars(player_index)
