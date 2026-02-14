extends CharacterBody2D
class_name GhostController
## Ghost 回放控制器
## 替代 PlatformerController2D，逐帧回放录制的玩家行为数据
## 半透明淡蓝色视觉，回放完毕后淡出消失

## Ghost 视觉颜色（半透明淡蓝）
const GHOST_COLOR: Color = Color(0.5, 0.7, 1.0, 0.6)
## 淡出持续时间（秒）
const FADE_OUT_DURATION: float = 0.5

## 录制帧数据
var _recording: Array[Dictionary] = []
## 当前回放帧索引
var _frame_index: int = 0
## 是否已开始淡出
var _fading_out: bool = false

## 子节点引用
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision_full: CollisionShape2D = $Collisionfull
@onready var _collision_half: CollisionShape2D = $Collisionhalf
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	## 加入 ghost 组，用于金币检测区分
	add_to_group("ghost")

	## 半透明淡蓝色调
	modulate = GHOST_COLOR

	## 保持在 player 层让金币 Area2D 能检测到，但不与任何物体产生物理碰撞
	collision_layer = 1
	collision_mask = 0

	## 禁用摄像机
	if _camera:
		_camera.enabled = false

	## 初始化碰撞体状态
	if _collision_full:
		_collision_full.disabled = false
	if _collision_half:
		_collision_half.disabled = true

	## 暂停回放直到 setup() 被调用
	set_physics_process(false)


## 接收录制数据并开始回放
func setup(recording: Array[Dictionary]) -> void:
	_recording = recording
	_frame_index = 0
	if _recording.is_empty():
		push_warning("[GhostController] 录制数据为空，无法回放")
		queue_free()
		return
	## 将 ghost 移动到录制的起始位置
	global_position = _recording[0]["position"]
	set_physics_process(true)
	print("[GhostController] 开始回放，共 %d 帧" % _recording.size())


func _physics_process(_delta: float) -> void:
	if _fading_out:
		return

	if _frame_index >= _recording.size():
		_fade_out()
		return

	var frame: Dictionary = _recording[_frame_index]

	## 设置全局位置
	global_position = frame["position"]

	## 播放对应动画和帧
	var anim_name: StringName = frame["animation"]
	var anim_frame: int = frame["frame"]
	if _sprite:
		if _sprite.animation != anim_name:
			_sprite.play(anim_name)
		_sprite.frame = anim_frame

	## 切换碰撞体
	var is_half: bool = frame["is_collision_half"]
	if _collision_full:
		_collision_full.disabled = is_half
	if _collision_half:
		_collision_half.disabled = not is_half

	_frame_index += 1


## 回放完毕后淡出消失
func _fade_out() -> void:
	if _fading_out:
		return
	_fading_out = true
	set_physics_process(false)
	print("[GhostController] 回放完毕，开始淡出")
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	tween.tween_callback(queue_free)
