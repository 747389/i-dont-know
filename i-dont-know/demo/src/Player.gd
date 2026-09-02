extends CharacterBody3D


const OPEN_MAP_ACTION := "Q"
const SCORE_SAVE_PATH := "user://save_score.data"
const EMPTY_TEXT: String = ""
const TIME_FORMAT: String = "Time: %02d:%02d:%03d"
const START_META: String = "Start"
const CONTROL_META: String = "control"
const FINISH_META: String = "Finish"
const START_MESSAGE: String = "Go"
const NEXT_CONTROL_MESSAGE: String = "Next control: "
const FINISH_CONTROL_MESSAGE: String = "Next control: Finish"
const CONTROL_MESSAGE_PREFIX: String = "Control "
const COLLECTED_MESSAGE_SUFFIX: String = " collected!"
const WRONG_CONTROL_MESSAGE: String = "Wrong control! Need control "
const FINISH_MESSAGE: String = "Finish"
const FADE_ANIMATION: String = "fade in out"
const SECONDS_PER_MINUTE: float = 60.0
const MILLISECONDS_PER_SECOND: float = 1000.0
const FIRST_CONTROL_NUMBER: int = 1
const CONTROL_STEP: int = 1
const SCORE_COMPONENT_COUNT: int = 3
const MAX_SCORE_COUNT: int = 5

# Not my code
const SPRING_LENGTH_PROPERTY: String = "spring_length"
const MIN_ARM_LENGTH: float = 0.0
const MAX_ARM_LENGTH: float = 6.0
const TWEEN_DURATION: float = 0.33
const SHIFT_SPEED_MULTIPLIER: float = 2.0
const GRAVITY_ACCELERATION: float = 40.0
const SPEED_INCREMENT: float = 0.5
const WHEEL_SPEED_STEP: float = 5.0
const MIN_SPEED: float = 5.0
const MAX_SPEED: float = 9999.0
const JUMP_SPEED_SCALE: float = 0.016
const DEFAULT_SPEED: float = 50.0
const DEFAULT_JUMP_SPEED: float = 2.0
const JUMP_RELEASE_KEYCODES: Array[int] = [KEY_Q, KEY_E, KEY_SPACE]


@export var map_view: CanvasLayer
@export var message_label: Label
@export var control_label: Label
@export var timer_label: Label
@export var animation_player: AnimationPlayer
@export var scores_label: Label
@export var ray_cast: RayCast3D


# Not my code
@export var camera_arm: SpringArm3D
@export var body_mesh: MeshInstance3D
@export var body_collision_shape: CollisionShape3D
@export var ray_collision_shape: CollisionShape3D
@export var camera: Camera3D
@export var move_speed: float = DEFAULT_SPEED
@export var jump_speed: float = DEFAULT_JUMP_SPEED

# Not my code
@export var first_person: bool = false:
	set(p_value):
		_first_person = p_value
		if is_inside_tree():
			_update_first_person()
	get:
		return _first_person
		
@export var gravity_enabled: bool = true:
	set(p_value):
		_gravity_enabled = p_value
		if not _gravity_enabled:
			velocity.y = 0.0
	get:
		return _gravity_enabled
		
@export var collision_enabled: bool = true:
	set(p_value):
		_collision_enabled = p_value
		if is_inside_tree():
			_update_collision()
	get:
		return _collision_enabled
		


var start_time_msec: int = 0
var course_started: bool = false
var next_control_number: int = 0
var scores: Array = []
var minutes: int = 0
var seconds: int = 0
var milliseconds: int = 0
var is_jumping: bool = false

# Not my code
var _first_person: bool = false
var _gravity_enabled: bool = true
var _collision_enabled: bool = true


func _ready() -> void:
	_load_scores()
	
	# Sorts the scores
	scores.sort_custom(_sort_scores)
	
	# Make shore that there are only the top 5 scores
	while scores.size() > MAX_SCORE_COUNT:
		scores.pop_back()
		
	# Reset the next control text
	if control_label:
		control_label.text = EMPTY_TEXT
		
	# Not my code
	_update_first_person()
	_update_collision()


