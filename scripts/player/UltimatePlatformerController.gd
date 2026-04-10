extends CharacterBody2D

class_name PlatformerController2D

#INFO 必要子节点
@export_category("Necessary Child Nodes")
## 玩家动画精灵
@export var PlayerSprite: AnimatedSprite2D
## 玩家碰撞体（默认引用）
@export var PlayerCollider: CollisionShape2D
## 完整碰撞体（站立时使用）
@export var CollisionFull: CollisionShape2D
## 半高碰撞体（蹲伏/滑铲/翻滚时使用）
@export var CollisionHalf: CollisionShape2D

#INFO 水平移动
@export_category("L/R Movement")
## 游戏开始时的初始速度（跑酷/无尽奔跑模式）
@export_range(0, 500) var initialSpeed: float = 100.0
## 玩家最大移动速度
@export_range(50, 500) var maxSpeed: float = 200.0
## 按左键刹车时的最低速度
@export_range(0, 500) var minSpeed: float = 50.0
## 启用后默认速度为 maxSpeed 的一半，按住 "run" 键加速到满速
@export var runningModifier: bool = false
## 按右键时每秒加速量
@export_range(0, 1000) var speedUpRate: float = 150.0
## 按左键时每秒减速量
@export_range(0, 1000) var slowDownRate: float = 200.0
## 无输入时每秒向 initialSpeed 回归的速率
@export_range(0, 1000) var returnToInitialRate: float = 100.0
## 速度阈值：低于此值播放 "walk" 动画，达到或超过播放 "run" 动画
@export_range(0, 500) var walkSpeed: float = 120.0

#INFO 蹲伏
@export_category("Crouching")
## 从半碰撞体顶部指向完整碰撞体顶部的 RayCast2D，碰撞地面层时强制蹲伏行走
@export var ceilingRaycast: RayCast2D

#INFO 跳跃与重力
@export_category("Jumping and Gravity")
## 跳跃的最大高度
@export_range(0, 20) var jumpHeight: float = 2.0
## 落地前可执行的跳跃次数，大于 1 时禁用跳跃缓冲和土狼时间
@export_range(0, 4) var jumps: int = 1
## 重力强度
@export_range(0, 100) var gravityScale: float = 20.0
## 最大下落速度
@export_range(0, 1000) var terminalVelocity: float = 500.0
## 下落时重力倍率，使跳跃曲线更紧凑
@export_range(0.5, 3) var descendingGravityFactor: float = 1.3
## 启用后松开跳跃键时垂直速度减半，实现可变跳跃高度
@export var shortHopAkaVariableJumpHeight: bool = true
## 离开边缘后仍可跳跃的额外时间（秒）
@export_range(0, 0.5) var coyoteTime: float = 0.2
## 落地前提前按跳跃键仍能注册跳跃的时间窗口（秒）
@export_range(0, 0.5) var jumpBuffering: float = 0.2

#INFO 冲刺
@export_category("Dashing")
## 冲刺类型
@export_enum("None", "Horizontal", "Vertical", "Four Way", "Eight Way") var dashType: int
## 落地前可执行的冲刺次数
@export_range(0, 10) var dashes: int = 1
## 启用后冲刺中按反方向可取消冲刺
@export var dashCancel: bool = true
## 冲刺距离倍率
@export_range(1.5, 4) var dashLength: float = 2.5

#INFO 下键操作（翻滚/滑铲）
@export_category("Down Input")
## 启用后可通过短按下键执行翻滚
@export var canRoll: bool
## 区分短按（翻滚）和长按（滑铲）的时间阈值（秒）
@export_range(0.05, 1.0) var rollSlideThreshold: float = 0.2
## 滑铲最大持续时间（秒）
@export_range(0.5, 5.0) var maxSlideTime: float = 1.5

#INFO 动画（勾选表示拥有对应动画）
@export_category("Animations")
## 拥有 "run" 动画
@export var run: bool
## 拥有 "jump" 动画
@export var jump: bool
## 拥有 "idle" 动画
@export var idle: bool
## 拥有 "walk" 动画
@export var walk: bool
## 拥有 "slide" 动画
@export var slide: bool
## 拥有 "falling" 动画
@export var falling: bool
## 拥有 "roll" 动画
@export var roll: bool
## 拥有 "crouch_walk" 动画
@export var crouch_walk: bool


