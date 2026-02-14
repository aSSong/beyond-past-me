extends Node2D
## CheckPoint 检测脚本
## 当玩家（CharacterBody2D）进入检查点区域时发出 player_entered 信号

## 当玩家进入检查点区域时发出
signal player_entered


func _ready() -> void:
	var area: Area2D = $Area2D
	## 检测玩家所在的 layer 1
	area.collision_mask = 1
	area.monitoring = true
	area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	## 只响应玩家，忽略 Ghost（Ghost 也是 CharacterBody2D 但在 ghost 组中）
	if body is CharacterBody2D and not body.is_in_group("ghost"):
		## 禁用监测防止重复触发
		$Area2D.set_deferred("monitoring", false)
		player_entered.emit()
