extends CharacterBody2D

class_name PlatformerController2D

@export var README: String = "IMPORTANT: MAKE SURE TO ASSIGN 'left' 'right' 'jump' 'dash' 'up' 'down' in the project settings input map. Usage tips. 1. Hover over each toggle and variable to read what it does and to make sure nothing bugs. 2. Animations are very primitive. To make full use of your custom art, you may want to slightly change the code for the animations"
#INFO READEME 
#IMPORTANT: MAKE SURE TO ASSIGN 'left' 'right' 'jump' 'dash' 'up' 'down' in the project settings input map. THIS IS REQUIRED
#Usage tips. 
#1. Hover over each toggle and variable to read what it does and to make sure nothing bugs. 
#2. Animations are very primitive. To make full use of your custom art, you may want to slightly change the code for the animations

@export_category("Necesary Child Nodes")
@export var PlayerSprite: AnimatedSprite2D
@export var PlayerCollider: CollisionShape2D
@export var CollisionFull: CollisionShape2D
@export var CollisionHalf: CollisionShape2D

#INFO HORIZONTAL MOVEMENT 
@export_category("L/R Movement")
##The initial speed your player will have at the start of the game (for parkour/endless runner games)
@export_range(0, 500) var initialSpeed: float = 100.0
##The max speed your player will move
@export_range(50, 500) var maxSpeed: float = 200.0
##The minimum speed when pressing left key to brake
@export_range(0, 500) var minSpeed: float = 50.0
##If enabled, the default movement speed will by 1/2 of the maxSpeed and the player must hold a "run" button to accelerate to max speed. Assign "run" (case sensitive) in the project input settings.
@export var runningModifier: bool = false
##How fast (per second) speed increases when pressing right key
@export_range(0, 1000) var speedUpRate: float = 150.0
##How fast (per second) speed decreases when pressing left key
@export_range(0, 1000) var slowDownRate: float = 200.0
##How fast (per second) speed returns to initialSpeed when no input is pressed
@export_range(0, 1000) var returnToInitialRate: float = 100.0
##Speed threshold: below this plays "walk" animation, at or above plays "run" animation
@export_range(0, 500) var walkSpeed: float = 120.0

@export_category("Crouching")
##RayCast2D pointing upward from half-collider top to full-collider top. If colliding with floor layer, player is forced into crouch walk.
@export var ceilingRaycast: RayCast2D

#INFO JUMPING 
@export_category("Jumping and Gravity")
##The peak height of your player's jump
@export_range(0, 20) var jumpHeight: float = 2.0
##How many jumps your character can do before needing to touch the ground again. Giving more than 1 jump disables jump buffering and coyote time.
@export_range(0, 4) var jumps: int = 1
##The strength at which your character will be pulled to the ground.
@export_range(0, 100) var gravityScale: float = 20.0
##The fastest your player can fall
@export_range(0, 1000) var terminalVelocity: float = 500.0
##Your player will move this amount faster when falling providing a less floaty jump curve.
@export_range(0.5, 3) var descendingGravityFactor: float = 1.3
##Enabling this toggle makes it so that when the player releases the jump key while still ascending, their vertical velocity will cut in half, providing variable jump height.
@export var shortHopAkaVariableJumpHeight: bool = true
##How much extra time (in seconds) your player will be given to jump after falling off an edge. This is set to 0.2 seconds by default.
@export_range(0, 0.5) var coyoteTime: float = 0.2
##The window of time (in seconds) that your player can press the jump button before hitting the ground and still have their input registered as a jump. This is set to 0.2 seconds by default.
@export_range(0, 0.5) var jumpBuffering: float = 0.2

