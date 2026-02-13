extends Node
class_name StageSpawner
## 区域生成管理器
## 负责动态生成、拼接和销毁游戏区域，实现无限循环跑酷

#INFO: Stage Spawner 配置
## 游戏启动时的初始区域场景（必须设置，否则玩家会掉落）
@export var initial_stage: PackedScene
## 可用的区域场景列表，玩家通过初始区域后从中随机选择生成后续区域
@export var stage_scenes: Array[PackedScene] = []
## 区域放置的 Y 坐标（所有区域共享同一高度基准线）
@export var stage_y_position: float = 133.0

## 当前活跃的区域实例
var _current_stage: Node2D = null
## 上一个区域实例（等待销毁）
var _previous_stage: Node2D = null
## 下一个区域的瓦片左边缘对齐位置（全局 X 坐标）
var _next_spawn_x: float = 0.0


func _ready() -> void:
	print("[StageSpawner] _ready called, initial_stage = ", initial_stage)
	print("[StageSpawner] stage_scenes count = ", stage_scenes.size())
	if initial_stage == null:
		push_error("StageSpawner: 未设置初始区域场景 (initial_stage)，请在 Inspector 中配置")
		return
	if stage_scenes.is_empty():
		push_warning("StageSpawner: 后续区域列表为空，将重复使用初始场景")
	## 延迟到场景树完全就绪后再生成初始区域，确保所有兄弟节点都已初始化
	call_deferred("_spawn_next_stage")


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

	## 连接检查点信号
	if stage.has_signal("checkpoint_reached"):
		stage.checkpoint_reached.connect(_on_checkpoint_reached)
		print("[StageSpawner] 已连接 checkpoint_reached 信号")
	else:
		push_warning("StageSpawner: 区域没有 checkpoint_reached 信号")

	## 更新区域引用
	_previous_stage = _current_stage
	_current_stage = stage

	## 推进 GameInitializer 中的区域计数
	var idx: int = GameInitializer.advance_stage()
	print("[StageSpawner] 区域生成完成, current_stage_index=", idx)


## 处理检查点触发
func _on_checkpoint_reached(stage: Node2D) -> void:
	## 只响应当前活跃区域的检查点
	if stage != _current_stage:
		return
	## 延迟处理，避免在物理回调（body_entered）期间修改场景树
	call_deferred("_handle_stage_transition")


## 处理区域过渡：生成下一个区域并清理已离开的旧区域
func _handle_stage_transition() -> void:
	## 记录玩家已完全离开的旧区域（当前区域的前一个）
	## 注意：_previous_stage 是玩家正在通过的区域，不能删它
	## 要删的是更早之前的区域（即 _previous_stage 在被更新之前的值）
	var stage_to_cleanup: Node2D = _previous_stage
	## 生成下一个区域（此时 _previous_stage 会被更新为当前玩家所在区域）
	_spawn_next_stage()
	## 清理玩家已完全离开的旧区域
	if stage_to_cleanup != null:
		print("[StageSpawner] 清理旧区域: ", stage_to_cleanup.name)
		stage_to_cleanup.queue_free()


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
