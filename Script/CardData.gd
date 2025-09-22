extends Node

func apply_effect(game_manager, player, card_data: Dictionary, player_index: int) -> void:
	var name: String = str(card_data.get("name", ""))

	match name:
		# === Old cards ===
		"CorruptedScript":
			print("CorruptedScript added to hand (passive curse)")

		"VirusAttack":
			var target_index = (player_index + 1) % game_manager.players.size()
			var target = game_manager.players[target_index]
			if target:
				target.integrity = max(0, target.integrity - 5)
				print("VirusAttack → Player", target_index + 1, "-5 integrity")
				if game_manager.has_method("_sync_player_to_vars"):
					game_manager.call("_sync_player_to_vars", target_index)

		"Overclock":
			player.bandwidth = min(player.bandwidth + 8, game_manager.MAX_BANDWIDTH)
			player.packetloss = min(100, player.packetloss + 40)
			print("Overclock → Player gains +8 bandwidth, +40 packetloss")

		# === New cards ===
		"WormVirus":
			var base_damage: int = 5
			for i in range(game_manager.players.size()):
				var target = game_manager.players[i]
				if not target:
					continue
				var damage: int = base_damage
				if _player_has_firewall(target):
					var reduction: int = int(floor(base_damage * 0.25))
					damage = max(0, base_damage - reduction)
				if game_manager.has_method("_add_integrity"):
					game_manager.call("_add_integrity", i, -damage)
				else:
					target.integrity = max(0, target.integrity - damage)
					if game_manager.has_method("_sync_player_to_vars"):
						game_manager.call("_sync_player_to_vars", i)
			print("WormVirus → everyone -%d integrity (firewall reduces damage by 25%%)" % base_damage)

		"Firewall":
			print("Firewall acquired — reduces incoming damage by 25%% while held (does not stack).")

		"NetworkUpgrade":
			if game_manager.has_method("_add_bandwidth"):
				game_manager.call("_add_bandwidth", player_index, 2)
			else:
				player.bandwidth = min(player.bandwidth + 2, game_manager.MAX_BANDWIDTH)
				if game_manager.has_method("_sync_player_to_vars"):
					game_manager.call("_sync_player_to_vars", player_index)
			print("NetworkUpgrade → Player %d gains +2 bandwidth (free)." % (player_index + 1))

		"DDosAttack":
			var target_index = (player_index + 1) % game_manager.players.size()
			if not game_manager.has_method("player_draw_card"):
				return

	# Force target to draw 10
			for d in range(10):
				game_manager.call("player_draw_card", target_index)

	# Check overflow
			var hand_size: int = game_manager.players[target_index].hand.size()
			var overflow: int = max(0, hand_size - game_manager.MAX_HAND_SIZE)
			if overflow > 0:
				var base_damage: int = overflow * 3
				var damage: int = base_damage
				if _player_has_firewall(game_manager.players[target_index]):
					var reduction: int = int(floor(base_damage * 0.25))
					damage = max(0, base_damage - reduction)
				if game_manager.has_method("_add_integrity"):
					game_manager.call("_add_integrity", target_index, -damage)
				print("DDosAttack → Player %d overflow %d -> %d damage (after firewall)" % [target_index + 1, overflow, damage])

			# === Final clamp and sync ===
			player.integrity = clamp(player.integrity, 0, game_manager.MAX_INTEGRITY)
			player.bandwidth = clamp(player.bandwidth, 0, game_manager.MAX_BANDWIDTH)
			player.packetloss = clamp(player.packetloss, game_manager.MIN_PACKETLOSS, 100)
			if game_manager.has_method("_sync_player_to_vars"):
				game_manager.call("_sync_player_to_vars", player_index)


func _player_has_firewall(player) -> bool:
	if not player:
		return false
	for c in player.hand:
		if c and c.has_method("get_card_data"):
			var d: Dictionary = c.get_card_data()
			if str(d.get("name", "")) == "Firewall":
				return true
	return false
