extends Control
## 跑步进度显示组件
## 显示当前正式流程(1~6)的实时距离进度

#INFO: 进度配置
## StageSpawner 节点路径（用于读取跑步进度边界）
@export var stage_spawner_path: NodePath = NodePath("../../StageSpawner")
## 玩家节点路径（用于读取实时X坐标）
@export var player_path: NodePath = NodePath("../../player")

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var _value_label: Label = $MarginContainer/VBoxContainer/ValueLabel

var _stage_spawner: StageSpawner = null
var _player: Node2D = null
var _progress_start_x: float = 0.0
var _progress_end_x: float = 1.0
var _progress_bounds_ready: bool = false


func _ready() -> void:
	_stage_spawner = get_node_or_null(stage_spawner_path) as StageSpawner
	_player = get_node_or_null(player_path) as Node2D

	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_refresh_progress_ui()

	GameInitializer.flow_state_changed.connect(_on_flow_state_changed)
	GameInitializer.gameplay_finished.connect(_on_gameplay_finished)
	if _stage_spawner != null:
		_stage_spawner.run_progress_bounds_updated.connect(_on_run_progress_bounds_updated)
		var bounds: Dictionary = _stage_spawner.get_run_progress_bounds()
		_apply_progress_bounds(bounds)


func _on_flow_state_changed(_previous_state: GameInitializer.GameFlowState, _new_state: GameInitializer.GameFlowState) -> void:
	_refresh_progress_ui()


func _on_gameplay_finished() -> void:
	_progress_bar.value = 100.0
	_value_label.text = "100%"


func _process(_delta: float) -> void:
	if not _progress_bounds_ready:
		return
	if _player == null:
		return
	if GameInitializer.flow_state == GameInitializer.GameFlowState.TITLE_NOT_STARTED:
		return

	var denominator: float = _progress_end_x - _progress_start_x
	if denominator <= 0.0:
		return

	var ratio: float = (_player.global_position.x - _progress_start_x) / denominator
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	var percent: int = int(round(clamped_ratio * 100.0))

	_progress_bar.value = float(percent)
	_value_label.text = "%d%%" % percent


func _on_run_progress_bounds_updated(start_x: float, end_x: float) -> void:
	_progress_start_x = start_x
	_progress_end_x = end_x
	_progress_bounds_ready = end_x > start_x
	_refresh_progress_ui()


func _apply_progress_bounds(bounds: Dictionary) -> void:
	_progress_bounds_ready = bool(bounds.get("ready", false))
	_progress_start_x = float(bounds.get("start_x", 0.0))
	_progress_end_x = float(bounds.get("end_x", 1.0))


func _refresh_progress_ui() -> void:
	_title_label.text = "Run Progress"

	if GameInitializer.flow_state == GameInitializer.GameFlowState.TITLE_NOT_STARTED:
		_progress_bar.value = 0.0
		_value_label.text = "0%"
		return
	if not _progress_bounds_ready:
		_progress_bar.value = 0.0
		_value_label.text = "0%"
