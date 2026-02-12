extends Node

signal coins_changed(new_count: int)

var coins: int = 0

func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)
