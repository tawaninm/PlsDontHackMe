extends Node2D

@onready var integrity_point: Label = $"Integrity  P1 point"
@onready var bandwidth_point: Label = $"Bandwidth P1 point"
@onready var packetloss_point: Label = $"Packet Loss P1 point"

# โหลด Stats.gd ที่ attach ไว้ใน Prep_menu
@onready var stats: Node = $Stats

func _process(delta: float) -> void:
	if stats:
		# ดึงค่าจาก Stats.gd
		var integrity_val = stats.health_label.text
		var bandwidth_val = stats.mana_label.text
		var packetloss_val = stats.error_label.text

		# อัปเดต label ของ Main_menu
		integrity_point.text = str(integrity_val)
		bandwidth_point.text = str(bandwidth_val)
		packetloss_point.text = str(packetloss_val)