# ---- 内部状态变量 ----
var appliedGravity: float
var maxSpeedLock: float

var jumpMagnitude: float = 500.0
var jumpCount: int
var jumpWasPressed: bool = false
var coyoteActive: bool = false
var gravityActive: bool = true

var dashing: bool = false
var dashCount: int
var dash_timer: float = 0.0
var dash_duration: float = 0.0
var dash_pre_speed: float = 0.0

var rolling: bool = false
var is_sliding: bool = false
var down_press_timer: float = 0.0
var down_is_held: bool = false
var down_triggered_roll: bool = false
var slide_timer: float = 0.0
var roll_start_velocity: float = 0.0
var was_rolling_or_sliding: bool = false
var crouching: bool = false

var twoWayDashHorizontal: bool
var twoWayDashVertical: bool
var eightWayDash: bool

## movementInputMonitoring.x 控制右方向，.y 控制左方向；冲刺期间禁用输入
var movementInputMonitoring: Vector2 = Vector2(true, true)

var anim: AnimatedSprite2D
var col: CollisionShape2D
var animScaleLock: Vector2

# ---- 输入变量 ----
var upHold: bool
var downHold: bool
var leftHold: bool
var rightHold: bool
var leftTap: bool
var jumpTap: bool
var jumpRelease: bool
var runHold: bool
var dashTap: bool
var downTap: bool


func _ready() -> void:
	anim = PlayerSprite
	col = PlayerCollider
	_update_data()
	velocity.x = initialSpeed
	if CollisionFull:
		CollisionFull.disabled = false
	if CollisionHalf:
		CollisionHalf.disabled = true


func _update_data() -> void:
	jumpMagnitude = (10.0 * jumpHeight) * gravityScale
	jumpCount = jumps
	dashCount = dashes
	maxSpeedLock = maxSpeed
	animScaleLock = abs(anim.scale)

	if CollisionFull:
		CollisionFull.disabled = false
	if CollisionHalf:
		CollisionHalf.disabled = true

	if jumps > 1:
		jumpBuffering = 0
		coyoteTime = 0

	coyoteTime = abs(coyoteTime)
	jumpBuffering = abs(jumpBuffering)

	twoWayDashHorizontal = false
	twoWayDashVertical = false
	eightWayDash = false
	match dashType:
		1:
			twoWayDashHorizontal = true
		2:
			twoWayDashVertical = true
		3:
			twoWayDashHorizontal = true
			twoWayDashVertical = true
		4:
			eightWayDash = true


func _process(_delta: float) -> void:
	anim.scale.x = animScaleLock.x

	if rolling and roll:
		anim.speed_scale = 1
		anim.play("roll")
	elif is_sliding and slide and !dashing:
		anim.speed_scale = 1
		anim.play("slide")
	elif dashing:
		anim.speed_scale = 1
		anim.play("dash")
	elif velocity.y < 0 and jump:
		anim.speed_scale = 1
		anim.play("jump")
	elif velocity.y > 40 and falling:
		anim.speed_scale = 1
		anim.play("falling")
	elif crouching and is_on_floor() and crouch_walk:
		anim.speed_scale = abs(velocity.x / 150)
		anim.play("crouch_walk")
	elif is_on_floor():
		if abs(velocity.x) > 0.1 and !is_on_wall():
			anim.speed_scale = abs(velocity.x / 150)
			if abs(velocity.x) >= walkSpeed and run:
				anim.play("run")
			elif walk:
				anim.play("walk")
			elif run:
				anim.play("run")
		elif idle:
			anim.speed_scale = 1
			anim.play("idle")