func _physics_process(p_delta: float) -> void:
	# tell the player what there crreunt time is
	if course_started:
		var elapsed_seconds: float = (
			float(Time.get_ticks_msec() - start_time_msec) / MILLISECONDS_PER_SECOND
		)
		minutes = int(elapsed_seconds / SECONDS_PER_MINUTE)
		seconds = int(elapsed_seconds) % int(SECONDS_PER_MINUTE)
		milliseconds = (
			int(elapsed_seconds * MILLISECONDS_PER_SECOND) % int(MILLISECONDS_PER_SECOND)
		)
		if timer_label:
			timer_label.text = TIME_FORMAT % [minutes, seconds, milliseconds]
	
	# If the player is not jumpring stop them form jumpping down slopes
	if is_on_floor():
		is_jumping = false
	
	if not is_jumping and ray_cast.is_colliding():
		global_position.y = ray_cast.get_collision_point().y
	
	# Open the map when Q is pressed
	if map_view and Input.is_action_just_pressed(OPEN_MAP_ACTION):
		map_view.visible = not map_view.visible
		
	# Not my code
	_move_player(p_delta)


func _on_area_3d_area_entered(area: Area3D) -> void:
	if not area:
		return
		
	# If the player puntched the start start the corce
	if area.has_meta(START_META) and not course_started:
		start_time_msec = Time.get_ticks_msec()
		course_started = true
		next_control_number = FIRST_CONTROL_NUMBER
		_set_message(START_MESSAGE)
		_update_control_label(NEXT_CONTROL_MESSAGE + str(next_control_number))
		_play_fade()
		
	elif area.has_meta(CONTROL_META) and course_started:
		var entered_control_number: Variant = area.control_number
		if not (entered_control_number is int):
			return
			
		# Check if the contral is the right one and tell the player
		if (
			entered_control_number == next_control_number and
			next_control_number + CONTROL_STEP != Global.finsh_control
		):
			next_control_number += CONTROL_STEP
			_set_message(
				CONTROL_MESSAGE_PREFIX + str(entered_control_number) + COLLECTED_MESSAGE_SUFFIX
			)
			_update_control_label(NEXT_CONTROL_MESSAGE + str(next_control_number))
			_play_fade()
			
		# If the next control is the finsh tell the player
		elif (
			entered_control_number == next_control_number and
			next_control_number + CONTROL_STEP == Global.finsh_control
		):
			next_control_number += CONTROL_STEP
			_set_message(
				CONTROL_MESSAGE_PREFIX + str(entered_control_number) + COLLECTED_MESSAGE_SUFFIX
			)
			_update_control_label(FINISH_CONTROL_MESSAGE)
			_play_fade()
			
		# if the control is wrong tell the player witch one is
		else:
			_set_message(WRONG_CONTROL_MESSAGE + str(next_control_number))
			_play_fade()
			
	# Check if the player can finsh the corce and stops the timer if so
	elif area.has_meta(FINISH_META) and course_started:
		if Global.finsh_control == next_control_number:
			_set_message(FINISH_MESSAGE)
			_play_fade()
			course_started = false
			scores.append([minutes, seconds, milliseconds])
			_save_score()
			start_time_msec = 0
		else:
			_set_message(WRONG_CONTROL_MESSAGE + str(next_control_number))
			_play_fade()


# Updates the main message label
func _set_message(message: String) -> void:
	if message_label:
		message_label.text = message


# Starts the message fade animation
func _play_fade() -> void:
	if animation_player:
		animation_player.play(FADE_ANIMATION)


# Updates the next-control label
func _update_control_label(message: String) -> void:
	if control_label:
		control_label.text = message


# Saves course times
func _save_score() -> void:
	var score_file = FileAccess.open(SCORE_SAVE_PATH, FileAccess.WRITE)
	if score_file:
		score_file.store_var(scores)


# Loads valid course times
func _load_scores() -> void:
	scores.clear()
	if FileAccess.file_exists(SCORE_SAVE_PATH):
		var score_file = FileAccess.open(SCORE_SAVE_PATH, FileAccess.READ)
		if not score_file:
			return
			
		var loaded_scores: Variant = score_file.get_var()
		if not (loaded_scores is Array):
			return
			
		for score_entry in loaded_scores:
			if _is_valid_score(score_entry):
				scores.append(score_entry)
				
				
