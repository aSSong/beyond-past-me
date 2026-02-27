extends Control
## 跑步进度显示组件
## 显示当前正式流程(1~6)完成度

#INFO: 进度配置
## StageSpawner 节点路径（用于读取正式关卡总数）
@export var stage_spawner_path: NodePath = NodePath("../../StageSpawner")
## 正式关卡总数回退值（当未找到 StageSpawner 时使用）
@export var fallback_total_gameplay_stages: int = 6

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _progress_bar: ProgressBar = $MarginContainer/VBoxContainer/ProgressBar
@onready var _value_label: Label = $MarginContainer/VBoxContainer/ValueLabel

var _total_gameplay_stages: int = 6


func _ready() -> void:
	_resolve_total_gameplay_stages()
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 100.0
	_progress_bar.value = 0.0
	_refresh_progress_ui()

	GameInitializer.stage_advanced.connect(_on_stage_advanced)
	GameInitializer.flow_state_changed.connect(_on_flow_state_changed)
	GameInitializer.gameplay_finished.connect(_on_gameplay_finished)


func _resolve_total_gameplay_stages() -> void:
	_total_gameplay_stages = max(fallback_total_gameplay_stages, 1)
	var stage_spawner: StageSpawner = get_node_or_null(stage_spawner_path) as StageSpawner
	if stage_spawner != null:
		_total_gameplay_stages = max(stage_spawner.gameplay_stage_count, 1)


func _on_stage_advanced(_new_stage_index: int) -> void:
	_refresh_progress_ui()


func _on_flow_state_changed(_previous_state: GameInitializer.GameFlowState, _new_state: GameInitializer.GameFlowState) -> void:
	_refresh_progress_ui()


func _on_gameplay_finished() -> void:
	_progress_bar.value = 100.0
	_value_label.text = "100%"


func _refresh_progress_ui() -> void:
	_title_label.text = "Run Progress"

	if GameInitializer.flow_state == GameInitializer.GameFlowState.TITLE_NOT_STARTED:
		_progress_bar.value = 0.0
		_value_label.text = "0%"
		return

	var completed_stages: int = clampi(GameInitializer.current_stage_index + 1, 0, _total_gameplay_stages)
	var ratio: float = float(completed_stages) / float(_total_gameplay_stages)
	var percent: int = int(round(ratio * 100.0))

	_progress_bar.value = float(percent)
	_value_label.text = "%d%%" % percent