#INFO EXTRAS
@export_category("Wall Jumping")
##Allows your player to jump off of walls. Without a Wall Kick Angle, the player will be able to scale the wall.
@export var wallJump: bool = false
##How long the player's movement input will be ignored after wall jumping.
@export_range(0, 0.5) var inputPauseAfterWallJump: float = 0.1
##The angle at which your player will jump away from the wall. 0 is straight away from the wall, 90 is straight up. Does not account for gravity
@export_range(0, 90) var wallKickAngle: float = 60.0
##The player's gravity will be divided by this number when touch a wall and descending. Set to 1 by default meaning no change will be made to the gravity and there is effectively no wall sliding. THIS IS OVERRIDDED BY WALL LATCH.
@export_range(1, 20) var wallSliding: float = 1.0
##If enabled, the player's gravity will be set to 0 when touching a wall and descending. THIS WILL OVERRIDE WALLSLIDING.
@export var wallLatching: bool = false
##wall latching must be enabled for this to work. #If enabled, the player must hold down the "latch" key to wall latch. Assign "latch" in the project input settings. The player's input will be ignored when latching.
@export var wallLatchingModifer: bool = false
@export_category("Dashing")
##The type of dashes the player can do.
@export_enum("None", "Horizontal", "Vertical", "Four Way", "Eight Way") var dashType: int
##How many dashes your player can do before needing to hit the ground.
@export_range(0, 10) var dashes: int = 1
##If enabled, pressing the opposite direction of a dash, during a dash, will zero the player's velocity.
@export var dashCancel: bool = true
##How far the player will dash. One of the dashing toggles must be on for this to be used.
@export_range(1.5, 4) var dashLength: float = 2.5
@export_category("Corner Cutting/Jump Correct")
##If the player's head is blocked by a jump but only by a little, the player will be nudged in the right direction and their jump will execute as intended. NEEDS RAYCASTS TO BE ATTACHED TO THE PLAYER NODE. AND ASSIGNED TO MOUNTING RAYCAST. DISTANCE OF MOUNTING DETERMINED BY PLACEMENT OF RAYCAST.
@export var cornerCutting: bool = false
##How many pixels the player will be pushed (per frame) if corner cutting is needed to correct a jump.
@export_range(1, 5) var correctionAmount: float = 1.5
##Raycast used for corner cutting calculations. Place above and to the left of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export var leftRaycast: RayCast2D
##Raycast used for corner cutting calculations. Place above of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export var middleRaycast: RayCast2D
##Raycast used for corner cutting calculations. Place above and to the right of the players head point up. ALL ARE NEEDED FOR IT TO WORK.
@export var rightRaycast: RayCast2D
@export_category("Down Input")
##Holding down and pressing the input for "roll" will execute a roll if the player is grounded.
@export var canRoll: bool
##If enabled, the player will stop all horizontal movement midair, wait (groundPoundPause) seconds, and then slam down into the ground when down is pressed. 
@export var groundPound: bool
##The amount of time the player will hover in the air before completing a ground pound (in seconds)
@export_range(0.05, 0.75) var groundPoundPause: float = 0.25
##If enabled, pressing up will end the ground pound early
@export var upToCancel: bool = false
##Time threshold (seconds) to distinguish short press (roll) from hold (slide) on down key
@export_range(0.05, 1.0) var rollSlideThreshold: float = 0.2
##Maximum duration (seconds) the player can slide before automatically exiting
@export_range(0.5, 5.0) var maxSlideTime: float = 1.5



@export_category("Animations (Check Box if has animation)")
##Animations must be named "run" all lowercase as the check box says
@export var run: bool
##Animations must be named "jump" all lowercase as the check box says
@export var jump: bool
##Animations must be named "idle" all lowercase as the check box says
@export var idle: bool
##Animations must be named "walk" all lowercase as the check box says
@export var walk: bool
##Animations must be named "slide" all lowercase as the check box says
@export var slide: bool
##Animations must be named "latch" all lowercase as the check box says
@export var latch: bool
##Animations must be named "falling" all lowercase as the check box says
@export var falling: bool
##Animations must be named "roll" all lowercase as the check box says
@export var roll: bool
##Animations must be named "crouch_walk" all lowercase as the check box says
@export var crouch_walk: bool



#Variables determined by the developer set ones.
var appliedGravity: float
var maxSpeedLock: float
var appliedTerminalVelocity: float

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
var roll_start_velocity: float = 0.0  # Store velocity at roll start
var was_rolling_or_sliding: bool = false  # Track if we just finished roll/slide
var crouching: bool = false

var twoWayDashHorizontal
var twoWayDashVertical
var eightWayDash

