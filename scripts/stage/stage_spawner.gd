extends Node
class_name StageSpawner
## 区域生成管理器
## 负责动态生成、拼接和销毁游戏区域，实现无限循环跑酷
## 同时管理 Ghost 的录制与回放生命周期
##
## Ghost 生命周期：
##   checkpoint_start → 开始录制当前区域 + 创建 Ghost 回放上一区域录制
##   checkpoint_end   → 结束录制当前区域 + 销毁 Ghost

#INFO: Stage Spawner 配置
## 游戏启动时的初始区域场景（必须设置，否则玩家会掉落）
@export var initial_stage: PackedScene
## 可用的区域场景列表，玩家通过初始区域后从中随机选择生成后续区域
@export var stage_scenes: Array[PackedScene] = []
## 区域放置的 Y 坐标（所有区域共享同一高度基准线）
@export var stage_y_position: float = 133.0

#INFO: Ghost 配置
## Ghost 场景（继承 player.tscn，使用 ghost_controller.gd）
var _ghost_scene: PackedScene = preload("res://scenes/ghost.tscn")
## PlayerRecorder 脚本引用
var _recorder_script: GDScript = preload("res://scripts/ghost/player_recorder.gd")

## 当前活跃的区域实例
var _current_stage: Node2D = null
## 上一个区域实例（等待销毁）
var _previous_stage: Node2D = null
## 下一个区域的瓦片左边缘对齐位置（全局 X 坐标）
var _next_spawn_x: float = 0.0

## 玩家行为录制器引用
var _recorder: Node = null
## 当前 Ghost 实例引用
var _current_ghost: Node2D = null


func _ready() -> void:
	print("[StageSpawner] _ready called, initial_stage = ", initial_stage)
	print("[StageSpawner] stage_scenes count = ", stage_scenes.size())
	if initial_stage == null:
		push_error("StageSpawner: 未设置初始区域场景 (initial_stage)，请在 Inspector 中配置")
		return
	if stage_scenes.is_empty():
		push_warning("StageSpawner: 后续区域列表为空，将重复使用初始场景")

	## 初始化玩家录制器
	call_deferred("_setup_recorder")
	## 延迟到场景树完全就绪后再生成初始区域，确保所有兄弟节点都已初始化
	call_deferred("_spawn_next_stage")


## 查找玩家节点并为其添加 PlayerRecorder 子节点
func _setup_recorder() -> void:
	var player: Node = _find_player()
	if player == null:
		push_error("StageSpawner: 未找到玩家节点，无法初始化录制器")
		return
	_recorder = _recorder_script.new()
	_recorder.name = "PlayerRecorder"
	player.add_child(_recorder)
	print("[StageSpawner] PlayerRecorder 已添加到玩家节点")


## 在兄弟节点中查找玩家（CharacterBody2D 类型且不在 ghost 组中）
func _find_player() -> Node:
	for child: Node in get_parent().get_children():
		if child is CharacterBody2D and not child.is_in_group("ghost"):
			return child
	return null


## 生成下一个区域并拼接到当前区域右侧
func _spawn_next_stage() -> void:
	var scene: PackedScene = _pick_next_stage()
	if scene == null:
		push_error("StageSpawner: 选择区域场景失败")
		return

	print("[StageSpawner] 正在实例化场景: ", scene.resource_path)
	var stage: Node2D = scene.instantiate()

	## 添加到场景树（触发 StageBase._ready() 自动计算尺寸）
	get_parent().add_child(stage)

	## 计算放置位置：瓦片左边缘对齐 _next_spawn_x
	var left_offset: float = 0.0
	if stage.has_method("get_left_offset"):
		left_offset = stage.get_left_offset()

	var stage_w: float = 0.0
	if "stage_width" in stage:
		stage_w = stage.stage_width

	print("[StageSpawner] stage_width=", stage_w, " left_offset=", left_offset, " next_spawn_x=", _next_spawn_x)

	stage.position = Vector2(_next_spawn_x - left_offset, stage_y_position)
	print("[StageSpawner] 区域放置位置: ", stage.position)

	## 更新下一次生成位置（当前区域瓦片右边缘）
	_next_spawn_x += stage_w

	## 连接起始检查点信号
	if stage.has_signal("checkpoint_reached"):
		stage.checkpoint_reached.connect(_on_checkpoint_start_reached)
		print("[StageSpawner] 已连接 checkpoint_reached 信号")
	else:
		push_warning("StageSpawner: 区域没有 checkpoint_reached 信号")

	## 连接结束检查点信号
	if stage.has_signal("checkpoint_end_reached"):
		stage.checkpoint_end_reached.connect(_on_checkpoint_end_reached)
		print("[StageSpawner] 已连接 checkpoint_end_reached 信号")

	## 更新区域引用
	_previous_stage = _current_stage
	_current_stage = stage

	## 推进 GameInitializer 中的区域计数
	var idx: int = GameInitializer.advance_stage()
	print("[StageSpawner] 区域生成完成, current_stage_index=", idx)


