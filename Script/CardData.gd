# CardData.gd
extends Node

# Centralized card effects. Signature:
# apply_effect(game_manager, player, card_data: Dictionary, player_index: int)
func apply_effect(game_manager, player, card_data: Dictionary, player_index: int) -> void:
	var name: String = str(card_data.get("name", ""))

	match name:
		"CorruptedScript":
			# passive, nothing immediate
			print("CorruptedScript added to hand (passive curse)")

		"VirusAttack":
			var target_idx: int = -1
			if game_manager.has_method("_find_next_alive"):
				target_idx = int(game_manager.call("_find_next_alive", player_index))
			else:
				if game_manager.players.size() > 0:
					target_idx = (player_index + 1) % game_manager.players.size()
			if target_idx == -1:
				print("VirusAttack: no valid target found.")
			else:
				if game_manager.has_method("_add_integrity"):
					game_manager.call("_add_integrity", target_idx, -5)
				else:
					game_manager.players[target_idx].integrity = max(0, game_manager.players[target_idx].integrity - 5)
					if game_manager.has_method("_sync_player_to_vars"):
						game_manager.call("_sync_player_to_vars", target_idx)
				print("VirusAttack → Player %d loses 5 integrity" % (target_idx + 1))

		"Overclock":
	# cost already paid in GameManager
			if game_manager.has_method("_add_bandwidth"):
				game_manager.call("_add_bandwidth", player_index, 8)
			else:
				player.bandwidth = min(player.bandwidth + 8, game_manager.MAX_BANDWIDTH)

			if game_manager.has_method("_add_packetloss"):
				game_manager.call("_add_packetloss", player_index, 40)
			else:
				player.packetloss = min(100, player.packetloss + 40)

			print("Overclock → Player %d gains +8 BW, +40 PL" % (player_index + 1))


		"WormVirus":
			const BASE_DAMAGE: int = 5
			var total_players: int = game_manager.players.size()
			for i in range(total_players):
				var damage: int = BASE_DAMAGE
				if _player_has_firewall(game_manager.players[i]):
					# compute 25% reduction (round down)
					var reduction: int = int(floor(float(BASE_DAMAGE) * 0.25))
					damage = max(0, BASE_DAMAGE - reduction)
				if game_manager.has_method("_add_integrity"):
					game_manager.call("_add_integrity", i, -damage)
				else:
					game_manager.players[i].integrity = max(0, game_manager.players[i].integrity - damage)
					if game_manager.has_method("_sync_player_to_vars"):
						game_manager.call("_sync_player_to_vars", i)
			print("WormVirus → everyone -%d integrity (firewall reduces damage by 25%%)" % BASE_DAMAGE)

		"Firewall":
			# passive effect; presence is checked by _player_has_firewall()
			print("Firewall acquired — reduces incoming damage by 25%% while held (does not stack).")

		"NetworkUpgrade":
			if game_manager.has_method("_add_bandwidth"):
				game_manager.call("_add_bandwidth", player_index, 2)
			else:
				player.bandwidth = min(player.bandwidth + 2, game_manager.MAX_BANDWIDTH)
				if game_manager.has_method("_sync_player_to_vars"):
					game_manager.call("_sync_player_to_vars", player_index)
			print("NetworkUpgrade → Player %d gains +2 bandwidth (free)." % (player_index + 1))

		#"DDosAttack":
			#var target_idx: int = -1
			#if game_manager.has_method("_find_next_alive"):
				#target_idx = int(game_manager.call("_find_next_alive", player_index))
			#else:
				#if game_manager.players.size() > 0:
					#target_idx = (player_index + 1) % game_manager.players.size()
#
			#if target_idx == -1:
				#print("DDosAttack: no valid target found.")
			#else:
				## Force target to draw 10 cards (use draw_cards_silent if available)
				#if game_manager.has_method("draw_cards_silent"):
					#game_manager.call("draw_cards_silent", target_idx, 10)
				#else:
					#for _d in range(10):
						#if game_manager.has_method("player_draw_card"):
							#game_manager.call("player_draw_card", target_idx)
#
				## compute overflow and apply damage
				#var hand_size: int = 0
				#if game_manager.has_method("_get_player_hand"):
					#var hand_arr = game_manager.call("_get_player_hand", target_idx)
					#if typeof(hand_arr) == TYPE_ARRAY:
						#hand_size = int(hand_arr.size())
				#else:
					#hand_size = game_manager.players[target_idx].hand.size()
#
				#var overflow: int = max(0, hand_size - int(game_manager.MAX_HAND_SIZE))
				#if overflow > 0:
					#var base_damage: int = overflow * 3
					#var damage: int = base_damage
					#if _player_has_firewall(game_manager.players[target_idx]):
						#var reduction: int = int(floor(float(base_damage) * 0.25))
						#damage = max(0, base_damage - reduction)
					#if game_manager.has_method("_add_integrity"):
						#game_manager.call("_add_integrity", target_idx, -damage)
					#else:
						#game_manager.players[target_idx].integrity = max(0, game_manager.players[target_idx].integrity - damage)
						#if game_manager.has_method("_sync_player_to_vars"):
							#game_manager.call("_sync_player_to_vars", target_idx)
					#print("DDosAttack → Player %d overflow %d -> %d damage (after firewall)" % [target_idx + 1, overflow, damage])
#
		#_:
			#print("CardData: unknown card effect ->", name)

	# Final clamp/sync for the actor
	player.integrity = clamp(player.integrity, 0, game_manager.MAX_INTEGRITY)
	player.bandwidth = clamp(player.bandwidth, 0, game_manager.MAX_BANDWIDTH)
	player.packetloss = clamp(player.packetloss, game_manager.MIN_PACKETLOSS, 100)
	if game_manager.has_method("_sync_player_to_vars"):
		game_manager.call("_sync_player_to_vars", player_index)


# Helper: detect Firewall card presence in a player's hand
func _player_has_firewall(player) -> bool:
	if not player:
		return false
	for c in player.hand:
		if c and c.has_method("get_card_data"):
			var d: Dictionary = c.get_card_data()
			if str(d.get("name", "")) == "Firewall":
				return true
	return false