var wasMovingR: bool
var wasPressingR: bool
var movementInputMonitoring: Vector2 = Vector2(true, true) #movementInputMonitoring.x addresses right direction while .y addresses left direction

var gdelta: float = 1

var dset = false

var latched
var wasLatched
var groundPounding

var anim
var col
var animScaleLock : Vector2

#Input Variables for the whole script
var upHold
var downHold
var leftHold
var leftTap
var leftRelease
var rightHold
var rightTap
var rightRelease
var jumpTap
var jumpRelease
var runHold
var latchHold
var dashTap
var rollTap
var downTap
var downRelease
var twirlTap

func _ready():
	wasMovingR = true
	anim = PlayerSprite
	col = PlayerCollider
	
	_updateData()
	
	# Set initial speed for parkour/endless runner games
	velocity.x = initialSpeed
	
	# Ensure collision shapes are properly initialized
	if CollisionFull:
		CollisionFull.disabled = false
	if CollisionHalf:
		CollisionHalf.disabled = true
	
func _updateData():
	jumpMagnitude = (10.0 * jumpHeight) * gravityScale
	jumpCount = jumps
	
	dashCount = dashes
	
	maxSpeedLock = maxSpeed
	
	animScaleLock = abs(anim.scale)
	
	# Initialize collision shapes: full is default, half is disabled
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
	if dashType == 0:
		pass
	if dashType == 1:
		twoWayDashHorizontal = true
	elif dashType == 2:
		twoWayDashVertical = true
	elif dashType == 3:
		twoWayDashHorizontal = true
		twoWayDashVertical = true
	elif dashType == 4:
		eightWayDash = true
	
	

func _process(_delta):
	#INFO animations
	#wall latch detection
	if is_on_wall() and !is_on_floor() and latch and wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
		latched = true
	else:
		latched = false
		wasLatched = true
		_setLatch(0.2, false)

	# Parkour mode: always face right
	anim.scale.x = animScaleLock.x
	
	# Rolling animation (highest priority, one-shot)
	if rolling and roll:
		anim.speed_scale = 1
		anim.play("roll")
	# Sliding animation (ground slide)
	elif is_sliding and slide and !dashing:
		anim.speed_scale = 1
		anim.play("slide")
	# Dashing animation
	elif dashing:
		anim.speed_scale = 1
		anim.play("dash")
	# Wall latch
	elif latch and latched and !wasLatched:
		anim.speed_scale = 1
		anim.play("latch")
	# Jump
	elif velocity.y < 0 and jump:
		anim.speed_scale = 1
		anim.play("jump")
	# Falling
	elif velocity.y > 40 and falling:
		anim.speed_scale = 1
		anim.play("falling")
	# Crouch walk (before normal walk/run/idle)
	elif crouching and is_on_floor() and crouch_walk:
		anim.speed_scale = abs(velocity.x / 150)
		anim.play("crouch_walk")
	# Walk / Run / Idle on floor
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


