extends CharacterBody3D

const EMPTY: String = ""
const TIME_FMT: String = "Time : %02d:%02d:%03d"
const META_START: String = "Start"
const META_CONTROL: String = "control"
const META_FINISH: String = "finsh"
const GO: String = "Go"
const NEXT_CTRL: String = "Next control: "
const NEXT_CTRL_FINISH: String = "Next control: Finsh"
const CONTROL: String = "Control "
const COLLECTED: String = " collected!"
const WRONG_CONTROL: String = "Wrong control! Need control "
const FINISH: String = "Finsh"
const FADE: String = "fade in out"
const SPRING: String = "spring_length"
const ARM_MIN: float = 0.0
const ARM_MAX: float = 6.0
const TWEEN: float = 0.33
const SEC_PER_MIN: float = 60.0
const MS_PER_SEC: float = 1000.0
const SHIFT_MULT: float = 2.0
const GRAVITY: float = 40.0
const SPEED_INC: float = 0.5
const WHEEL_STEP: float = 5.0
const SPEED_MIN: float = 5.0
const SPEED_MAX: float = 9999.0
const JUMP_SCALE: float = 0.016
const SPEED_DEFAULT: float = 50.0
const JUMP_DEFAULT: float = 2.0
const TIME_ZERO: int = 0
const ZERO: float = 0.0
const JUMP_RELEASE_KEYS: Array[int] = [KEY_Q, KEY_E, KEY_SPACE]
const CTRL_START: int = 1
const CTRL_STEP: int = 1


var start_time: int = TIME_ZERO
var course_started: bool = false
var next_control: int = CTRL_START
var _first_person: bool = false
var _gravity_enabled: bool = true
var _collision_enabled: bool = true


@export var label: Label
@export var current_control: Label
@export var time_label: Label
@export var animation: AnimationPlayer
@export var camera_arm: SpringArm3D
@export var body: MeshInstance3D
@export var collision_body: CollisionShape3D
@export var collision_ray: CollisionShape3D
@export var camera_3d: Camera3D
@export var MOVE_SPEED: float = SPEED_DEFAULT
@export var JUMP_SPEED: float = JUMP_DEFAULT
# not my code
@export var first_person: bool = false :
	set(p_value):
		_first_person = p_value
		if is_inside_tree():
			_update_first_person()
	get:
		return _first_person

@export var gravity_enabled: bool = true :
	set(p_value):
		_gravity_enabled = p_value
		if not _gravity_enabled:
			velocity.y = ZERO
	get:
		return _gravity_enabled
			
@export var collision_enabled: bool = true :
	set(p_value):
		_collision_enabled = p_value
		if is_inside_tree():
			_update_collision()
	get:
		return _collision_enabled


func _ready() -> void:
	# reset the next control text
	current_control.text = EMPTY
	_update_first_person()
	_update_collision()


func _update_first_person() -> void:
	if _first_person:
		var tween: Tween = create_tween()
		tween.tween_property(camera_arm, SPRING, ARM_MIN, TWEEN)
		tween.tween_callback(body.set_visible.bind(false))
	else:
		body.visible = true
		create_tween().tween_property(camera_arm, SPRING, ARM_MAX, TWEEN)


func _update_collision() -> void:
	collision_body.disabled = ! _collision_enabled
	collision_ray.disabled = ! _collision_enabled


func _physics_process(p_delta) -> void:
	# tell the player what there crreunt time is
	if course_started:
		var elapsed: float = float(Time.get_ticks_msec() - start_time) / MS_PER_SEC
		var minutes: int = int(elapsed / SEC_PER_MIN)
		var seconds: int = int(elapsed) % int(SEC_PER_MIN)
		var milliseconds: int = int(elapsed * MS_PER_SEC) % int(MS_PER_SEC)
		time_label.text = TIME_FMT % [minutes, seconds, milliseconds]
		
	# not my code
	var direction: Vector3 = get_camera_relative_input()
	var h_veloc: Vector2 = Vector2(direction.x, direction.z).normalized() * MOVE_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		h_veloc *= SHIFT_MULT
	velocity.x = h_veloc.x
	velocity.z = h_veloc.y
	if gravity_enabled:
		velocity.y -= GRAVITY * p_delta
	move_and_slide()