func _physics_process(delta: float) -> void:
	#INFO 输入检测
	leftHold = Input.is_action_pressed("left")
	rightHold = Input.is_action_pressed("right")
	upHold = Input.is_action_pressed("up")
	downHold = Input.is_action_pressed("down")
	leftTap = Input.is_action_just_pressed("left")
	jumpTap = Input.is_action_just_pressed("jump")
	jumpRelease = Input.is_action_just_released("jump")
	runHold = Input.is_action_pressed("run")
	dashTap = Input.is_action_just_pressed("dash")
	downTap = Input.is_action_just_pressed("down")

	#INFO 水平移动（跑酷模式 - 始终向前）
	if !dashing and !rolling:
		var current_speed_up: float = speedUpRate / 2.0 if crouching else speedUpRate
		var current_slow_down: float = slowDownRate * 2.0 if crouching else slowDownRate
		var current_return_rate: float = returnToInitialRate * 2.0 if crouching else returnToInitialRate
		var current_max_speed: float = maxSpeed / 2.0 if crouching else maxSpeed

		if rightHold and movementInputMonitoring.x:
			velocity.x = min(velocity.x + current_speed_up * delta, current_max_speed)
		elif leftHold and movementInputMonitoring.y:
			velocity.x = max(velocity.x - current_slow_down * delta, minSpeed)
		else:
			if velocity.x > initialSpeed:
				velocity.x = max(velocity.x - current_return_rate * delta, initialSpeed)
			elif velocity.x < initialSpeed:
				velocity.x = min(velocity.x + current_return_rate * delta, initialSpeed)

		velocity.x = max(velocity.x, minSpeed)

	if runningModifier and !runHold:
		maxSpeed = maxSpeedLock / 2
	elif is_on_floor():
		maxSpeed = maxSpeedLock

	#INFO 翻滚/滑铲状态机（下键）
	if is_on_floor() and downTap and !rolling:
		down_press_timer = 0.0
		down_is_held = true
		down_triggered_roll = false

	if down_is_held and downHold and is_on_floor():
		down_press_timer += delta
		if down_press_timer > rollSlideThreshold and !is_sliding:
			is_sliding = true
			slide_timer = 0.0

	if is_sliding:
		slide_timer += delta
		if slide_timer >= maxSlideTime:
			is_sliding = false
			down_is_held = false
			was_rolling_or_sliding = true

	if down_is_held and !downHold:
		if down_press_timer <= rollSlideThreshold and !down_triggered_roll and is_on_floor() and canRoll:
			down_triggered_roll = true
			_start_roll()
		if is_sliding:
			was_rolling_or_sliding = true
		is_sliding = false
		down_is_held = false

	if !is_on_floor() and !downHold:
		is_sliding = false
		down_is_held = false

	#INFO 蹲伏检测
	if ceilingRaycast and is_on_floor() and !rolling and !is_sliding:
		if ceilingRaycast.is_colliding():
			crouching = true
		elif crouching:
			crouching = !_can_stand_up()
		else:
			crouching = false
	else:
		if ceilingRaycast and !ceilingRaycast.is_colliding():
			if crouching:
				crouching = !_can_stand_up()
			else:
				crouching = false

	#INFO 碰撞体切换
	if is_sliding or rolling:
		was_rolling_or_sliding = false
		if CollisionFull:
			CollisionFull.disabled = true
		if CollisionHalf:
			CollisionHalf.disabled = false
	elif crouching:
		was_rolling_or_sliding = false
		if CollisionFull:
			CollisionFull.disabled = true
		if CollisionHalf:
			CollisionHalf.disabled = false
	elif was_rolling_or_sliding:
		if CollisionFull:
			CollisionFull.disabled = false
		if CollisionHalf:
			CollisionHalf.disabled = true
		if !downHold:
			was_rolling_or_sliding = false
	elif is_on_floor() and downHold:
		if CollisionFull:
			CollisionFull.disabled = true
		if CollisionHalf:
			CollisionHalf.disabled = false
	else:
		if CollisionFull:
			CollisionFull.disabled = false
		if CollisionHalf:
			CollisionHalf.disabled = true
		if !downHold:
			was_rolling_or_sliding = false

	#INFO 跳跃与重力
	if velocity.y > 0:
		appliedGravity = gravityScale * descendingGravityFactor
	else:
		appliedGravity = gravityScale

	if gravityActive:
		if velocity.y < terminalVelocity:
			velocity.y += appliedGravity
		elif velocity.y > terminalVelocity:
			velocity.y = terminalVelocity

	if shortHopAkaVariableJumpHeight and jumpRelease and velocity.y < 0:
		velocity.y = velocity.y / 2

	if jumps == 1:
		if !is_on_floor() and !is_on_wall():
			if coyoteTime > 0:
				coyoteActive = true
				_coyote_time()

		if jumpTap and !is_on_wall():
			if coyoteActive:
				coyoteActive = false
				_jump()
			if jumpBuffering > 0:
				jumpWasPressed = true
				_buffer_jump()
			elif jumpBuffering == 0 and coyoteTime == 0 and is_on_floor():
				_jump()
		elif jumpTap and is_on_floor():
			_jump()

		if is_on_floor():
			jumpCount = jumps
			coyoteActive = true
			if jumpWasPressed:
				_jump()

	elif jumps > 1:
		if is_on_floor():
			jumpCount = jumps
		if jumpTap and jumpCount > 0 and !is_on_wall():
			velocity.y = -jumpMagnitude
			jumpCount -= 1

	#INFO 冲刺
	if dashing:
		dash_timer += delta
		if dash_timer >= dash_duration:
			_end_dash()

	if is_on_floor() and !dashing:
		dashCount = dashes

	if dashTap and dashCount > 0 and !dashing and !rolling and !is_sliding and !crouching:
		var dTime: float = 0.0625 * dashLength
		var current_dash_magnitude: float = velocity.x * dashLength
		var dash_triggered: bool = false

		if eightWayDash:
			var input_direction: Vector2 = Input.get_vector("left", "right", "up", "down")
			if input_direction != Vector2.ZERO:
				dash_pre_speed = velocity.x
				velocity = current_dash_magnitude * input_direction
				dash_triggered = true
		else:
			if twoWayDashVertical:
				if upHold and !downHold:
					dash_pre_speed = velocity.x
					velocity.x = 0
					velocity.y = -current_dash_magnitude
					dash_triggered = true
				elif downHold and !upHold:
					dash_pre_speed = velocity.x
					velocity.x = 0
					velocity.y = current_dash_magnitude
					dash_triggered = true
			if !dash_triggered and twoWayDashHorizontal and !(upHold or downHold):
				dash_pre_speed = velocity.x
				velocity.y = 0
				velocity.x = current_dash_magnitude
				dash_triggered = true

		if dash_triggered:
			dashing = true
			dash_timer = 0.0
			dash_duration = dTime
			dashCount -= 1
			gravityActive = false
			movementInputMonitoring = Vector2(false, false)

	if dashing and leftTap and dashCancel:
		_end_dash()

	move_and_slide()