func _physics_process(delta):
	if !dset:
		gdelta = delta
		dset = true
	#INFO Input Detectio. Define your inputs from the project settings here.
	leftHold = Input.is_action_pressed("left")
	rightHold = Input.is_action_pressed("right")
	upHold = Input.is_action_pressed("up")
	downHold = Input.is_action_pressed("down")
	leftTap = Input.is_action_just_pressed("left")
	rightTap = Input.is_action_just_pressed("right")
	leftRelease = Input.is_action_just_released("left")
	rightRelease = Input.is_action_just_released("right")
	jumpTap = Input.is_action_just_pressed("jump")
	jumpRelease = Input.is_action_just_released("jump")
	runHold = Input.is_action_pressed("run")
	latchHold = Input.is_action_pressed("latch")
	dashTap = Input.is_action_just_pressed("dash")
	rollTap = Input.is_action_just_pressed("roll")
	downTap = Input.is_action_just_pressed("down")
	downRelease = Input.is_action_just_released("down")
	twirlTap = Input.is_action_just_pressed("twirl")
	
	#INFO Left and Right Movement (Parkour Mode - Always moving forward)
	# During roll, maintain current speed to prevent stopping
	if !dashing and !rolling:
		var current_speed_up = speedUpRate / 2.0 if crouching else speedUpRate
		var current_slow_down = slowDownRate * 2.0 if crouching else slowDownRate
		var current_return_rate = returnToInitialRate * 2.0 if crouching else returnToInitialRate
		var current_max_speed = maxSpeed / 2.0 if crouching else maxSpeed
		
		if rightHold and movementInputMonitoring.x:
			# Right key - accelerate toward maxSpeed (halved when crouching)
			velocity.x = min(velocity.x + current_speed_up * delta, current_max_speed)
		elif leftHold and movementInputMonitoring.y:
			# Left key - decelerate toward minSpeed
			velocity.x = max(velocity.x - current_slow_down * delta, minSpeed)
		else:
			# No input - return toward initialSpeed
			if velocity.x > initialSpeed:
				velocity.x = max(velocity.x - current_return_rate * delta, initialSpeed)
			elif velocity.x < initialSpeed:
				velocity.x = min(velocity.x + current_return_rate * delta, initialSpeed)
		
		# Ensure speed never drops below minSpeed (only when not dashing)
		velocity.x = max(velocity.x, minSpeed)
	
	# Always moving right in parkour mode
	wasMovingR = true
	if rightTap:
		wasPressingR = true
	if leftTap:
		wasPressingR = false
	
	if runningModifier and !runHold:
		maxSpeed = maxSpeedLock / 2
	elif is_on_floor(): 
		maxSpeed = maxSpeedLock
			
	#INFO Roll/Slide State Machine (Down key)
	# Start tracking DOWN when pressed on floor
	if is_on_floor() and downTap and !rolling:
		down_press_timer = 0.0
		down_is_held = true
		down_triggered_roll = false
	
	# Accumulate timer while held on floor
	if down_is_held and downHold and is_on_floor():
		down_press_timer += delta
		if down_press_timer > rollSlideThreshold and !is_sliding:
			# Hold past threshold - enter slide state
			is_sliding = true
			slide_timer = 0.0
	
	# Count slide duration and auto-exit when exceeding max time
	if is_sliding:
		slide_timer += delta
		if slide_timer >= maxSlideTime:
			is_sliding = false
			down_is_held = false
			was_rolling_or_sliding = true  # Mark that we just finished sliding
	
	# Down released (or no longer held) - check for roll or exit slide
	if down_is_held and !downHold:
		if down_press_timer <= rollSlideThreshold and !down_triggered_roll and is_on_floor() and canRoll:
			# Short press - trigger roll (only animation + collider, no speed change)
			down_triggered_roll = true
			_start_roll()
		# Exit slide state
		if is_sliding:
			was_rolling_or_sliding = true  # Mark that we just finished sliding
		is_sliding = false
		down_is_held = false
	
	# Cancel slide if genuinely airborne (not holding down)
	if !is_on_floor() and !downHold:
		is_sliding = false
		down_is_held = false
	
	#INFO Crouch detection: if on floor, not rolling/sliding, and ceiling raycast hits
	if ceilingRaycast and is_on_floor() and !rolling and !is_sliding:
		if ceilingRaycast.is_colliding():
			crouching = true
		elif crouching:
			# Raycast clear, but verify full collider fits before standing up
			crouching = !_can_stand_up()
		else:
			crouching = false
	else:
		if ceilingRaycast and !ceilingRaycast.is_colliding():
			if crouching:
				crouching = !_can_stand_up()
			else:
				crouching = false
	
	# Switch collision shapes: prioritize roll/slide state
	# During roll/slide: always use half
	# After roll/slide ends: use full even if down is still held (until down is released or new roll/slide starts)
	# When pressing down on floor (but not in roll/slide and not just finished): use half
	if is_sliding or rolling:
		# Keep half collision during roll or slide
		was_rolling_or_sliding = false  # Reset flag when entering roll/slide
		if CollisionFull:
			CollisionFull.disabled = true
		if CollisionHalf:
			CollisionHalf.disabled = false
	elif crouching:
		# Crouch walk: use half collision
		was_rolling_or_sliding = false
		if CollisionFull:
			CollisionFull.disabled = true
		if CollisionHalf:
			CollisionHalf.disabled = false
	elif was_rolling_or_sliding:
		# After roll/slide ends, use full collision even if down is still held
		if CollisionFull:
			CollisionFull.disabled = false
		if CollisionHalf:
			CollisionHalf.disabled = true
		# Reset flag when down is released, allowing normal behavior again
		if !downHold:
			was_rolling_or_sliding = false
	elif is_on_floor() and downHold and !groundPounding:
		# Immediately switch to half collision when pressing down on floor (but not during/after roll/slide)
		if CollisionFull:
			CollisionFull.disabled = true
		if CollisionHalf:
			CollisionHalf.disabled = false
	else:
		# Use full collision in all other cases
		if CollisionFull:
			CollisionFull.disabled = false
		if CollisionHalf:
			CollisionHalf.disabled = true
		# Reset flag when not holding down
		if !downHold:
			was_rolling_or_sliding = false
			
	#INFO Jump and Gravity
	if velocity.y > 0:
		appliedGravity = gravityScale * descendingGravityFactor
	else:
		appliedGravity = gravityScale
	
	if is_on_wall() and !groundPounding:
		appliedTerminalVelocity = terminalVelocity / wallSliding
		if wallLatching and ((wallLatchingModifer and latchHold) or !wallLatchingModifer):
			appliedGravity = 0
			
			if velocity.y < 0:
				velocity.y += 50
			if velocity.y > 0:
				velocity.y = 0
				
			if wallLatchingModifer and latchHold and movementInputMonitoring == Vector2(true, true):
				velocity.x = 0
			
		elif wallSliding != 1 and velocity.y > 0:
			appliedGravity = appliedGravity / wallSliding
	elif !is_on_wall() and !groundPounding:
		appliedTerminalVelocity = terminalVelocity
	
	if gravityActive:
		if velocity.y < appliedTerminalVelocity:
			velocity.y += appliedGravity
		elif velocity.y > appliedTerminalVelocity:
				velocity.y = appliedTerminalVelocity
		
	if shortHopAkaVariableJumpHeight and jumpRelease and velocity.y < 0:
		velocity.y = velocity.y / 2
	
	if jumps == 1:
		if !is_on_floor() and !is_on_wall():
			if coyoteTime > 0:
				coyoteActive = true
				_coyoteTime()
				
		if jumpTap and !is_on_wall():
			if coyoteActive:
				coyoteActive = false
				_jump()
			if jumpBuffering > 0:
				jumpWasPressed = true
				_bufferJump()
			elif jumpBuffering == 0 and coyoteTime == 0 and is_on_floor():
				_jump()	
		elif jumpTap and is_on_wall() and !is_on_floor():
			if wallJump and !latched:
				_wallJump()
			elif wallJump and latched:
				_wallJump()
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
			jumpCount = jumpCount - 1
			_endGroundPound()
		elif jumpTap and is_on_wall() and wallJump:
			_wallJump()
			
			
	#INFO dashing
	# Dash timer: count down and end dash when duration expires
	if dashing:
		dash_timer += delta
		if dash_timer >= dash_duration:
			_end_dash()
	
	# Reset dash count only when on floor and NOT currently dashing
	if is_on_floor() and !dashing:
		dashCount = dashes
	
	# Trigger new dash (must not be dashing, rolling, sliding, or crouching)
	if dashTap and dashCount > 0 and !dashing and !rolling and !is_sliding and !crouching:
		var dTime = 0.0625 * dashLength
		var current_dash_magnitude = velocity.x * dashLength
		var dash_triggered = false
		
		if eightWayDash:
			var input_direction = Input.get_vector("left", "right", "up", "down")
			if input_direction != Vector2.ZERO:
				dash_pre_speed = velocity.x
				velocity = current_dash_magnitude * input_direction
				dash_triggered = true
		else:
			# Check vertical dash first (has priority when Four Way is enabled)
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
			# Horizontal dash: always forward in parkour mode (only if vertical didn't trigger)
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
	
	# Dash cancel: pressing left during dash ends it early, restoring pre-dash speed
	if dashing and leftTap and dashCancel:
		_end_dash()
	
	#INFO Corner Cutting
	if cornerCutting:
		if velocity.y < 0 and leftRaycast.is_colliding() and !rightRaycast.is_colliding() and !middleRaycast.is_colliding():
			position.x += correctionAmount
		if velocity.y < 0 and !leftRaycast.is_colliding() and rightRaycast.is_colliding() and !middleRaycast.is_colliding():
			position.x -= correctionAmount
			
	#INFO Ground Pound
	if groundPound and downTap and !is_on_floor() and !is_on_wall():
		groundPounding = true
		gravityActive = false
		velocity.y = 0
		await get_tree().create_timer(groundPoundPause).timeout
		_groundPound()
	if is_on_floor() and groundPounding:
		_endGroundPound()
	move_and_slide()
	
	if upToCancel and upHold and groundPound:
		_endGroundPound()
	
