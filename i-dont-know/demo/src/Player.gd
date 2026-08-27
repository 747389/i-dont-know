extends CharacterBody3D


const INPUT_OPEN_MAP := "Q"
const SAVE_PATH := "user://save_score.data"
const EMPTY: String = ""
const FINSH_TIME: String = "Time : %02d:%02d:%03d"
const META_START: String = "Start"
const META_CONTROL: String = "control"
const META_FINISH: String = "Finish"
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
const JUMP_RELEASE_KEYS: Array[int] = [KEY_Q, KEY_E, KEY_SPACE]
const CTRL_START: int = 1
const CTRL_STEP: int = 1
const MAX_SCORES: int = 5


var start_time: int = 0
var course_started: bool = false
var next_control: int = 0
var scores := []
var minutes: int = 0
var seconds: int = 0
var milliseconds: int = 0

# Not my code
var _first_person: bool = false
var _gravity_enabled: bool = true
var _collision_enabled: bool = true


@export var map_view: CanvasLayer
@export var label: Label
@export var current_control: Label
@export var time_label: Label
@export var animation: AnimationPlayer
@export var scores_lable: Label

# Not my code
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
			velocity.y = 0.0
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
	load_scores()
	
	# Sorts the scores
	scores.sort_custom(sort_scores)
	
	# Make shore that there are only the top 5 scores
	while len(scores) > MAX_SCORES:
		scores.pop_back()
	
	# Reset the next control text
	current_control.text = EMPTY
	
	# Not my code 
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
		minutes = int(elapsed / SEC_PER_MIN)
		seconds = int(elapsed) % int(SEC_PER_MIN)
		milliseconds = int(elapsed * MS_PER_SEC) % int(MS_PER_SEC)
		time_label.text = FINSH_TIME % [minutes, seconds, milliseconds]
	
	var toggle = map_view.visible
	if Input.is_action_just_pressed(INPUT_OPEN_MAP):
		map_view.visible = not toggle
	
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
	if Input.is_key_pressed(KEY_SPACE):
		velocity.y += JUMP_SPEED + MOVE_SPEED * JUMP_SCALE
	if Input.is_key_pressed(KEY_Q): # Down
		velocity.y -= JUMP_SPEED + MOVE_SPEED * JUMP_SCALE
	if Input.is_key_pressed(KEY_KP_ADD) or Input.is_key_pressed(KEY_EQUAL):
		MOVE_SPEED = clamp(MOVE_SPEED + SPEED_INC, SPEED_MIN, SPEED_MAX)
	if Input.is_key_pressed(KEY_KP_SUBTRACT) or Input.is_key_pressed(KEY_MINUS):
		MOVE_SPEED = clamp(MOVE_SPEED - SPEED_INC, SPEED_MIN, SPEED_MAX)
	return input_dir
	


# Not my code
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
			velocity.y = 0.0


func _on_area_3d_area_entered(area: Area3D) -> void:
	# If the player puntched the start start the corce
	if area.has_meta(META_START) and not course_started:
		start_time = Time.get_ticks_msec()
		course_started = true
		next_control = CTRL_START
		label.text = GO
		current_control.text = NEXT_CTRL + str(next_control)
		animation.play(FADE)

	elif area.has_meta(META_CONTROL) and course_started:
		# Check if the contral is the right one and tell the player
		if area.control_number == next_control and next_control + CTRL_STEP != Global.finsh_control:
			next_control += CTRL_STEP
			label.text = CONTROL + str(area.control_number) + COLLECTED
			current_control.text = NEXT_CTRL + str(next_control)
			animation.play(FADE)
		
		# If the next control is the finsh tell the player
		elif (
			area.control_number == next_control and
			next_control + CTRL_STEP == Global.finsh_control
		):
			next_control += CTRL_STEP
			label.text = CONTROL + str(area.control_number) + COLLECTED
			current_control.text = NEXT_CTRL_FINISH
			animation.play(FADE)
			
		# if the control is wrong tell the player witch one is
		else:
			label.text = WRONG_CONTROL + str(next_control)
			animation.play(FADE)
		
	# Check if the player can finsh the corce and stops the timer if so
	elif area.has_meta(META_FINISH) and course_started:
		if Global.finsh_control == next_control:
			label.text = FINISH
			animation.play(FADE)
			course_started = false
			scores.append([minutes, seconds, milliseconds])
			save_score()
			start_time = 0
		else:
			label.text = WRONG_CONTROL + str(next_control)
			animation.play(FADE)


func save_score():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(scores)


func load_scores():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		scores = file.get_var()


# Sorts the scores using sort_custom()
func sort_scores(score_1, score_2):
	if score_1[0] < score_2[0]:
		return true
		
	elif score_1[0] == score_2[0]:
		if score_1[1] < score_2[1]:
			return true
			
		elif score_1[1] == score_2[1]:
			if score_1[2] < score_2[2]:
				return true
	return false
		
