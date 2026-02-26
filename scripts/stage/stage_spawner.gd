extends Node
class_name StageSpawner
## 区域生成管理器
## 负责按固定顺序生成、拼接和销毁游戏区域
## 同时管理 Ghost 的录制与回放生命周期
##
## Ghost 生命周期：
##   checkpoint_start → 开始录制当前区域 + 创建 Ghost 回放上一区域录制
##   checkpoint_end   → 结束录制当前区域（Ghost 自行淡出销毁）

#INFO: 顺序关卡配置
## main 场景中内置标题区域节点路径
@export var maintitle_stage_node_path: NodePath = NodePath("../Stage_maintitle")
## 正式流程场景列表（按 1~6 顺序配置）
@export var gameplay_stage_scenes: Array[PackedScene] = []
## 结束阶段场景（流程最后一段）
@export var ending_stage_scene: PackedScene
## 正式流程总关卡数（默认 6）
@export var gameplay_stage_count: int = 6
## 区域放置的 Y 坐标（所有区域共享同一高度基准线）
@export var stage_y_position: float = 133.0

#INFO: Ghost 配置
## Ghost 场景（继承 player.tscn，使用 ghost_controller.gd）
var _ghost_scene: PackedScene = preload("res://scenes/ghost.tscn")
## PlayerRecorder 脚本引用
var _recorder_script: GDScript = preload("res://scripts/ghost/player_recorder.gd")

## 当前活跃的区域实例
var _current_stage: Node2D = null
## 下一个区域的瓦片左边缘对齐位置（全局 X 坐标）
var _next_spawn_x: float = 0.0

## 玩家行为录制器引用
var _recorder: Node = null
## 当前 Ghost 实例引用
var _current_ghost: Node2D = null
## 已生成且仍在场景树中的区域（按生成顺序）
var _spawned_stages: Array[Node2D] = []
## 区域实例 ID -> 序列索引
var _stage_order_by_instance_id: Dictionary = {}
## 固定关卡序列
var _stage_sequence: Array[PackedScene] = []
## 下一个待生成的序列索引
var _next_sequence_index: int = 0
## 是否已经进入正式流程（按 D 后）
var _gameplay_sequence_started: bool = false
## main 场景中已内置的标题区域实例
var _maintitle_stage: Node2D = null
## 第一个正式关卡实例（用于在其 checkpoint_end 后清理标题区域）
var _first_gameplay_stage: Node2D = null


func _ready() -> void:
	print("[StageSpawner] _ready called")
	if ending_stage_scene == null:
		push_error("StageSpawner: 未设置结束场景 ending_stage_scene")
		return

	_build_stage_sequence()
	_setup_maintitle_anchor()
	## 初始化玩家录制器
	call_deferred("_setup_recorder")


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
	var scene: PackedScene = _pick_next_stage_from_sequence()
	if scene == null:
		push_warning("StageSpawner: 序列中无可生成区域，跳过")
		return

	var stage_order: int = _next_sequence_index - 1
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

	## 记录区域顺序信息
	_spawned_stages.append(stage)
	_stage_order_by_instance_id[stage.get_instance_id()] = stage_order
	if stage_order == 0 and _first_gameplay_stage == null:
		_first_gameplay_stage = stage
	_current_stage = stage

	## 推进 GameInitializer 中的区域计数
	var idx: int = GameInitializer.advance_stage()
	print("[StageSpawner] 区域生成完成, current_stage_index=", idx, " sequence_order=", stage_order)


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

	## start 仅负责生成下一个区域
	_spawn_next_stage()


## ========== 结束检查点处理 ==========
## 玩家到达区域结束检查点时触发
func _on_checkpoint_end_reached(stage: Node2D) -> void:
	## 响应当前区域或上一区域的结束检查点（防止时序穿插漏事件）
	call_deferred("_handle_checkpoint_end", stage)


## 处理结束检查点：结束录制 + 清除上一个区域
func _handle_checkpoint_end(stage: Node2D) -> void:
	if stage == null or not is_instance_valid(stage):
		return

	## --- Ghost：结束录制（Ghost 销毁由回放完毕自行处理） ---
	if _recorder != null:
		_recorder.stop_recording()
		print("[StageSpawner] checkpoint_end: 结束录制")
	print("[StageSpawner] checkpoint_end: Ghost 保持回放，结束后自动淡出销毁")

	## end 仅负责清理“当前区域”的上一个区域
	_cleanup_previous_stage_of(stage)
	if stage == _first_gameplay_stage:
		_cleanup_maintitle_stage()

	## 第6关结束时进入流程完成与结束阶段
	if _is_sixth_gameplay_stage(stage):
		GameInitializer.mark_gameplay_finished()
		GameInitializer.enter_end_screen()


## ========== Ghost 管理 ==========

## 生成 Ghost 并传入录制数据
## Ghost 使用当前区域锚点回放上一次录制的相对轨迹
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
		var replay_origin: Vector2 = recording[0]["position"] as Vector2
		if player and player is Node2D:
			## 仅使用当前玩家 X 作为锚点，Y 保持录制起点高度
			## 避免玩家空中触发 checkpoint_start 时 Ghost 悬空
			replay_origin.x = (player as Node2D).global_position.x
		ghost.setup(recording, replay_origin)
	_current_ghost = ghost
	print("[StageSpawner] Ghost 已生成并开始回放")