func _bufferJump():
	await get_tree().create_timer(jumpBuffering).timeout
	jumpWasPressed = false

func _coyoteTime():
	await get_tree().create_timer(coyoteTime).timeout
	coyoteActive = false
	jumpCount += -1

	
func _jump():
	if jumpCount > 0:
		velocity.y = -jumpMagnitude
		jumpCount += -1
		jumpWasPressed = false
		
func _wallJump():
	var horizontalWallKick = abs(jumpMagnitude * cos(wallKickAngle * (PI / 180)))
	var verticalWallKick = abs(jumpMagnitude * sin(wallKickAngle * (PI / 180)))
	velocity.y = -verticalWallKick
	var dir = 1
	if wallLatchingModifer and latchHold:
		dir = -1
	if wasMovingR:
		velocity.x = -horizontalWallKick  * dir
	else:
		velocity.x = horizontalWallKick * dir
	if inputPauseAfterWallJump != 0:
		movementInputMonitoring = Vector2(false, false)
		_inputPauseReset(inputPauseAfterWallJump)
			
func _setLatch(delay, setBool):
	await get_tree().create_timer(delay).timeout
	wasLatched = setBool
			
func _inputPauseReset(time):
	await get_tree().create_timer(time).timeout
	movementInputMonitoring = Vector2(true, true)
	

