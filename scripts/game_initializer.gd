extends Node
## 游戏全局生命周期管理器（Autoload 单例）
## 管理金币计数、区域进度等全局游戏状态

signal coins_changed(new_count: int)
## 当玩家进入新区域时发出，参数为新的区域索引
signal stage_advanced(new_stage_index: int)

var coins: int = 0
## 玩家当前所处的区域索引（从 0 开始，-1 表示尚未进入任何区域）
var current_stage_index: int = -1

func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)

## 推进到下一个区域，更新索引并发出信号，返回新的区域索引
func advance_stage() -> int:
	current_stage_index += 1
	stage_advanced.emit(current_stage_index)
	return current_stage_index
