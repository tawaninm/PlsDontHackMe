extends Node

@export var start_seconds: int = 5  # 1:30 prep phase
@onready var prep_timer: Timer = $"Prep Time"
@onready var time_label: RichTextLabel = $"Time Left"

var remaining_seconds: int = 0

func _ready() -> void:
	remaining_seconds = start_seconds
	prep_timer.wait_time = 1.0
	prep_timer.one_shot = false
	prep_timer.autostart = false
	prep_timer.timeout.connect(_on_prep_time_timeout)
	update_time_label()
	prep_timer.start()

func _on_prep_time_timeout() -> void:
	remaining_seconds -= 1
	if remaining_seconds <= 0:
		prep_timer.stop()

		# --- Auto-spend points ---
		var stats_node = get_parent().get_node("Stats")  # adjust path to your Stats node
		while stats_node.player1_points > 0 and stats_node.player1_integrity < stats_node.MAX_INTEGRITY:
			stats_node.player1_points -= 1
			stats_node.player1_integrity = min(stats_node.player1_integrity + 2, stats_node.MAX_INTEGRITY)
		if stats_node.player1_integrity < 2:
			stats_node.player1_integrity = 2
		stats_node.update_ui()
		
		# --- Send stats to server ---
		var final_stats = {
			"integrity": stats_node.player1_integrity,
			"bandwidth": stats_node.player1_bandwidth,
			"packetloss": stats_node.player1_packetloss
		}
		
		if multiplayer.get_multiplayer_peer() != null:
			GameManager.rpc_id(1, "receive_player_stats", final_stats)
	else:
		update_time_label()

func update_time_label() -> void:
	var m = remaining_seconds / 60
	var s = remaining_seconds % 60
	time_label.text = "[color=red]%02d:%02d[/color]" % [m, s]
