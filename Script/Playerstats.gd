extends Control

@export var integrity_path: NodePath
@export var bandwidth_path: NodePath
@export var packetloss_path: NodePath

var gm: Node = null
@onready var integrity_label: RichTextLabel = $"../../../Control/Health1"
@onready var bandwidth_label: RichTextLabel = $"../../../Control/Mana1"
@onready var packetloss_label: RichTextLabel = $"../../../Control/Error1"

func set_gm(game_manager: Node) -> void:
	gm = game_manager

func _ready() -> void:
	for lbl in [integrity_label, bandwidth_label, packetloss_label]:
		if lbl:
			lbl.bbcode_enabled = true

func update_ui_for_player1() -> void:
	if gm == null:
		print("❌ No GameManager set for Player1 UI")
		return

	# Pull directly from GameManager's variables
	var hp: int = gm.player1_integrity
	var bw: int = gm.player1_bandwidth
	var pl: int = gm.player1_packetloss

	integrity_label.bbcode_text  = "[color=#e5b931]%d[/color]" % hp
	bandwidth_label.bbcode_text  = "[color=#e5b931]%d[/color]" % bw
	packetloss_label.bbcode_text = "[color=#e5b931]%d[/color]" % pl

	print("✅ UI Update -> Player1 | HP:%d BW:%d PL:%d" % [hp, bw, pl])
