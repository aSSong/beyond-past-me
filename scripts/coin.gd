extends Node2D

func _ready():
	# 确保 Area2D 碰撞设置正确：mask 包含 player 所在的 layer 1
	$Area2D.collision_mask = 1
	$Area2D.monitoring = true
	$Area2D.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		# 禁用碰撞防止重复触发
		$Area2D.set_deferred("monitoring", false)
		# 获取金币在屏幕上的位置
		var screen_pos = get_global_transform_with_canvas().origin
		# 通知 GameInitializer 播放飞行动画
		GameInitializer.request_coin_fly(screen_pos)
		# 移除金币
		queue_free()
