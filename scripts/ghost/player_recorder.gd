extends Node
class_name PlayerRecorder
## 玩家行为录制器
## 作为 Player 的子节点，每个 _physics_process 帧录制玩家状态
## 由 StageSpawner 管理录制的开始/停止/存储

## 当前正在录制的帧数据缓冲区
var _current_recording: Array[Dictionary] = []
## 上一次完整录制的帧数据（用于传递给 Ghost）
var _previous_recording: Array[Dictionary] = []
## 是否正在录制
var _is_recording: bool = false

## 玩家节点引用（父节点）
var _player: CharacterBody2D
## 动画精灵引用
var _sprite: AnimatedSprite2D
## 全身碰撞体引用
var _collision_full: CollisionShape2D


func _ready() -> void:
	_player = get_parent() as CharacterBody2D
	if _player == null:
		push_warning("PlayerRecorder: 父节点不是 CharacterBody2D")
		return
	_sprite = _player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	_collision_full = _player.get_node("Collisionfull") as CollisionShape2D


func _physics_process(_delta: float) -> void:
	if not _is_recording:
		return
	if _player == null or _sprite == null:
		return
	var frame_data: Dictionary = {
		"position": _player.global_position,
		"animation": _sprite.animation,
		"frame": _sprite.frame,
		"is_collision_half": _collision_full.disabled if _collision_full else false,
	}
	_current_recording.append(frame_data)


## 开始录制，清空当前缓冲区
func start_recording() -> void:
	_current_recording.clear()
	_is_recording = true
	print("[PlayerRecorder] 开始录制")


## 停止录制，将当前录制保存为 _previous_recording 并返回
func stop_recording() -> Array[Dictionary]:
	_is_recording = false
	_previous_recording = _current_recording.duplicate()
	_current_recording.clear()
	print("[PlayerRecorder] 停止录制，共 %d 帧" % _previous_recording.size())
	return _previous_recording


## 获取上次完成的录制数据
func get_previous_recording() -> Array[Dictionary]:
	return _previous_recording