## ========== 起始检查点处理 ==========
## 玩家到达区域起始检查点时触发
func _on_checkpoint_start_reached(stage: Node2D) -> void:
	## 只响应当前活跃区域的检查点
	if stage != _current_stage:
		return
	## 延迟处理，避免在物理回调（body_entered）期间修改场景树
	call_deferred("_handle_checkpoint_start")


## 处理起始检查点：生成下一个区域、开始录制、创建 Ghost
func _handle_checkpoint_start() -> void:
	## 记录玩家已完全离开的旧区域（当前区域的前一个）
	var stage_to_cleanup: Node2D = _previous_stage

	## --- Ghost：开始录制 + 创建 Ghost ---
	if _recorder != null:
		## 开始录制当前区域的玩家行为
		_recorder.start_recording()
		print("[StageSpawner] checkpoint_start: 开始录制")

		## 如果有上一个区域的录制数据，创建 Ghost 回放
		var previous_recording: Array[Dictionary] = _recorder.get_previous_recording()
		if not previous_recording.is_empty():
			_destroy_current_ghost()
			_spawn_ghost(previous_recording)

	## 生成下一个区域（此时 _previous_stage 会被更新为当前玩家所在区域）
	_spawn_next_stage()
	## 清理玩家已完全离开的旧区域
	if stage_to_cleanup != null:
		print("[StageSpawner] 清理旧区域: ", stage_to_cleanup.name)
		stage_to_cleanup.queue_free()


## ========== 结束检查点处理 ==========
## 玩家到达区域结束检查点时触发
func _on_checkpoint_end_reached(_stage: Node2D) -> void:
	## 响应当前区域或上一个区域的结束检查点
	## （玩家可能已经触发了下一个区域的 start，但 end 属于上一个区域）
	call_deferred("_handle_checkpoint_end")


## 处理结束检查点：结束录制、销毁 Ghost
func _handle_checkpoint_end() -> void:
	## --- Ghost：结束录制 + 销毁 Ghost ---
	if _recorder != null:
		_recorder.stop_recording()
		print("[StageSpawner] checkpoint_end: 结束录制")

	_destroy_current_ghost()
	print("[StageSpawner] checkpoint_end: Ghost 已销毁")


## ========== Ghost 管理 ==========

## 生成 Ghost 并传入录制数据
func _spawn_ghost(recording: Array[Dictionary]) -> void:
	if recording.is_empty():
		push_warning("[StageSpawner] 录制数据为空，跳过 Ghost 生成")
		return

	var ghost: Node2D = _ghost_scene.instantiate()
	## 渲染在 player（z_index=10）之下
	ghost.z_index = 9
	## 与玩家相同的缩放（main.tscn 中 player scale = 1.5）
	var player: Node = _find_player()
	if player and player is Node2D:
		ghost.scale = (player as Node2D).scale

	get_parent().add_child(ghost)
	## 调用 setup 开始回放（_ready 已执行完毕）
	if ghost.has_method("setup"):
		ghost.setup(recording)
	_current_ghost = ghost
	print("[StageSpawner] Ghost 已生成并开始回放")


## 销毁当前 Ghost
func _destroy_current_ghost() -> void:
	if _current_ghost != null and is_instance_valid(_current_ghost):
		print("[StageSpawner] 销毁旧 Ghost")
		_current_ghost.queue_free()
		_current_ghost = null


## ========== 区域选择 ==========

## 选择下一个要生成的区域场景
## 初始区域使用 initial_stage，后续从 stage_scenes 中随机选择
## 未来可扩展为加权、难度递增等策略
func _pick_next_stage() -> PackedScene:
	## 初始区域（current_stage_index 为 -1 时）使用专门的初始场景
	if GameInitializer.current_stage_index < 0:
		return initial_stage
	## 后续区域：如果列表不为空则随机选择，否则回退到初始场景
	if not stage_scenes.is_empty():
		return stage_scenes.pick_random()
	return initial_stage
