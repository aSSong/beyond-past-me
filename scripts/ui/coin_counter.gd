extends HBoxContainer

@onready var label: Label = $CoinLabel
@onready var coin_icon: TextureRect = $CoinIcon

func _ready():
	GameInitializer.coins_changed.connect(_on_coins_changed)

func _on_coins_changed(new_count: int) -> void:
	label.text = "x " + str(new_count)
	# 计数更新时图标弹跳反馈
	_bounce_icon()

func _bounce_icon() -> void:
	var tween = coin_icon.create_tween()
	tween.tween_property(coin_icon, "scale", Vector2(1.3, 1.3), 0.1) \
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(coin_icon, "scale", Vector2(1.0, 1.0), 0.1) \
		.set_ease(Tween.EASE_IN)