## 销毁当前 Ghost
func _destroy_current_ghost() -> void:
	if _current_ghost != null and is_instance_valid(_current_ghost):
		print("[StageSpawner] 销毁旧 Ghost")
		_current_ghost.queue_free()
		_current_ghost = null


## ========== 区域选择 ==========

## 外部触发：按 D 开始正式流程时调用
func start_gameplay_sequence() -> void:
	if _gameplay_sequence_started:
		return
	_gameplay_sequence_started = true
	## 按需求：开始时立即在标题场景右侧创建第1关
	_spawn_next_stage()


## 构建固定序列：[maintitle, gameplay(1~6), ending]
func _build_stage_sequence() -> void:
	_stage_sequence.clear()
	_next_sequence_index = 0

	var safe_gameplay_count: int = max(gameplay_stage_count, 1)
	if gameplay_stage_scenes.is_empty():
		push_warning("StageSpawner: gameplay_stage_scenes 为空，将使用 ending_stage_scene 作为占位")
	for i in range(safe_gameplay_count):
		var scene: PackedScene = _get_gameplay_scene_by_index(i)
		_stage_sequence.append(scene)

	if ending_stage_scene != null:
		_stage_sequence.append(ending_stage_scene)

	print("[StageSpawner] 固定序列已构建, size=", _stage_sequence.size())


func _get_gameplay_scene_by_index(index: int) -> PackedScene:
	if gameplay_stage_scenes.is_empty():
		return ending_stage_scene
	if index < gameplay_stage_scenes.size() and gameplay_stage_scenes[index] != null:
		return gameplay_stage_scenes[index]
	## 若配置数量不足，则使用列表最后一个做占位，避免流程中断
	var fallback_scene: PackedScene = gameplay_stage_scenes[gameplay_stage_scenes.size() - 1]
	push_warning("StageSpawner: gameplay_stage_scenes 数量不足，索引 %s 使用末尾场景占位" % str(index))
	return fallback_scene


func _pick_next_stage_from_sequence() -> PackedScene:
	if _next_sequence_index >= _stage_sequence.size():
		return null
	var next_scene: PackedScene = _stage_sequence[_next_sequence_index]
	_next_sequence_index += 1
	return next_scene


func _setup_maintitle_anchor() -> void:
	_maintitle_stage = get_node_or_null(maintitle_stage_node_path) as Node2D
	if _maintitle_stage == null:
		push_error("StageSpawner: 未找到内置标题区域节点: %s" % String(maintitle_stage_node_path))
		return

	var metrics: Dictionary = _calculate_stage_metrics(_maintitle_stage)
	var stage_width: float = float(metrics.get("stage_width", 0.0))
	_next_spawn_x = _maintitle_stage.position.x + stage_width
	print("[StageSpawner] 标题区域锚点已初始化, width=", stage_width, " next_spawn_x=", _next_spawn_x)


func _calculate_stage_metrics(stage: Node2D) -> Dictionary:
	var stage_width: float = 0.0
	var left_offset: float = 0.0

	if stage.has_method("get_left_offset"):
		left_offset = stage.get_left_offset()
	if "stage_width" in stage:
		stage_width = stage.stage_width

	if stage_width <= 0.0:
		var tile_layer: TileMapLayer = stage.find_child("TileMapLayer", true, false) as TileMapLayer
		if tile_layer != null and tile_layer.tile_set != null:
			var used_rect: Rect2i = tile_layer.get_used_rect()
			var tile_size: Vector2i = tile_layer.tile_set.tile_size
			stage_width = used_rect.size.x * tile_size.x * stage.scale.x
			left_offset = used_rect.position.x * tile_size.x * stage.scale.x

	return {
		"stage_width": stage_width,
		"left_offset": left_offset,
	}


func _cleanup_previous_stage_of(stage: Node2D) -> void:
	var current_index: int = _spawned_stages.find(stage)
	if current_index <= 0:
		return

	var previous_stage: Node2D = _spawned_stages[current_index - 1]
	if previous_stage == null or not is_instance_valid(previous_stage):
		return

	_stage_order_by_instance_id.erase(previous_stage.get_instance_id())
	_spawned_stages.remove_at(current_index - 1)
	print("[StageSpawner] 清理旧区域: ", previous_stage.name)
	previous_stage.queue_free()


func _is_sixth_gameplay_stage(stage: Node2D) -> bool:
	var stage_order: int = int(_stage_order_by_instance_id.get(stage.get_instance_id(), -1))
	## 仅统计正式关卡序列：0=第1关, 5=第6关
	return stage_order == gameplay_stage_count - 1


func _cleanup_maintitle_stage() -> void:
	if _maintitle_stage == null or not is_instance_valid(_maintitle_stage):
		return
	print("[StageSpawner] 清理标题区域: ", _maintitle_stage.name)
	_maintitle_stage.queue_free()
	_maintitle_stage = null
