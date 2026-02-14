extends Node2D

## 记录拾取此金币的是否为 Ghost
var _collected_by_ghost: bool = false


func _ready():
	# 确保 Area2D 碰撞设置正确：mask 包含 player 所在的 layer 1
	$Area2D.collision_mask = 1
	$Area2D.monitoring = true
	$Area2D.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		# 禁用碰撞防止重复触发
		$Area2D.set_deferred("monitoring", false)
		# 记录拾取者是否为 Ghost
		_collected_by_ghost = body.is_in_group("ghost")
		# 原地播放收集动画（缩放弹跳 + 淡出）然后消失
		_play_collect_animation()


func _play_collect_animation() -> void:
	var sprite = $AnimatedSprite2D
	var tween = create_tween()
	tween.set_parallel(true)
	# 先放大弹跳
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	# 再缩小并淡出
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(0, 0), 0.2) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2) \
		.set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	# 动画结束后：Ghost 拾取不计数，玩家拾取正常计数
	tween.tween_callback(func():
		if not _collected_by_ghost:
			GameInitializer.add_coin()
		queue_free()
	)
