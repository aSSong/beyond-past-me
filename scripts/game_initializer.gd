extends Node

signal coins_changed(new_count: int)
signal coin_fly_requested(from_screen_pos: Vector2)

var coins: int = 0

func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)

func request_coin_fly(from_screen_pos: Vector2) -> void:
	coin_fly_requested.emit(from_screen_pos)