# ---- 跳跃辅助函数 ----

func _buffer_jump() -> void:
	await get_tree().create_timer(jumpBuffering).timeout
	jumpWasPressed = false


func _coyote_time() -> void:
	await get_tree().create_timer(coyoteTime).timeout
	coyoteActive = false
	jumpCount -= 1


func _jump() -> void:
	if jumpCount > 0:
		velocity.y = -jumpMagnitude
		jumpCount -= 1
		jumpWasPressed = false


# ---- 冲刺辅助函数 ----

func _end_dash() -> void:
	dashing = false
	dash_timer = 0.0
	gravityActive = true
	movementInputMonitoring = Vector2(true, true)
	velocity.x = dash_pre_speed


# ---- 翻滚辅助函数 ----

func _start_roll() -> void:
	var duration: float = _get_anim_duration("roll")
	rolling = true
	roll_start_velocity = velocity.x
	await get_tree().create_timer(duration).timeout
	rolling = false
	call_deferred("_on_roll_end")


func _get_anim_duration(anim_name: String) -> float:
	var frames: SpriteFrames = anim.sprite_frames
	var count: int = frames.get_frame_count(anim_name)
	var speed: float = frames.get_animation_speed(anim_name)
	if speed <= 0:
		return 0.5
	var total: float = 0.0
	for i in range(count):
		total += frames.get_frame_duration(anim_name, i)
	return total / speed


func _on_roll_end() -> void:
	was_rolling_or_sliding = true
	if !rightHold and !leftHold:
		velocity.x = max(roll_start_velocity, minSpeed)


# ---- 碰撞体辅助函数 ----

func _can_stand_up() -> bool:
	if !CollisionFull or !CollisionHalf:
		return true
	CollisionHalf.disabled = true
	CollisionFull.disabled = false
	var blocked: bool = test_move(transform, Vector2.ZERO)
	CollisionFull.disabled = true
	CollisionHalf.disabled = false
	return !blocked
