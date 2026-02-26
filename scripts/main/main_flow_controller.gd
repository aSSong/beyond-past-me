extends Node2D
class_name MainFlowController
## 主流程控制器
## 负责标题阶段、UI切换、按D开跑与玩家初始状态管理

#INFO: 节点引用配置
## StageSpawner 节点路径
@export var stage_spawner_path: NodePath = NodePath("StageSpawner")
## 玩家节点路径
@export var player_path: NodePath = NodePath("player")
## 标题 UI 节点路径（CanvasLayer）
@export var ui_maintitle_path: NodePath = NodePath("ui_maintitle")
## 游戏内主 UI 节点路径（CanvasLayer）
@export var ui_main_path: NodePath = NodePath("UI_main")

var _stage_spawner: StageSpawner
var _player: PlatformerController2D
var _ui_maintitle: CanvasLayer
var _ui_main: CanvasLayer


func _ready() -> void:
	_cache_nodes()
	_initialize_title_state()


func _unhandled_input(event: InputEvent) -> void:
	if GameInitializer.flow_state != GameInitializer.GameFlowState.TITLE_NOT_STARTED:
		return
	if event.is_action_pressed("right"):
		_start_gameplay_flow()


func _cache_nodes() -> void:
	_stage_spawner = get_node_or_null(stage_spawner_path) as StageSpawner
	_player = get_node_or_null(player_path) as PlatformerController2D
	_ui_maintitle = get_node_or_null(ui_maintitle_path) as CanvasLayer
	_ui_main = get_node_or_null(ui_main_path) as CanvasLayer


func _initialize_title_state() -> void:
	GameInitializer.reset_to_title_state()
	if _ui_maintitle != null:
		_ui_maintitle.visible = true
	if _ui_main != null:
		_ui_main.visible = false
	_freeze_player_to_idle()


func _freeze_player_to_idle() -> void:
	if _player == null:
		return
	_player.velocity = Vector2.ZERO
	_player.set_physics_process(false)
	if _player.PlayerSprite != null:
		_player.PlayerSprite.play("idle")


func _start_gameplay_flow() -> void:
	if not GameInitializer.request_game_start():
		return

	if _ui_maintitle != null:
		_ui_maintitle.visible = false
	if _ui_main != null:
		_ui_main.visible = true

	_unfreeze_player_for_run()
	if _stage_spawner != null:
		_stage_spawner.start_gameplay_sequence()


func _unfreeze_player_for_run() -> void:
	if _player == null:
		return
	_player.set_physics_process(true)
	_player.velocity.x = _player.initialSpeed