# Validates one score entry
func _is_valid_score(score: Variant) -> bool:
	if not (score is Array) or score.size() != SCORE_COMPONENT_COUNT:
		return false
		
	return (
		score[0] is int and score[0] >= 0 and
		score[1] is int and score[1] >= 0 and score[1] < int(SECONDS_PER_MINUTE) and
		score[2] is int and score[2] >= 0 and score[2] < int(MILLISECONDS_PER_SECOND)
	)


# Sorts the scores using sort_custom()
func _sort_scores(first_score, second_score) -> bool:
	if not _is_valid_score(first_score) or not _is_valid_score(second_score):
		return false
		
	if first_score[0] < second_score[0]:
		return true
		
	elif first_score[0] == second_score[0]:
		if first_score[1] < second_score[1]:
			return true
			
		elif first_score[1] == second_score[1]:
			if first_score[2] < second_score[2]:
				return true
	return false


# Not my code
func _update_first_person() -> void:
	if not camera_arm:
		return
		
	if _first_person:
		var tween: Tween = create_tween()
		tween.tween_property(camera_arm, SPRING_LENGTH_PROPERTY, MIN_ARM_LENGTH, TWEEN_DURATION)
		if body_mesh:
			tween.tween_callback(body_mesh.set_visible.bind(false))
	else:
		if body_mesh:
			body_mesh.visible = true
		create_tween().tween_property(
			camera_arm, SPRING_LENGTH_PROPERTY, MAX_ARM_LENGTH, TWEEN_DURATION
		)


# Not my code
func _update_collision() -> void:
	if body_collision_shape:
		body_collision_shape.disabled = not _collision_enabled
	if ray_collision_shape:
		ray_collision_shape.disabled = not _collision_enabled


# Not my code
func _move_player(p_delta: float) -> void:
	var camera_relative_direction: Vector3 = get_camera_relative_input()
	var horizontal_velocity: Vector2 = (
		Vector2(camera_relative_direction.x, camera_relative_direction.z).normalized()
		* move_speed
	)
	if Input.is_key_pressed(KEY_SHIFT):
		horizontal_velocity *= SHIFT_SPEED_MULTIPLIER
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y
	if gravity_enabled:
		velocity.y -= GRAVITY_ACCELERATION * p_delta
	move_and_slide()


# Not my code
# Returns the input vector relative to the camera.
# Forward is always the direction the camera is facing.
func get_camera_relative_input() -> Vector3:
	if not camera:
		return Vector3.ZERO
		
	var input_direction: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_A): # Left
		input_direction -= camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_D): # Right
		input_direction += camera.global_transform.basis.x
	if Input.is_key_pressed(KEY_W): # Forward
		input_direction -= camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_S): # Backward
		input_direction += camera.global_transform.basis.z
	if Input.is_key_pressed(KEY_SPACE):
		is_jumping = true
		velocity.y += jump_speed + move_speed * JUMP_SPEED_SCALE
	if Input.is_key_pressed(KEY_Q): # Down
		velocity.y -= jump_speed + move_speed * JUMP_SPEED_SCALE
	if Input.is_key_pressed(KEY_KP_ADD) or Input.is_key_pressed(KEY_EQUAL):
		move_speed = clamp(move_speed + SPEED_INCREMENT, MIN_SPEED, MAX_SPEED)
	if Input.is_key_pressed(KEY_KP_SUBTRACT) or Input.is_key_pressed(KEY_MINUS):
		move_speed = clamp(move_speed - SPEED_INCREMENT, MIN_SPEED, MAX_SPEED)
	return input_direction


# Not my code
func _input(p_event: InputEvent) -> void:
	if p_event is InputEventMouseButton and p_event.pressed:
		if p_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			move_speed = clamp(move_speed + WHEEL_SPEED_STEP, MIN_SPEED, MAX_SPEED)
		elif p_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			move_speed = clamp(move_speed - WHEEL_SPEED_STEP, MIN_SPEED, MAX_SPEED)
			
	elif p_event is InputEventKey:
		if p_event.pressed:
			if p_event.keycode == KEY_V:
				first_person = not first_person
			elif p_event.keycode == KEY_G:
				gravity_enabled = not gravity_enabled
			elif p_event.keycode == KEY_C:
				collision_enabled = not collision_enabled
				
		# Else if up/down released
		elif p_event.keycode in JUMP_RELEASE_KEYCODES:
			velocity.y = 0.0
