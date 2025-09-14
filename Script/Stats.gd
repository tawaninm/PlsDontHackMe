extends Node

# --- Player 1 stats (start values) ---
var player1_points: int = 100
var player1_integrity: int = 0
var player1_bandwidth: int = 0
var player1_packetloss: int = 100

# --- Limits ---
const MAX_INTEGRITY := 100
const MAX_BANDWIDTH := 20
const MIN_PACKETLOSS := 0

# --- Cooldown flags ---
var can_click_integrity := true
var can_click_bandwidth := true
var can_click_packetloss := true

# --- Timer (Prep Time) ---
@onready var prep_timer: Timer = $"../TimerControl/Prep Time"    # adjust path if yours differs
var remaining_seconds: int = 90   # 1:30

# --- Labels (RichTextLabel) ---
@onready var health_label: RichTextLabel = $"../Player1Health"
@onready var mana_label: RichTextLabel = $"../Player1Mana"
@onready var error_label: RichTextLabel = $"../Player1Error"
@onready var points_label: RichTextLabel = $"../Player1points"

# --- Area2D Hitboxes ---
@onready var hitbox_integrity: Area2D = $"../HitboxIntegrity"
@onready var hitbox_bandwidth: Area2D = $"../HitboxBandwidth"
@onready var hitbox_packetloss: Area2D = $"../HitboxPacketloss"

func _ready() -> void:
	# Connect Area2D signals
	hitbox_integrity.input_event.connect(_on_HitboxIntegrity_input_event)
	hitbox_bandwidth.input_event.connect(_on_HitboxBandwidth_input_event)
	hitbox_packetloss.input_event.connect(_on_HitboxPacketloss_input_event)

	# Setup & start timer
	if prep_timer:
		prep_timer.wait_time = 1.0
		prep_timer.one_shot = false
		prep_timer.autostart = true
		prep_timer.timeout.connect(_on_Prep_Time_timeout)
		prep_timer.start()

	update_ui()

# --- UI updater (shows points now) ---
func update_ui() -> void:
	# ensure bbcode enabled
	health_label.bbcode_enabled = true
	mana_label.bbcode_enabled = true
	error_label.bbcode_enabled = true
	points_label.bbcode_enabled = true

	# show values (gold color)
	health_label.bbcode_text = "[color=#e5b931]%d[/color]" % player1_integrity
	mana_label.bbcode_text   = "[color=#e5b931]%d[/color]" % player1_bandwidth
	error_label.bbcode_text  = "[color=#e5b931]%d[/color]" % player1_packetloss
	# <-- This line displays the player's points
	points_label.bbcode_text = "[color=#e5b931]%d[/color]" % player1_points

# --- Hitbox callbacks (with cooldown and prints) ---
func _on_HitboxIntegrity_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not can_click_integrity:
			return
		can_click_integrity = false

		# cost: 1 point -> +2 integrity
		if player1_points >= 1 and player1_integrity < MAX_INTEGRITY:
			player1_points -= 1
			player1_integrity = min(player1_integrity + 2, MAX_INTEGRITY)
			print("Clicked Integrity → +2 integrity, Points left:", player1_points, "Integrity:", player1_integrity)
			update_ui()
		else:
			if player1_points < 1:
				print("Cannot increase Integrity: not enough points.")
			else:
				print("Integrity already at max.")
		await get_tree().create_timer(0.1).timeout
		can_click_integrity = true

func _on_HitboxBandwidth_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not can_click_bandwidth:
			return
		can_click_bandwidth = false

		# cost: 4 points -> +1 bandwidth
		if player1_points >= 4 and player1_bandwidth < MAX_BANDWIDTH:
			player1_points -= 4
			player1_bandwidth = min(player1_bandwidth + 1, MAX_BANDWIDTH)
			print("Clicked Bandwidth → +1 bandwidth, -4 points. Bandwidth:", player1_bandwidth, "Points left:", player1_points)
			update_ui()
		else:
			if player1_points < 4:
				print("Cannot increase Bandwidth: need 4 points.")
			else:
				print("Bandwidth already at max.")
		await get_tree().create_timer(0.1).timeout
		can_click_bandwidth = true

func _on_HitboxPacketloss_input_event(viewport, event, shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not can_click_packetloss:
			return
		can_click_packetloss = false

		# cost: 1 point -> -4 packetloss (clamped to 0)
		if player1_points >= 1 and player1_packetloss > MIN_PACKETLOSS:
			player1_points -= 1
			player1_packetloss = max(player1_packetloss - 4, MIN_PACKETLOSS)
			print("Clicked Packetloss → -4 packetloss, -1 point. Packetloss:", player1_packetloss, "Points left:", player1_points)
			update_ui()
		else:
			if player1_points < 1:
				print("Cannot reduce Packetloss: not enough points.")
			else:
				print("Packetloss already at minimum.")
		await get_tree().create_timer(0.1).timeout
		can_click_packetloss = true

# --- Timer tick (countdown + auto-spend on timeout) ---
func _on_Prep_Time_timeout() -> void:
	remaining_seconds -= 1

	# if time's up, auto-spend remaining points to integrity (respect caps)
	if remaining_seconds <= 0:
		if prep_timer:
			prep_timer.stop()

		while player1_points > 0 and player1_integrity < MAX_INTEGRITY:
			player1_points -= 1
			player1_integrity = min(player1_integrity + 2, MAX_INTEGRITY)

		if player1_integrity < 2:
			player1_integrity = 2

		print("Time ran out! Auto-spent points. Final: Integrity:", player1_integrity, "Bandwidth:", player1_bandwidth, "Packetloss:", player1_packetloss, "Points left:", player1_points)
		update_ui()

		# change scene (adjust path)
		get_tree().change_scene_to_file("res://scenes/NextScene.tscn")
		return

	update_ui()