# not my code 
# Returns the input vector relative to the camera. Forward is always the direction the camera is facing
func get_camera_relative_input() -> Vector3:
	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_A): # Left
		input_dir -= camera_3d.global_transform.basis.x
	if Input.is_key_pressed(KEY_D): # Right
		input_dir += camera_3d.global_transform.basis.x
	if Input.is_key_pressed(KEY_W): # Forward
		input_dir -= camera_3d.global_transform.basis.z
	if Input.is_key_pressed(KEY_S): # Backward
		input_dir += camera_3d.global_transform.basis.z
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE): # Up
		velocity.y += JUMP_SPEED + MOVE_SPEED * JUMP_SCALE
	if Input.is_key_pressed(KEY_Q): # Down
		velocity.y -= JUMP_SPEED + MOVE_SPEED * JUMP_SCALE
	if Input.is_key_pressed(KEY_KP_ADD) or Input.is_key_pressed(KEY_EQUAL):
		MOVE_SPEED = clamp(MOVE_SPEED + SPEED_INC, SPEED_MIN, SPEED_MAX)
	if Input.is_key_pressed(KEY_KP_SUBTRACT) or Input.is_key_pressed(KEY_MINUS):
		MOVE_SPEED = clamp(MOVE_SPEED - SPEED_INC, SPEED_MIN, SPEED_MAX)
	return input_dir
	


# not my code
func _input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.pressed:
		if p_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			MOVE_SPEED = clamp(MOVE_SPEED + WHEEL_STEP, SPEED_MIN, SPEED_MAX)
		elif p_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			MOVE_SPEED = clamp(MOVE_SPEED - WHEEL_STEP, SPEED_MIN, SPEED_MAX)
	
	elif p_event is InputEventKey:
		if p_event.pressed:
			if p_event.keycode == KEY_V:
				first_person = ! first_person
			elif p_event.keycode == KEY_G:
				gravity_enabled = ! gravity_enabled
			elif p_event.keycode == KEY_C:
				collision_enabled = ! collision_enabled

		# Else if up/down released
		elif p_event.keycode in JUMP_RELEASE_KEYS:
			velocity.y = ZERO


func _on_area_3d_area_entered(area: Area3D) -> void:
	# if the player puntched the start start the corce
	if area.has_meta(META_START) and not course_started:
		start_time = Time.get_ticks_msec()
		course_started = true
		next_control = CTRL_START
		label.text = GO
		current_control.text = NEXT_CTRL + str(next_control)
		animation.play(FADE)

	if area.has_meta(META_CONTROL) and course_started:
		# check if the contral is the right one and tell the player
		if area.control_number == next_control and next_control + CTRL_STEP != Global.finsh_control:
			next_control += CTRL_STEP
			label.text = CONTROL + str(area.control_number) + COLLECTED
			current_control.text = NEXT_CTRL + str(next_control)
			animation.play(FADE)
		
		# if the next control is the finsh tell the player
		elif area.control_number == next_control and next_control + CTRL_STEP == Global.finsh_control:
			next_control += CTRL_STEP
			label.text = CONTROL + str(area.control_number) + COLLECTED
			current_control.text = NEXT_CTRL_FINISH
			animation.play(FADE)
			
		# if the control is wrong tell the player witch one is
		else:
			label.text = WRONG_CONTROL + str(next_control)
			animation.play(FADE)
		
	# check if the player can finsh the corce and stops the timer if so
	if area.has_meta(META_FINISH) and course_started:
		if Global.finsh_control == next_control:
			label.text = FINISH
			animation.play(FADE)
			course_started = false
			start_time = TIME_ZERO
		else:
			label.text = WRONG_CONTROL + str(next_control)
			animation.play(FADE)
