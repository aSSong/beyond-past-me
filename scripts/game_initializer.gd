extends Node
## 游戏全局生命周期管理器（Autoload 单例）
## 管理金币计数、区域进度等全局游戏状态

signal coins_changed(new_count: int)
## 当玩家进入新区域时发出，参数为新的区域索引
signal stage_advanced(new_stage_index: int)
## 当游戏流程状态切换时发出，参数为(旧状态, 新状态)
signal flow_state_changed(previous_state: GameFlowState, new_state: GameFlowState)
## 当玩家请求从标题阶段开始正式流程时发出
signal game_start_requested
## 当正式流程(1~6关)完成时发出
signal gameplay_finished
## 当进入结束界面阶段时发出
signal end_screen_entered

enum GameFlowState {
	TITLE_NOT_STARTED,
	RUNNING,
	PAUSED,
	FLOW_FINISHED,
	END_SCREEN,
}

var coins: int = 0
## 玩家当前所处的区域索引（从 0 开始，-1 表示尚未进入任何区域）
var current_stage_index: int = -1
## 当前流程状态（默认处于标题且尚未开始）
var flow_state: GameFlowState = GameFlowState.TITLE_NOT_STARTED

func add_coin() -> void:
	coins += 1
	coins_changed.emit(coins)

## 推进到下一个区域，更新索引并发出信号，返回新的区域索引
func advance_stage() -> int:
	current_stage_index += 1
	stage_advanced.emit(current_stage_index)
	return current_stage_index


## 重置局内数据（用于新一轮流程）
func reset_run_data() -> void:
	coins = 0
	current_stage_index = -1
	coins_changed.emit(coins)
	stage_advanced.emit(current_stage_index)


## 重置到标题未开始状态，并重置局内数据
func reset_to_title_state() -> void:
	reset_run_data()
	_set_flow_state(GameFlowState.TITLE_NOT_STARTED)


## 请求从标题阶段开始正式流程
func request_game_start() -> bool:
	if flow_state != GameFlowState.TITLE_NOT_STARTED:
		return false
	_set_flow_state(GameFlowState.RUNNING)
	game_start_requested.emit()
	return true


## 设置暂停状态
func set_paused_state(paused: bool) -> void:
	if paused:
		if flow_state == GameFlowState.RUNNING:
			_set_flow_state(GameFlowState.PAUSED)
	else:
		if flow_state == GameFlowState.PAUSED:
			_set_flow_state(GameFlowState.RUNNING)


## 标记正式流程结束（第6关完成）
func mark_gameplay_finished() -> void:
	if flow_state == GameFlowState.FLOW_FINISHED or flow_state == GameFlowState.END_SCREEN:
		return
	_set_flow_state(GameFlowState.FLOW_FINISHED)
	gameplay_finished.emit()


## 进入结束界面阶段
func enter_end_screen() -> void:
	if flow_state == GameFlowState.END_SCREEN:
		return
	_set_flow_state(GameFlowState.END_SCREEN)
	end_screen_entered.emit()


func _set_flow_state(new_state: GameFlowState) -> void:
	if flow_state == new_state:
		return
	var previous_state: GameFlowState = flow_state
	flow_state = new_state
	flow_state_changed.emit(previous_state, flow_state)
