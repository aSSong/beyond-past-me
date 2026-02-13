extends Node2D
class_name StageBase
## 区域基类脚本
## 挂载在每个区域场景的根节点上，自动计算区域尺寸并转发检查点信号

## 当玩家到达此区域的检查点时发出，参数为此区域实例
signal checkpoint_reached(stage: Node2D)

## 区域的像素宽度（在 _ready 中自动计算）
var stage_width: float = 0.0
## 区域的左边界偏移量（tile 起始列可能不为 0）
var _left_offset: float = 0.0


func _ready() -> void:
	print("[StageBase] _ready called for: ", name)
	_calculate_dimensions()
	_connect_checkpoint()
	print("[StageBase] stage_width=", stage_width, " left_offset=", _left_offset)


## 获取区域的左边界偏移（像素）
func get_left_offset() -> float:
	return _left_offset


## 通过 TileMapLayer 的 get_used_rect() 自动计算区域宽度和偏移
func _calculate_dimensions() -> void:
	var tile_layer: TileMapLayer = _find_tile_map_layer()
	if tile_layer == null:
		push_warning("StageBase: 未找到 TileMapLayer 子节点")
		return
	var used_rect: Rect2i = tile_layer.get_used_rect()
	var tile_size: Vector2i = tile_layer.tile_set.tile_size
	## 宽度 = 使用的 tile 列数 * 单个 tile 宽度 * 场景缩放 X
	stage_width = used_rect.size.x * tile_size.x * scale.x
	## 左边界偏移 = 起始 tile 列号 * 单个 tile 宽度 * 场景缩放 X
	_left_offset = used_rect.position.x * tile_size.x * scale.x


## 在子节点中查找第一个 TileMapLayer
func _find_tile_map_layer() -> TileMapLayer:
	for child: Node in get_children():
		if child is TileMapLayer:
			return child
	return null


## 连接 CheckPoint_start 的 player_entered 信号
func _connect_checkpoint() -> void:
	var cp: Node = find_child("CheckPoint_start", true, false)
	if cp == null:
		push_warning("StageBase: 未找到 CheckPoint_start 子节点")
		return
	if cp.has_signal("player_entered"):
		cp.player_entered.connect(_on_checkpoint_entered)
	else:
		push_warning("StageBase: CheckPoint_start 没有 player_entered 信号，请确认脚本已挂载")


func _on_checkpoint_entered() -> void:
	checkpoint_reached.emit(self)
