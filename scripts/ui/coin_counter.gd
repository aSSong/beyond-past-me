extends HBoxContainer

@onready var label: Label = $CoinLabel
@onready var coin_icon: TextureRect = $CoinIcon

# 从金币图集截取的第一帧贴图，用于飞行动画
var coin_texture: Texture2D

func _ready():
	# 加载金币图集并截取第一帧作为飞行动画贴图
	var atlas = load("res://assets/coins/JumpingShiningCoin.png")
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = atlas
	atlas_tex.region = Rect2(0, 0, 8, 16)
	coin_texture = atlas_tex

	GameInitializer.coins_changed.connect(_on_coins_changed)
	GameInitializer.coin_fly_requested.connect(_on_coin_fly_requested)

func _on_coins_changed(new_count: int) -> void:
	label.text = "x " + str(new_count)

func _on_coin_fly_requested(from_screen_pos: Vector2) -> void:
	# 创建飞行金币精灵
	var flying = Sprite2D.new()
	flying.texture = coin_texture
	flying.scale = Vector2(4, 4)
	flying.z_index = 100
	flying.global_position = from_screen_pos
	get_tree().root.add_child(flying)

	# 获取计数器图标的屏幕位置作为目标
	var target_pos = coin_icon.global_position + coin_icon.size / 2

	# Tween 飞行动画（位移和缩小并行执行）
	var tween = flying.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flying, "global_position", target_pos, 0.5) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(flying, "scale", Vector2(1, 1), 0.5) \
		.set_ease(Tween.EASE_IN)
	tween.set_parallel(false)
	tween.tween_callback(func():
		flying.queue_free()
		GameInitializer.add_coin()
	)