func _end_dash():
	dashing = false
	dash_timer = 0.0
	gravityActive = true
	movementInputMonitoring = Vector2(true, true)
	# Restore pre-dash horizontal speed
	velocity.x = dash_pre_speed

func _start_roll():
	# Roll duration is determined by the roll animation's actual length
	var duration = _get_anim_duration("roll")
	rolling = true
	# Store velocity before roll to maintain momentum
	roll_start_velocity = velocity.x
	await get_tree().create_timer(duration).timeout
	rolling = false
	# Use call_deferred to ensure collision shape switch happens after physics step
	call_deferred("_on_roll_end")

func _get_anim_duration(anim_name: String) -> float:
	var frames = anim.sprite_frames
	var count = frames.get_frame_count(anim_name)
	var speed = frames.get_animation_speed(anim_name)
	if speed <= 0:
		return 0.5
	var total = 0.0
	for i in range(count):
		total += frames.get_frame_duration(anim_name, i)
	return total / speed

func _groundPound():
	appliedTerminalVelocity = terminalVelocity * 10
	velocity.y = jumpMagnitude * 2
	
func _endGroundPound():
	groundPounding = false
	appliedTerminalVelocity = terminalVelocity
	gravityActive = true

func _on_roll_end():
	# Mark that roll just finished
	was_rolling_or_sliding = true
	# Ensure velocity is maintained after roll ends (prevent sudden stop)
	# Only restore if no input is being held, otherwise let normal movement logic handle it
	if !rightHold and !leftHold:
		velocity.x = max(roll_start_velocity, minSpeed)
	# Collision shape will be switched in _physics_process based on was_rolling_or_sliding flag

func _can_stand_up() -> bool:
	if !CollisionFull or !CollisionHalf:
		return true
	# Temporarily switch to full collider to test if it fits
	CollisionHalf.disabled = true
	CollisionFull.disabled = false
	var blocked = test_move(transform, Vector2.ZERO)
	# Restore half collider
	CollisionFull.disabled = true
	CollisionHalf.disabled = false
	return !blocked

func _placeHolder():
	print("")
